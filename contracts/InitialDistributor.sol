// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IYaka.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IInitialDistributor.sol";
import "./Minter.sol";

contract InitialDistributor is IInitialDistributor {
    event SetMinter(address indexed _minter);
    event SetStartPeriod(uint256 indexed _start_period);
    event SetAdmin(address indexed _admin);
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

    address public treasury;
    address public community;
    address public team;
    address public lp;
    address public tokenSale;

    IVotingEscrow public immutable ve;
    IYaka public immutable yaka;


    uint256 public constant MAX_SUPPLY_OF_TEAM = 16_000_000 * 1e18;
    uint256 public constant MAX_VE_SUPPLY_OF_TEAM = 16_000_000 * 1e18;
    ReleaseRuleInfo public releaseRuleInfoOfTeam;

    uint256 public constant DEFAULT_LOCK_DURATION = 104 weeks;
    uint256 public constant CLIFF_DURATION = 26 weeks;

    uint256 public start_period;

    address public minter;
    bool hasSupplyImmediately;

    mapping(address => bool) internal adminRoles;

    constructor(address _ve, address _lp, address _community, address _team, address _treasury) {
        ve = IVotingEscrow(_ve);
        lp = _lp;
        community = _community;
        yaka = IYaka(IVotingEscrow(_ve).token());
        team = _team;
        treasury = _treasury;
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

        releaseRuleInfoOfTreasury = ReleaseRuleInfo(
            20_000_000 * 1e18,
            0,
            12_000_000 * 1e18,
            8_000_000 * 1e18,
            1 weeks,
            16 weeks,
            0,
            0
        );
    }

    function supplyImmediately() external onlyAdmin {
        require(!hasSupplyImmediately, "");
        hasSupplyImmediately = true;

        yaka.transfer(community, 50_000_000 * 1e18);//TGE(30M) + veYAKA(12M) + IDO（8M）
        yaka.transfer(lp, 10_000_000 * 1e18);//LP（10M）
    }

    /*///////////////////////////////////////////////////////////////
                             Presale
    //////////////////////////////////////////////////////////////*/
    uint256 public constant MAX_SUPPLY_OF_PRESALE = 6_000_000 * 1e18;
    uint256 public supplyOfPresale;
    mapping(address => uint256) amountOfPresale1;
    mapping(address => uint256) amountOfPresale2;
    mapping(address => uint256) claimedTimeOfPresale;
    mapping(address => uint256) claimedAmountOfPresale;

    function addWhitelistOfPresale(
        address[] calldata users,
        uint256[] calldata amounts
    ) external onlyAdmin {
        uint256 len = users.length;
        require(len == amounts.length, "Mismatch lenght.");
        
        for (uint256 i=0; i<len; ++i) {
            address user = users[i];
            uint256 amount = amounts[i];

            uint256 amount1 = amount * 30 / 100;
            uint256 amount2 = amount - amount1;

            amountOfPresale1[user] = amount1;
            amountOfPresale2[user] = amount2;
            
            supplyOfPresale += amount;
        }
        require(supplyOfPresale <= MAX_SUPPLY_OF_PRESALE, "");
    }

    function claimableForPresale(address _to) external view returns (uint256) {
        (uint256 amount1, uint256 amount2) = _claimableForPresale(_to);
        return (amount1 + amount2);
    }

    function _claimableForPresale(address _to) internal view returns (uint256, uint256) {
        uint256 _start_time = start_period;
        if (_start_time == 0) {
            return (0, 0);
        }

        uint256 amount1 = amountOfPresale1[_to];
        uint256 amount2 = amountOfPresale2[_to];
        uint256 claimedTime = claimedTimeOfPresale[_to];

        if (claimedTime == 0) {
            claimedTime = start_period;
        }

        if (block.timestamp > (start_period + 12 weeks)) {
            return (amount1, amount2 - claimedAmountOfPresale[_to]);
        }

        claimedTime = claimedTime == 0 ? start_period : claimedTime;
        uint256 duration = (block.timestamp - claimedTime) / 1 weeks;
        uint256 releaseAmount = amount2 * duration / 12;
        return (amount1, releaseAmount);
    }


    function claimForPresale() external nonreentrant {
        uint256 _start_period = start_period;
        require(_start_period > 0, "not start");
        require(block.timestamp > _start_period, "cannot claim yet");

        (uint256 amount1, uint256 amount2) = _claimableForPresale(msg.sender);
        if (amount1 > 0) {
            amountOfPresale1[msg.sender] = 0;
        }
        claimedAmountOfPresale[msg.sender] += amount2;

        amount1 += amount2;
        IYaka(yaka).transfer(msg.sender, amount1);
        claimedTimeOfPresale[msg.sender] = block.timestamp / 1 weeks * 1 weeks;
    }

    /*///////////////////////////////////////////////////////////////
                             Partner
    //////////////////////////////////////////////////////////////*/
    uint256 public constant MAX_PRE_SUPPLY_OF_PARTNER = 40_000_000 * 1e18;
    uint256 public constant MAX_SUPPLY_OF_PARTNER = 30_000_000 * 1e18;
    uint256 public preSupplyOfPartner;
    uint256 public supplyOfPartner;
    mapping(address => ReleaseRuleInfo) whitelistOfPartner1;
    mapping(address => ReleaseRuleInfo) whitelistOfPartner2;

    function addWhitelistOfPartner(
        bool _isStage1,
        address _to,
        uint256 _amount
    ) external onlyAdmin {
        require(_amount > 0, "Amount must greater than 0");
        if (_isStage1) {
            require(start_period == 0, "start_period > 0");
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
        bool _isStage1
    ) external nonreentrant {
        uint256 _start_period = start_period;
        require(_start_period > 0, "not start");
        require(block.timestamp > _start_period, "cannot claim yet");

        ReleaseRuleInfo memory info;
        if (_isStage1) {
            info = whitelistOfPartner1[msg.sender];
        } else {
            info = whitelistOfPartner2[msg.sender];
        }
        require(info.totalAmount > 0, "Not in the WL.");

        uint256 releaseAmount = _claimableForPartner(info, _start_period);
        require(releaseAmount > 0, "Has beem claimed.");
        ve.create_lock_for(releaseAmount, DEFAULT_LOCK_DURATION, msg.sender);

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
                             Ecosystem
    //////////////////////////////////////////////////////////////*/
    ReleaseRuleInfo public releaseRuleInfoOfTreasury;

    function claimForTreasury() external nonreentrant {
        uint256 _start_period = start_period;
        require(_start_period > 0, "not start");
        require(block.timestamp > (_start_period + 1 weeks), "cannot claim yet");

        ReleaseRuleInfo memory ruleInfo = releaseRuleInfoOfTreasury;
        uint256 transferAmount = _claimableAmount(ruleInfo, _start_period);
        if (transferAmount > 0) {
            releaseRuleInfoOfTreasury.claimedAmount += transferAmount;
        }

        IYaka(yaka).transfer(treasury, transferAmount);
        releaseRuleInfoOfTreasury.latestClaimedTime = block.timestamp / 1 weeks * 1 weeks;
    }

    /*///////////////////////////////////////////////////////////////
                             TEAM
    //////////////////////////////////////////////////////////////*/
    function claimForTeam() external nonreentrant {
        uint256 _start_period = start_period;
        require(_start_period > 0, "not start");
        require(block.timestamp > _start_period, "cannot claim yet");
        ReleaseRuleInfo memory ruleInfo = releaseRuleInfoOfTeam;
        address _team = team;

        uint256 veAmount = ruleInfo.veAmount;
        if (veAmount > 0) {
            releaseRuleInfoOfTeam.veAmount = 0;
            ve.create_lock_for(veAmount, DEFAULT_LOCK_DURATION, _team);
            return;
        }

        uint256 transferAmount = _claimableAmount(ruleInfo, _start_period);
        if (transferAmount > 0) {
            releaseRuleInfoOfTeam.claimedAmount += transferAmount;
        }

        IYaka(yaka).transfer(_team, transferAmount);
        releaseRuleInfoOfTeam.latestClaimedTime = block.timestamp / 1 weeks * 1 weeks;
    }


    /*///////////////////////////////////////////////////////////////
                            Token Sale
    //////////////////////////////////////////////////////////////*/
    uint256 public constant MAX_SUPPLY_OF_TOKEN_SALE = 12_000_000 * 1e18;
    uint256 public supplyOfTokenSale;
    mapping(address => uint256) amountOfTokenSale1;
    mapping(address => uint256) amountOfTokenSale2;
    mapping(address => uint256) claimedTimeOfTokenSale;
    mapping(address => uint256) claimedAmountOfTokenSale;

    function addWhitelistOfTokenSale(
        address[] calldata users,
        uint256[] calldata amounts
    ) external onlyAdmin {
        uint256 len = users.length;
        require(len == amounts.length, "Mismatch lenght.");
        
        for (uint256 i=0; i<len; ++i) {
            address user = users[i];
            uint256 amount = amounts[i];

            uint256 amount1 = amount * 40 / 100;
            uint256 amount2 = amount - amount1;

            amountOfTokenSale1[user] = amount1;
            amountOfTokenSale2[user] = amount2;
            
            supplyOfTokenSale += amount;
        }
        require(supplyOfTokenSale <= MAX_SUPPLY_OF_TOKEN_SALE, "");
    }

    function claimableForTokenSale(address _to) external view returns (uint256) {
        (uint256 amount1, uint256 amount2) = _claimableForTokenSale(_to);
        return (amount1 + amount2);
    }

    function _claimableForTokenSale(address _to) internal view returns (uint256, uint256) {
        uint256 _start_time = start_period;
        if (_start_time == 0) {
            return (0, 0);
        }

        uint256 amount1 = amountOfTokenSale1[_to];
        uint256 amount2 = amountOfTokenSale2[_to];
        uint256 claimedTime = claimedTimeOfTokenSale[_to];

        if (block.timestamp > (start_period + 12 weeks)) {
            return (amount1, amount2 - claimedAmountOfTokenSale[_to]);
        }

        claimedTime = claimedTime == 0 ? start_period : claimedTime;
        uint256 duration = (block.timestamp - claimedTime) / 1 weeks; 
        uint256 releaseAmount = amount2 * duration / 12;
        return (amount1, releaseAmount);
    }


    function claimForTokenSale() external nonreentrant {
        uint256 _start_period = start_period;
        require(_start_period > 0, "not start");
        require(block.timestamp > _start_period, "cannot claim yet");

        (uint256 amount1, uint256 amount2) = _claimableForTokenSale(msg.sender);
        if (amount1 > 0) {
            amountOfTokenSale1[msg.sender] = 0;
        }
        claimedAmountOfTokenSale[msg.sender] += amount2;

        amount1 += amount2;
        IYaka(yaka).transfer(msg.sender, amount1);
        claimedTimeOfTokenSale[msg.sender] = block.timestamp / 1 weeks * 1 weeks;
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
            return info.totalAmount - info.claimedAmount;
        }

        uint256 releaseAmount;
        uint256 _latestClaimTime = info.latestClaimedTime;
        if (_latestClaimTime == 0) {
            releaseAmount = info.immediateReleaseAmount;
            _latestClaimTime = cliffTime;
        }

        uint256 duration = (block.timestamp - _latestClaimTime) / 1 weeks * 1 weeks;
        releaseAmount += (info.linearReleaseAmount * duration) / info.releaseDuration;
        return releaseAmount;
    }

    function setMinter(address _minter) external onlyAdmin {
        minter = _minter;
        emit SetMinter(_minter);
    }

    function setStartPeriod(uint256 _start_period) external {
        require(msg.sender == minter, "");
        start_period = _start_period;       
        emit SetStartPeriod(_start_period); 
    }

    function setAdmin(address _admin) external onlyAdmin {
        adminRoles[_admin] = true;
        emit SetAdmin(_admin);
    }

    function checkAdmin(address _admin) internal view {
        require(adminRoles[_admin] == true, "wrong admin");
    }
}