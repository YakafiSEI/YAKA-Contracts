// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RouterV2.sol";
import "./interfaces/IPair.sol";
import "./interfaces/IERC20.sol";

contract SeiCampaignStage2 {

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'SeiCampaignStage2: EXPIRED');
        _;
    }
    
    address public admin;
    RouterV2 public router;

    address[] public pairs;
    mapping(address => bool) public pairWhiteList;

    address[] public users;
    mapping(address => uint256) public boardingTimeOf;

    mapping(address => mapping(address => uint32)) public swapCntOf;//user=>pool=>cnt
    mapping(address => mapping(address => uint32)) public depositCntOf;//user=>pool=>cnt
    mapping(address => uint256) public invitedCntOf;

    mapping(address => address) public superiorOf;

    mapping(address => bool) public swapBadgeOf;
    mapping(address => bool) public depositBadgeOf;
    mapping(address => bool) public inviteBadgeOf;



    constructor(address _router) {
        admin = msg.sender;
        router = RouterV2(payable(address(_router)));
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        RouterV2.route[] calldata routes,
        uint256 deadline,
        address inviter
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        inviteUser(msg.sender, inviter);
        updateBadge(msg.sender, true);

        address pair = router.pairFor(routes[0].from, routes[0].to, routes[0].stable);
        require(pairWhiteList[pair], "pair is not WL.");
        
        _safeTransferFrom(routes[0].from, msg.sender, address(this), amountIn);

        addSwapPoint(msg.sender, pair);
        return router.swapExactTokensForTokens(amountIn, amountOutMin, routes, msg.sender, deadline);
    }


    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline,
        address inviter
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {

        {
            inviteUser(msg.sender, inviter);
            updateBadge(msg.sender, false);
        }

        {
            address pair = router.pairFor(tokenA, tokenB, stable);
            require(pairWhiteList[pair], "pair is not WL.");

            _safeTransferFrom(tokenA, msg.sender, address(this), amountADesired);
            _safeTransferFrom(tokenB, msg.sender, address(this), amountBDesired);

            addDepositPoint(msg.sender, pair);
        }

        (amountA, amountB, liquidity) = router.addLiquidity(tokenA, tokenB, stable, amountADesired, amountBDesired, amountAMin, amountBMin, msg.sender, deadline);
        {
            refund(tokenA);
            refund(tokenB);
        }
    }

    function refund(address token) internal {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(msg.sender, balance);
        }
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline,
        address inviter
    ) public ensure(deadline) returns (uint256 amountA, uint256 amountB) {

        inviteUser(msg.sender, inviter);

        address pair = router.pairFor(tokenA, tokenB, stable);
        require(pairWhiteList[pair], "pair is not WL.");

        require(IPair(pair).transferFrom(msg.sender, address(this), liquidity));
        return router.removeLiquidity(tokenA, tokenB, stable, liquidity, amountAMin, amountBMin, msg.sender, deadline);
    }

    function getUserCnt() external view returns (uint256) {
        return users.length;
    }

    function getPoints(address user) external view returns(uint256, uint256, uint256) {
        return _getPoints(user);
    }

    function batchGetPoints(uint256 start, uint256 end) external view returns(address[] memory, uint256[] memory) {
        uint256 len = users.length;
        require(start < end);
        require(end <= len);

        address[] memory _users = new address[](end - start);
        uint256[] memory points = new uint256[](end - start);
        uint256 j=0;
        for (uint256 i = start; i < end; i++) {
            address user = users[i];
            (uint256 swapPoints, uint256 depositPoints, uint256 invitedPoints) = _getPoints(user);
            _users[j] = user;
            points[j] = swapPoints + depositPoints + invitedPoints;
            ++j;
        }
        return (_users, points);
    } 

    function _getPoints(address user) internal view returns(uint256, uint256, uint256) {
        uint256 len = pairs.length;
        uint256 swapPoints;
        uint256 depositPoints;
        uint256 invitedPoints = invitedCntOf[user];
        for (uint256 i = 0; i < len; ++i) {
            address pair = pairs[i];
            if (swapCntOf[user][pair] > 0) {
                swapPoints += 20;
            }

            if (depositCntOf[user][pair] > 0) {
                depositPoints += 30;
            }
        }
        return (swapPoints, depositPoints, invitedPoints);
    }

    function inviteUser(address user, address inviter) internal {
                
        if (boardingTimeOf[user] != 0) {
            return;
        }

        users.push(user);
        boardingTimeOf[user] = block.timestamp;
        if (inviter != address(0)) {
            require(inviteBadgeOf[inviter], "illegal inviter.");
            if (superiorOf[user] == address(0)) {
                superiorOf[user] = inviter;
                invitedCntOf[inviter] += 1;
            }
        }
    }

    function updateBadge(address user, bool isSwap) internal {

        bool hasInviteBadge = inviteBadgeOf[user];
        if (hasInviteBadge) {
            return;
        }

        bool hasSwapped = swapBadgeOf[user];
        bool hasDeposited = depositBadgeOf[user];
        if (isSwap) {
            if (!hasSwapped) {
                hasSwapped = true;
                swapBadgeOf[user] = true;
            }
        } else {
            if (!hasDeposited) {
                hasDeposited = true;
                depositBadgeOf[user] = true;
            }
        }

        if (hasSwapped && hasDeposited) {
            inviteBadgeOf[user] = true;
        }
    }


    function addSwapPoint(address _user, address _pair) internal {
        swapCntOf[_user][_pair] += 1;
    }

    function addDepositPoint(address _user, address _pair) internal {
        depositCntOf[_user][_pair] += 1;
    }


    function addPair(address _pair) external {
        require(msg.sender == admin, "not admin");
        uint256 len = pairs.length;
        for (uint256 i=0; i < len; i++) {
            if (_pair == pairs[i]) {
                revert("same pair.");
            }
        }

        pairs.push(_pair);
        pairWhiteList[_pair] = true;

        (address tokenA, address tokenB) = IPair(_pair).tokens();
        IERC20(tokenA).approve(address(router), type(uint256).max);

        IERC20(tokenB).approve(address(router), type(uint256).max);
        
        IERC20(_pair).approve(address(router), type(uint256).max);
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function getSwapCntOf(address user, address pool) external view returns(uint256) {
        return swapCntOf[user][pool];
    }

    function getDepositCntOf(address user, address pool) external view returns(uint256) {
        return depositCntOf[user][pool];
    }
}
