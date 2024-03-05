// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IYaka.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IInitialDistributor.sol";
import "./Minter.sol";

contract InitialDistributor is IInitialDistributor {
    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @dev reentrancy guard
    uint8 internal constant _not_entered = 1;
    uint8 internal constant _entered = 2;
    uint8 internal _entered_state = 1;

    modifier nonreentrant() {
        require(_entered_state == _not_entered);
        _entered_state = _entered;
        _;
        _entered_state = _not_entered;
    }

    modifier onlyAdmin() {
        checkAdmin(msg.sender);
        _;
    }

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    struct ReleaseRuleInfo {
        uint256 totalAmount;
        uint256 veAmount;
        uint256 immediateReleaseAmount;
        uint256 linearReleaseAmount;
        uint256 cliffDuration;
        uint256 releaseDuration;
        uint256 claimedAmount;
        uint256 latestClaimedTime;
    }

    address public community;
    address public team;
    address public lp;
    address public tokenSale;
    address public IDO;

    IVotingEscrow public immutable ve;
    IYaka public immutable yaka;

    uint256 public constant MAX_SUPPLY_OF_COMMUNITY = 48_000_000 * 1e18;
    uint256 public supplyOfCommunity;
    mapping(address => ReleaseRuleInfo) whitelistOfcommunity;

    uint256 public constant MAX_PRE_SUPPLY_OF_PARTNER = 50_000_000 * 1e18;
    uint256 public constant MAX_SUPPLY_OF_PARTNER = 30_000_000 * 1e18;
    uint256 public preSupplyOfPartner;
    uint256 public supplyOfPartner;
    mapping(address => ReleaseRuleInfo) whitelistOfPartner1;
    mapping(address => ReleaseRuleInfo) whitelistOfPartner2;

    uint256 public constant MAX_SUPPLY_OF_TEAM = 15_000_000 * 1e18;
    uint256 public constant MAX_VE_SUPPLY_OF_TEAM = 15_000_000 * 1e18;
    ReleaseRuleInfo public releaseRuleInfoOfTeam;

    uint256 public constant MAX_SUPPLY_OF_VESTOR = 6_000_000 * 1e18;
    uint256 public supplyOfVestor;
    mapping(address => ReleaseRuleInfo) whitelistOfVestor;

    uint256 public constant DEFAULT_LOCK_DURATION = 104 weeks;
    uint256 public constant CLIFF_DURATION = 26 weeks;

    uint256 public start_period;

    address public minter;
    bool hasSupplyImmediately;

    mapping(address => bool) internal adminRoles;

    constructor(address _ve, address _lp, address _IDO, address _team) {
        ve = IVotingEscrow(_ve);
        lp = _lp;
        IDO = _IDO;
        yaka = IYaka(IVotingEscrow(_ve).token());
        team = _team;
        adminRoles[msg.sender] = true;
        yaka.approve(address(_ve), type(uint256).max);

        releaseRuleInfoOfTeam = ReleaseRuleInfo(
            (MAX_VE_SUPPLY_OF_TEAM + MAX_SUPPLY_OF_TEAM),
            MAX_VE_SUPPLY_OF_TEAM,
            0,
            MAX_SUPPLY_OF_TEAM,
            CLIFF_DURATION,
            DEFAULT_LOCK_DURATION,
            0,
            0
        );
    }

    function supplyImmediately() external onlyAdmin {
        require(!hasSupplyImmediately, "");
        hasSupplyImmediately = true;

        yaka.transfer(lp, 10_000_000 * 1e18);
        yaka.transfer(IDO, 14_000_000 * 1e18); //presale(6M) + public sale(8M)
    }

    /*///////////////////////////////////////////////////////////////
                             COMMUNITY
    //////////////////////////////////////////////////////////////*/
    function addWhitelistOfCommunity(
        address to,
        uint256 amount
    ) external onlyAdmin {
        require(amount > 0, "Amount must greater than 0");
        supplyOfCommunity += amount;
        require(supplyOfCommunity <= MAX_SUPPLY_OF_COMMUNITY, "");

        uint256 veAmount = amount / 2;
        uint256 tokenAmount = amount - veAmount;
        uint256 immediateReleaseAmount = (tokenAmount * 300) / 1000;
        uint256 linearReleaseAmount = (tokenAmount * 700) / 1000;

        whitelistOfcommunity[to] = ReleaseRuleInfo(
            amount,
            veAmount,
            immediateReleaseAmount,
            linearReleaseAmount,
            0,
            4 weeks,
            0,
            0
        );
    }

    function claimForCommunity(address _to) external nonreentrant {
        uint256 _start_time = start_period;
        require(block.timestamp > start_period, "cannot claim yet");

        ReleaseRuleInfo memory ruleInfo = whitelistOfcommunity[msg.sender];
        require(ruleInfo.totalAmount > 0, "Not in the WL.");

        if (_to == address(0)) {
            _to = msg.sender;
        }

        uint256 veAmount = ruleInfo.veAmount;
        if (veAmount > 0) {
            whitelistOfcommunity[msg.sender].veAmount = 0;
            ve.create_lock_for(veAmount, DEFAULT_LOCK_DURATION, _to);
        }

        uint256 transferAmount;

        uint256 immediateReleaseAmount = ruleInfo.immediateReleaseAmount;
        if (immediateReleaseAmount > 0) {
            whitelistOfcommunity[msg.sender].immediateReleaseAmount = 0;
            transferAmount += immediateReleaseAmount;
        }

        uint256 releaseAmount = _claimableAmount(ruleInfo, _start_time);
        if (releaseAmount > 0) {
            whitelistOfcommunity[msg.sender].claimedAmount += releaseAmount;
        }
        transferAmount += releaseAmount;

        IYaka(yaka).transfer(_to, transferAmount);
        whitelistOfcommunity[msg.sender].latestClaimedTime = block.timestamp;
    }

    function claimableForCommunity(address _to) external view returns (uint256) {
        uint256 _start_time = start_period;
        if (_start_time == 0) {
            return 0;
        }

        ReleaseRuleInfo memory ruleInfo = whitelistOfcommunity[_to];
        if (ruleInfo.totalAmount == 0) {
            return 0;
        }

        uint256 immediateReleaseAmount = ruleInfo.immediateReleaseAmount;
        // console2.log("immediateReleaseAmount ", immediateReleaseAmount);
        uint256 releaseAmount = _claimableAmount(ruleInfo, _start_time);
        // console2.log("releaseAmount ", releaseAmount);

        return (immediateReleaseAmount + releaseAmount);
    }

    /*///////////////////////////////////////////////////////////////
                             Partner
    //////////////////////////////////////////////////////////////*/
    function addWhitelistOfPartner(
        bool _isStage1,
        address _to,
        uint256 _amount
    ) external onlyAdmin {
        require(_amount > 0, "Amount must greater than 0");
        if (_isStage1) {
            preSupplyOfPartner += _amount;
            require(preSupplyOfPartner <= MAX_PRE_SUPPLY_OF_PARTNER, "");
        } else {
            supplyOfPartner += _amount;
            require(supplyOfPartner <= MAX_SUPPLY_OF_PARTNER, "");
        }

        ReleaseRuleInfo memory info = ReleaseRuleInfo(
            _amount,
            _amount,
            0,
            0,
            0,
            DEFAULT_LOCK_DURATION,
            0,
            0
        );

        if (_isStage1) {
            whitelistOfPartner1[_to] = info;
        } else {
            whitelistOfPartner2[_to] = info;
        }
    }

    function claimForPartner(
        bool _isStage1,
        address _to
    ) external nonreentrant {
        uint256 _start_time = start_period;
        require(block.timestamp > _start_time, "cannot claim yet");

        ReleaseRuleInfo memory info;
        if (_isStage1) {
            info = whitelistOfPartner1[msg.sender];
            whitelistOfPartner1[msg.sender].veAmount = 0;
        } else {
            info = whitelistOfPartner2[msg.sender];
            whitelistOfPartner2[msg.sender].veAmount = 0;
        }
        require(info.totalAmount > 0, "Not in the WL.");

        if (_to == address(0)) {
            _to = msg.sender;
        }

        uint256 releaseAmount = _claimableForPartner(info, _start_time);
        require(releaseAmount > 0, "Has beem claimed.");
        ve.create_lock_for(releaseAmount, DEFAULT_LOCK_DURATION, _to);

        if (_isStage1) {
            whitelistOfPartner1[msg.sender].veAmount = 0;
            whitelistOfPartner1[msg.sender].latestClaimedTime = block.timestamp;
        } else {
            whitelistOfPartner2[msg.sender].veAmount = 0;
            whitelistOfPartner2[msg.sender].latestClaimedTime = block.timestamp;
        }
    }

    function claimableForPartner(
        bool _isStage1,
        address _to
    ) external view returns (uint256) {
        uint256 _start_time = start_period;
        if (_start_time == 0) {
            return 0;
        }

        ReleaseRuleInfo memory info;
        if (_isStage1) {
            info = whitelistOfPartner1[_to];
        } else {
            info = whitelistOfPartner2[_to];
        }
        return _claimableForPartner(info, _start_time);
    }

    function _claimableForPartner(
        ReleaseRuleInfo memory info,
        uint256 _start_time
    ) internal view returns (uint256) {
        if (info.totalAmount == 0) {
            return 0;
        }

        uint256 cliffTime = _start_time + info.cliffDuration;
        if (block.timestamp < cliffTime) {
            return 0;
        }
        return info.veAmount;
    }

    /*///////////////////////////////////////////////////////////////
                             TEAM
    //////////////////////////////////////////////////////////////*/
    function claimForTeam() external nonreentrant {
        uint256 _start_time = start_period;
        require(block.timestamp > start_period, "cannot claim yet");
        ReleaseRuleInfo memory ruleInfo = releaseRuleInfoOfTeam;
        address _team = team;

        uint256 veAmount = ruleInfo.veAmount;
        if (veAmount > 0) {
            releaseRuleInfoOfTeam.veAmount = 0;
            ve.create_lock_for(veAmount, DEFAULT_LOCK_DURATION, _team);
            return;
        }

        uint256 transferAmount = _claimableAmount(ruleInfo, _start_time);
        if (transferAmount > 0) {
            releaseRuleInfoOfTeam.claimedAmount += transferAmount;
        }

        IYaka(yaka).transfer(_team, transferAmount);
        releaseRuleInfoOfTeam.latestClaimedTime = block.timestamp;
    }

    /*///////////////////////////////////////////////////////////////
                             Vestor
    //////////////////////////////////////////////////////////////*/
    function addWhitelistOfVestor(
        address _to,
        uint256 _amount
    ) external onlyAdmin {
        require(_amount > 0, "Amount must greater than 0");
        supplyOfVestor += _amount;
        require(supplyOfVestor <= MAX_SUPPLY_OF_VESTOR, "");

        whitelistOfVestor[_to] = ReleaseRuleInfo(
            _amount,
            0,
            0,
            _amount,
            CLIFF_DURATION,
            DEFAULT_LOCK_DURATION,
            0,
            0
        );
    }

    function claimForVestor(address _to) external nonreentrant {
        uint256 _start_time = start_period;
        require(block.timestamp > start_period, "cannot claim yet");
        ReleaseRuleInfo memory ruleInfo = whitelistOfVestor[msg.sender];
        require(ruleInfo.totalAmount > 0, "Not in the WL.");

        if (_to == address(0)) {
            _to = msg.sender;
        }

        uint256 transferAmount = _claimableAmount(ruleInfo, _start_time);
        if (transferAmount > 0) {
            whitelistOfVestor[msg.sender].claimedAmount += transferAmount;
        }

        IYaka(yaka).transfer(_to, transferAmount);
        whitelistOfVestor[msg.sender].latestClaimedTime = block.timestamp;
    }

    function claimableForVestor(address _to) external view returns (uint256) {
        uint256 _start_time = start_period;
        if (_start_time == 0) {
            return 0;
        }

        ReleaseRuleInfo memory ruleInfo = whitelistOfVestor[_to];
        if (ruleInfo.totalAmount == 0) {
            return 0;
        }

        uint256 releaseAmount = _claimableAmount(ruleInfo, _start_time);
        return releaseAmount;
    }

    function _claimableAmount(
        ReleaseRuleInfo memory info,
        uint256 _start_time
    ) internal view returns (uint256) {
        uint256 cliffTime = _start_time + info.cliffDuration;
        uint256 endTime = cliffTime + info.releaseDuration;

        if (block.timestamp < cliffTime) {
            return 0;
        }

        if (block.timestamp >= endTime) {
            return info.linearReleaseAmount - info.claimedAmount;
        }

        uint256 _latestClaimTime = info.latestClaimedTime == 0
            ? cliffTime
            : info.latestClaimedTime;

        uint256 diffTime = block.timestamp - _latestClaimTime;
        uint256 releaseAmount = (info.linearReleaseAmount * diffTime) /
            info.releaseDuration;
        return releaseAmount;
    }

    function setMinter(address _minter) external onlyAdmin {
        minter = _minter;
    }

    function setStartPeriod(uint256 _start_period) external {
        require(msg.sender == minter, "");
        start_period = _start_period;        
    }

    function setAdmin(address _admin) external onlyAdmin {
        adminRoles[_admin] = true;
    }

    function checkAdmin(address _admin) internal view {
        require(adminRoles[_admin] == true, "wrong admin");
    }
}
