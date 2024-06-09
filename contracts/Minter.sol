// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import "./libraries/Math.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IRewardsDistributor.sol";
import "./interfaces/IYaka.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IInitialDistributor.sol";

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting

contract Minter is IMinter {

    bool public isFirstMint = true;
    bool public initialized;

    uint public EMISSION = 990;
    uint public TAIL_EMISSION = 2;
    uint public REBASEMAX = 300;
    uint public constant PRECISION = 1000;
    address public owner;
    address public initialDistributor;
    uint public teamRate;
    uint public constant MAX_TEAM_RATE = 50; // 5%

    uint public constant WEEK = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint public weekly = 10_000_000 * 1e18; // represents a starting weekly emission of 10M yaka (yaka has 18 decimals)
    uint public active_period;
    uint public genesis_time;
    uint public constant LOCK = 86400 * 7 * 52 * 2;

    // address internal _initializer;
    address public team;
    address public pendingTeam;
    
    IYaka public immutable _yaka;
    IVoter public _voter;
    IVotingEscrow public _ve;
    IRewardsDistributor public _rewards_distributor;

    event Mint(address indexed sender, uint weekly, uint circulating_supply, uint circulating_emission);

    constructor(
        address __voter, // the voting & distribution system
        address __ve, // the ve(3,3) system that will be locked into
        address __rewards_distributor, // the distribution system that ensures users aren't diluted
        address __initialDistributor,
        address __team
    ) {
        owner = msg.sender;
        teamRate = 35;
        _yaka = IYaka(IVotingEscrow(__ve).token());
        _voter = IVoter(__voter);
        _ve = IVotingEscrow(__ve);
        _rewards_distributor = IRewardsDistributor(__rewards_distributor);
        initialDistributor = __initialDistributor;
        team = __team;
    }

    function initialize() external {
        require(owner == msg.sender);
        if (initialized) {
            return;
        }
        initialSupply();
        initialized = true;
    }

    function initialSupply() internal {
        _yaka.mint(initialDistributor, 200_000_000 * 1e18);//The initial supply of $YAKA is 200M.
        _yaka.approve(address(_ve), type(uint256).max);
    }

    function startActivePeriod() external {
        require(owner == msg.sender, "not owner");
        require(active_period == 0, "had been actived");
        // allow minter.update_period() to mint new emissions THIS Thursday
        active_period = ((block.timestamp) / WEEK) * WEEK;
        genesis_time = active_period;
        IInitialDistributor(initialDistributor).setStartPeriod(active_period);
    }


    function setTeam(address _team) external {
        require(msg.sender == team, "not team");
        pendingTeam = _team;
    }

    function acceptTeam() external {
        require(msg.sender == pendingTeam, "not pending team");
        team = pendingTeam;
    }

    function setVoter(address __voter) external {
        require(__voter != address(0));
        require(msg.sender == team, "not team");
        _voter = IVoter(__voter);
    }

    function setTeamRate(uint _teamRate) external {
        require(msg.sender == team, "not team");
        require(_teamRate <= MAX_TEAM_RATE, "rate too high");
        teamRate = _teamRate;
    }

    function getGenesisTime() external view returns (uint256) {
        return genesis_time;
    }

    function setEmission(uint _emission) external {
        require(msg.sender == team, "not team");
        require(_emission <= PRECISION, "rate too high");
        EMISSION = _emission;
    }


    function setRebase(uint _rebase) external {
        require(msg.sender == team, "not team");
        require(_rebase <= PRECISION, "rate too high");
        REBASEMAX = _rebase;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "not owner");
        owner = _owner;
    }

    // calculate circulating supply as total token supply - locked supply
    function circulating_supply() public view returns (uint) {
        return _yaka.totalSupply() - _yaka.balanceOf(address(_ve));
    }

    // emission calculation is 1% of available supply to mint adjusted by circulating / total supply
    function calculate_emission() public view returns (uint) {
        return (weekly * EMISSION) / PRECISION;
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function weekly_emission() public view returns (uint) {
        return Math.max(calculate_emission(), circulating_emission());
    }

    // calculates tail end (infinity) emissions as 0.2% of total supply
    function circulating_emission() public view returns (uint) {
        return (circulating_supply() * TAIL_EMISSION) / PRECISION;
    }

    // calculate inflation and adjust ve balances accordingly
    function calculate_rebase(uint _weeklyMint) public view returns (uint) {
        uint _veTotal = _yaka.balanceOf(address(_ve));
        uint _yakaTotal = _yaka.totalSupply();
        
        uint lockedShare = (_veTotal) * PRECISION  / _yakaTotal;
        if(lockedShare >= REBASEMAX){
            return _weeklyMint * REBASEMAX / PRECISION;
        } else {
            return _weeklyMint * lockedShare / PRECISION;
        }
    }

    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint) {
        uint _period = active_period;
        if (block.timestamp >= _period + WEEK && genesis_time > 0) {
            _period = (block.timestamp / WEEK) * WEEK;
            active_period = _period;

            if(!isFirstMint){
                weekly = weekly_emission();
            } else {
                isFirstMint = false;
            }

            uint _rebase = calculate_rebase(weekly);
            uint _teamEmissions = weekly * teamRate / PRECISION;
            uint _required = weekly;

            uint _gauge = weekly - _rebase - _teamEmissions;

            uint _balanceOf = _yaka.balanceOf(address(this));
            if (_balanceOf < _required) {
                _yaka.mint(address(this), _required - _balanceOf);
            }

            require(_yaka.transfer(team, _teamEmissions));
            
            require(_yaka.transfer(address(_rewards_distributor), _rebase));
            _rewards_distributor.checkpoint_token(); // checkpoint token balance that was just minted in rewards distributor
            _rewards_distributor.checkpoint_total_supply(); // checkpoint supply

            _yaka.approve(address(_voter), _gauge);
            _voter.notifyRewardAmount(_gauge);

            emit Mint(msg.sender, weekly, circulating_supply(), circulating_emission());
        }
        return _period;
    }

    function check() external view returns(bool){
        uint _period = active_period;
        return (block.timestamp >= _period + WEEK && genesis_time > 0);
    }

    function period() external view returns(uint){
        return(block.timestamp / WEEK) * WEEK;
    }
    function setRewardDistributor(address _rewardDistro) external {
        require(msg.sender == team);
        _rewards_distributor = IRewardsDistributor(_rewardDistro);
    }
}
