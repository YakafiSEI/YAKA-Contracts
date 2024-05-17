// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RouterV2.sol";
import "./interfaces/IPair.sol";
import "./interfaces/IERC20.sol";
import "forge-std/console2.sol";

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

    address public weth;

    constructor(address _router, address _weth) {
        admin = msg.sender;
        router = RouterV2(payable(address(_router)));
        IERC20(_weth).approve(_router, type(uint256).max);
        weth = _weth;
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

    function swapExactETHForTokens(
        uint amountOutMin, 
        RouterV2.route[] calldata routes,
        uint deadline,
        address inviter
    ) external payable ensure(deadline) returns (uint[] memory amounts) {
        
        require(routes[0].from == address(weth), 'SeiCampaignStage2: INVALID_WSEI_PATH');

        inviteUser(msg.sender, inviter);
        updateBadge(msg.sender, true);

        address pair = router.pairFor(routes[0].from, routes[0].to, routes[0].stable);
        require(pairWhiteList[pair], "pair is not WL.");

        addSwapPoint(msg.sender, pair);
        return router.swapExactETHForTokens{value : msg.value}(amountOutMin, routes, msg.sender, deadline);
    }

    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        RouterV2.route[] calldata routes, 
        uint deadline,
        address inviter
    ) external ensure(deadline) returns (uint[] memory amounts) {
        require(routes[routes.length - 1].to == address(weth), 'SeiCampaignStage2: INVALID_WSEI_PATH');

        inviteUser(msg.sender, inviter);
        updateBadge(msg.sender, true);

        address pair = router.pairFor(routes[0].from, routes[0].to, routes[0].stable);
        require(pairWhiteList[pair], "pair is not WL.");

        _safeTransferFrom(routes[0].from, msg.sender, address(this), amountIn);

        addSwapPoint(msg.sender, pair);
        return router.swapExactTokensForETH(amountIn, amountOutMin, routes, msg.sender, deadline);
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

    function addLiquidityETH(
        address token,
        bool stable,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline,
        address inviter
    ) external payable ensure(deadline) returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        {
            inviteUser(msg.sender, inviter);
            updateBadge(msg.sender, false);
        }

        {
            address pair = router.pairFor(token, address(weth), stable);
            require(pairWhiteList[pair], "pair is not WL.");

            _safeTransferFrom(token, msg.sender, address(this), amountTokenDesired);
            addDepositPoint(msg.sender, pair);
        }
        (amountToken, amountETH, liquidity) = router.addLiquidityETH{value : msg.value}(token, stable, amountTokenDesired, amountTokenMin, amountETHMin, msg.sender, deadline);

        {
            refund(token);
            if (msg.value > amountETH) _safeTransferETH(msg.sender, msg.value - amountETH);
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

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function getSwapCntOf(address user, address pool) external view returns(uint256) {
        return swapCntOf[user][pool];
    }

    function getDepositCntOf(address user, address pool) external view returns(uint256) {
        return depositCntOf[user][pool];
    }

    function getAllPairs() external view returns(address[] memory) {
        uint256 len = pairs.length;
        address[] memory allPairs = new address[](len);
        for (uint256 i=0; i<len; ++i) {
            allPairs[i] = pairs[i];
        }
        return allPairs;
    }

}