pragma solidity 0.8.20;

import "./BaseTest.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MockToken is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}


contract SeiCampaignStage2Test is BaseTest {

    address public POOL_1;
    address public POOL_2;
    address public POOL_3;

    MockToken token1;
    MockToken token2;
    MockToken token3;
    MockToken token4;

    // SeiCampaignStage2 public seiCampaignStage;

    address public Alice = address(1);
    address public Bob = address(2);
    address public Chris = address(3);

    address public TOKEN_A;
    address public TOKEN_B;

    function setUp() public {
        deployAll();
        minter.initialize();
        initialDistributor.supplyImmediately();
        assertEq(IERC20(address(YAKA)).balanceOf(COMMUNITY), 50_000_000 * 1e18);
        assertEq(IERC20(address(YAKA)).balanceOf(LP), 10_000_000 * 1e18);
        
        vm.label(address(Alice), "Alice");
        vm.label(address(Bob), "Bob");
        vm.label(address(Chris), "Chris");

        token1 = new MockToken("token_1", "token_1");
        token2 = new MockToken("token_2", "token_2");
        TOKEN_A = address(token1);
        TOKEN_B = address(token2);
        console2.log("TOKEN_A", TOKEN_A);
        console2.log("TOKEN_B", TOKEN_B);

        token1.mint(1000000000);
        token2.mint(1000000000);

        vm.deal(Alice, 10000000000000);
        vm.deal(Bob, 10000000000000);
        vm.deal(Chris, 10000000000000);

        chargeYAKA(Alice, 1000000000000);
        chargeYAKA(Bob, 1000000000000);
        chargeYAKA(Chris, 1000000000000);
        charge(token1, Alice, 1000000);
        charge(token1, Bob, 1000000);
        charge(token1, Chris, 1000000);
        charge(token2, Alice, 1000000);
        charge(token2, Bob, 1000000);
        charge(token2, Chris, 1000000);

        token1.approve(address(router), 1000000000);
        token2.approve(address(router), 1000000000);

        router.addLiquidity(address(token1), address(token2), false, 100000000, 100000000, 100000000, 100000000, msg.sender, block.timestamp);
        POOL_1 = router.pairFor(address(token1), address(token2), false);
        IERC20(POOL_1).approve(address(seiCampaignStage2), 1000000000);

        seiCampaignStage2 = new SeiCampaignStage2(address(router), address(weth), address(voter));
        token1.approve(address(seiCampaignStage2), 1000000000);
        token2.approve(address(seiCampaignStage2), 1000000000);
        console2.log("POOL_1", POOL_1);
        seiCampaignStage2.addPair(POOL_1);

        vm.deal(address(owner), 1000000);
        charge(token1, address(owner), 1000000);

        IERC20(TOKEN_A).approve(address(router), type(uint256).max);
        router.addLiquidityETH{value : 10000}(TOKEN_A, false, 10000, 10000, 10000, msg.sender, block.timestamp);
        POOL_3 = router.pairFor(address(TOKEN_A), address(weth), false);
        IERC20(POOL_3).approve(address(seiCampaignStage2), type(uint256).max);
        seiCampaignStage2.addPair(POOL_3);

        address[] memory _tokens = new address[](2);
        _tokens[0] = TOKEN_A;
        _tokens[1] = TOKEN_B;
        console2.log("whitelist");
        voter.whitelist(_tokens);

        console2.log("createGauge");
        voter.createGauge(POOL_1, 0);
    }

    //forge test --match-test test_addLiquidityETH -vvv
    function test_addLiquidityETH() public {
        
        uint256 balanceA = IERC20(TOKEN_A).balanceOf(Alice);
        console2.log("before balanceA: %s, eth %s", balanceA, Alice.balance);

        vm.startPrank(Alice);
        IERC20(TOKEN_A).approve(address(seiCampaignStage2), type(uint256).max);
        seiCampaignStage2.addLiquidityETH{value : 10000}(TOKEN_A, false, 10000, 10000, 10000, block.timestamp, address(0));
        vm.stopPrank();

        balanceA = IERC20(TOKEN_A).balanceOf(Alice);
        console2.log("after balanceA: %s, eth %s", balanceA, Alice.balance);

        uint256 lp = IERC20(POOL_3).balanceOf(Alice);
        console2.log("Alice lp %s", lp);


        RouterV2.route[] memory path = new RouterV2.route[](1);
        path[0] = RouterV2.route({from:address(weth), to:address(TOKEN_A), stable:false});
        vm.startPrank(Bob);
        IERC20(TOKEN_A).approve(address(seiCampaignStage2), type(uint256).max);
        seiCampaignStage2.swapExactETHForTokens{value : 10000}(100, path, block.timestamp, address(0));
        vm.stopPrank();
        uint256 balanceB = IERC20(TOKEN_A).balanceOf(Bob);
        console2.log("Bob after1 balanceB: %s, eth %s", balanceB, Bob.balance);


        path[0] = RouterV2.route({from:address(TOKEN_A), to:address(weth), stable:false});
        vm.startPrank(Bob);
        // IERC20(TOKEN_A).approve(address(seiCampaignStage2), type(uint256).max);
        seiCampaignStage2.swapExactTokensForETH(10000, 9000, path, block.timestamp, address(0));
        vm.stopPrank();
        balanceB = IERC20(TOKEN_A).balanceOf(Bob);
        console2.log("Bob after2 balanceB: %s, eth %s", balanceB, Bob.balance);

    }

    //forge test --match-test test_swap_deposit_invite -vvv
    function test_swap_deposit_invite() public {
        console2.log("====================================");
        vm.roll(1);
        uint256 balanceA = IERC20(TOKEN_A).balanceOf(Alice);
        uint256 balanceB = IERC20(TOKEN_B).balanceOf(Alice);
        console2.log("balanceA: %s, balanceB: %s", balanceA, balanceB);

        swap(Alice, address(0), POOL_1);

        balanceA = IERC20(TOKEN_A).balanceOf(Alice);
        balanceB = IERC20(TOKEN_B).balanceOf(Alice);
        console2.log("balanceA: %s, balanceB: %s", balanceA, balanceB);

        vm.roll(2);
        deposit(Alice, address(0), POOL_1);

        vm.roll(3);
        swap(Bob, Alice, POOL_1);

        vm.roll(4);
        swap(Chris, Alice, POOL_1);

        uint256 userCnt = seiCampaignStage2.getUserCnt();
        console2.log("userCnt:", userCnt);

        uint256 swapCnt = seiCampaignStage2.getSwapCntOf(Alice, POOL_1);
        uint256 depositCnt = seiCampaignStage2.getDepositCntOf(Alice, POOL_1);

        SeiCampaignStage2.Info memory info = seiCampaignStage2.getUserInfo(Alice);
        console2.log("Alice sp:%s, dp:%s, ip:%s", info.swap, info.deposit, info.invite);

        address superior = seiCampaignStage2.superiorOf(Bob);
        console2.log("Bob superior:", superior);

        uint256 balanceYAKA = IERC20(address(YAKA)).balanceOf(Alice);
        console2.log("before balanceYAKA %s", balanceYAKA);
        uint256 veTokenId = lock(Alice, address(0), 100000000000);
        balanceYAKA = IERC20(address(YAKA)).balanceOf(Alice);
        console2.log("after balanceYAKA %s", balanceYAKA);
        assertEq(Alice, IERC721(address(ve)).ownerOf(veTokenId));

        bool ret = verifyVote(1, Alice, address(0));
        assertEq(ret, false);
        vote(veTokenId, Alice);
        ret = verifyVote(veTokenId, Alice, address(0));
        assertEq(ret, true);
        info = seiCampaignStage2.getUserInfo(Alice);
        console2.log("Alice lp:%s, vp:%s", info.lock, info.vote);


        // vm.roll(4);
        // deposit(Bob, address(0), POOL_1);
        // swapCnt = seiCampaignStage2.getSwapCntOf(Bob, POOL_1);
        // depositCnt = seiCampaignStage2.getDepositCntOf(Bob, POOL_1);
        // console2.log("Bob swapCnt: %s, depositCnt:%s", swapCnt, depositCnt);
        // (sp, dp, ip, lp, vp) = seiCampaignStage2.getPoints(Bob);
        // console2.log("Bob sp:%s, dp:%s, ip:%s", sp, dp, ip);

        // vm.roll(5);
        // swap(Chris, Bob, POOL_1);
        // swapCnt = seiCampaignStage2.getSwapCntOf(Chris, POOL_1);
        // depositCnt = seiCampaignStage2.getDepositCntOf(Chris, POOL_1);
        // console2.log("Chris swapCnt: %s, depositCnt:%s", swapCnt, depositCnt);
        // (sp, dp, ip, lp, vp) = seiCampaignStage2.getPoints(Chris);
        // console2.log("Chris sp:%s, dp:%s, ip:%s", sp, dp, ip);

        // inviteCnt = seiCampaignStage2.invitedCntOf(Bob);
        // console2.log("Bob inviteCnt:", inviteCnt);

        // superior = seiCampaignStage2.superiorOf(Chris);
        // console2.log("Chris superior:", superior);

    }

    //forge test --match-test test_native_swap -vvv
    function test_native_swap() public {
        console2.log("====================================");
        vm.roll(1);
        uint256 balanceA = IERC20(TOKEN_A).balanceOf(Alice);
        uint256 balanceB = IERC20(TOKEN_B).balanceOf(Alice);
        console2.log("balanceA: %s, balanceB: %s", balanceA, balanceB);
        nativeSwap(Alice);
        balanceA = IERC20(TOKEN_A).balanceOf(Alice);
        balanceB = IERC20(TOKEN_B).balanceOf(Alice);
        console2.log("balanceA: %s, balanceB: %s", balanceA, balanceB);
    }

    function nativeSwap(address user) internal {
        RouterV2.route[] memory path = new RouterV2.route[](1);
        path[0] = RouterV2.route({from:address(TOKEN_A), to:address(TOKEN_B), stable:false});

        vm.startPrank(user);
        token1.approve(address(router), 1000);
        token2.approve(address(router), 1000);

        router.swapExactTokensForTokens(
            100,
            90,
            path,
            user,
            block.timestamp
        );
        vm.stopPrank();
    }


    function swap(address user, address inviter, address pool) internal {
        RouterV2.route[] memory path = new RouterV2.route[](1);
        path[0] = RouterV2.route({from:address(TOKEN_A), to:address(TOKEN_B), stable:false});

        vm.startPrank(user);
        token1.approve(address(seiCampaignStage2), 1000);
        token2.approve(address(seiCampaignStage2), 1000);

        seiCampaignStage2.swapExactTokensForTokens(
            100,
            90,
            path,
            block.timestamp,
            inviter);
        vm.stopPrank();
    }



    function deposit(address user, address inviter, address pool) internal {
        vm.startPrank(user);
        token1.approve(address(seiCampaignStage2), 1000);
        token2.approve(address(seiCampaignStage2), 1000);

        seiCampaignStage2.addLiquidity(
            TOKEN_A,
            TOKEN_B,
            false,
            100,
            100,
            95,
            95,
            block.timestamp,
            inviter
        );
        vm.stopPrank();
    }

    function lock(address user, address inviter, uint256 value) internal returns(uint256) {
        uint256 _lock_duration = 365 days;
        vm.startPrank(user);
        console2.log("approve");
        YAKA.approve(address(seiCampaignStage2), value);
        console2.log("create_lock_for");
        uint256 veTokenId = seiCampaignStage2.create_lock_for(value, _lock_duration, user, inviter);
        vm.stopPrank();
        console2.log("veTokenId:%s", veTokenId);
        return veTokenId;
    }

    function vote(uint256 _tokenId, address user) internal returns(uint256) {
        address[] memory _poolVote = new address[](1);
        _poolVote[0] = POOL_1;

        uint256[] memory _weights = new uint256[](1);
        _weights[0] = 100;

        vm.startPrank(user);
        // IERC721(address(ve)).approve(address(voter), );
        voter.vote(_tokenId, _poolVote, _weights);
        vm.stopPrank();
    }

    function verifyVote(uint256 tokenId, address user, address inviter) internal returns(bool) {
        vm.startPrank(user);
        bool ret =seiCampaignStage2.verifyVote(tokenId, inviter);
        vm.stopPrank();
        return ret;
    }

    function charge(MockToken erc20, address user, uint256 amount) internal {
        vm.startPrank(user);
        erc20.mint(amount);
        vm.stopPrank();
    }

    function chargeYAKA(address user, uint256 amount) internal {
        vm.startPrank(COMMUNITY);
        YAKA.transfer(user, amount);
        vm.stopPrank();
    }
}