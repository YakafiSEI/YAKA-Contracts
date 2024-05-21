pragma solidity 0.8.20;

import "./BaseTest.sol";

import {PermissionsRegistry} from "../contracts/PermissionsRegistry.sol";
// import {PairFactory} from "../contracts/factories/PairFactory.sol";
// import {GaugeFactoryV2} from "../contracts/factories/GaugeFactoryV2.sol";
// import {BribeFactoryV3} from "../contracts/factories/BribeFactoryV3.sol";

import {VoterV3} from "../contracts/VoterV3.sol";
import {RouterV2} from "../contracts/RouterV2.sol";

import {MockERC20} from "./MockERC20.sol";

contract VoterV3Test is BaseTest {

    address public Alice = address(1);
    address public Bob = address(2);
    address public WETH = 0xc838f522520137472494d8e2aEb341514e47eF54;

    address public musk = address(100);

    // contract
    // PermissionsRegistry permissionsRegistry;
    PairFactory pairFactory;
    // GaugeFactoryV2 gaugeFactory;
    // BribeFactoryV3 bribeFactory;
    // RouterV2 router;

    MockERC20 SKY;


    function setUp() public {
        vm.label(address(Alice), "Alice");
        vm.label(address(Bob), "Bob");

        vm.warp(genesisEpoch);

        vm.startPrank(musk);
        deployCoins();
        deployBase1();

        minter.initialize();

        vm.stopPrank();

        assertEq(IERC20(address(YAKA)).balanceOf(address(initialDistributor)), 200_000_000 * 1e18);

        initContract();
    }

    // forge test --match-path test/VoterV3.t.sol --match-contract VoterV3Test --match-test test_vote -vvvv
    function test_vote() public returns(address) {
        
        uint256 tokenId = _lock();
        // vote: vote(uint256 _tokenId, address[] calldata _poolVote, uint256[] calldata _weights) 
        //
        address pair = createPair();
        createGuage(pair);

        address[] memory _poolVote = new address[](1);
        _poolVote[0] = pair;
        uint256[] memory _weights = new uint256[](1);
        _weights[0] = 10000;

        vm.startPrank(musk);
         voter.vote(tokenId, _poolVote, _weights);
         // print 
         uint256 voted = voter.votes(tokenId, pair);
         console2.log("tokenId:%d,voted:%d", tokenId, voted);

         vm.stopPrank();

         return pair;
        
    }

    // forge test --match-path test/VoterV3.t.sol --match-contract VoterV3Test --match-test test_rewards -vvvv
    function test_rewards() public {
        address pool = test_vote();
        vm.warp(block.timestamp + 1 weeks);

        // get guage bribes
        address guageAddress = voter.gauges(pool);
        address internalBribe = voter.internal_bribes(guageAddress);
        address externalBribe = voter.external_bribes(guageAddress);

        console2.log("internalBribe:%s,externalBribe:%s", internalBribe, externalBribe);

    }

    function _lock() public returns(uint256) {
        uint256 amount = 10000 * 1e18;
        uint256 duration = 54 weeks;

        vm.startPrank(musk);
        YAKA.approve(address(ve), amount);

        uint256 tokenId = ve.create_lock(amount, duration);
        console2.log("tokenId:%d", tokenId);

        vm.stopPrank();

        return tokenId;
    }

    function initContract() public {

        SKY = new MockERC20("SKY", "SKY");
        SKY.mint(musk, 100000 * 1e18);
        console2.log("sky musk balance:%d",SKY.balanceOf(musk));

        vm.prank(address(minter));
        YAKA.mint(musk, 100000 * 1e18);

        console2.log("yaka musk balance:%d",YAKA.balanceOf(musk));

        // init contract
        vm.startPrank(musk);

        // permissionsRegistry = new PermissionsRegistry();
        pairFactory = new PairFactory();
        gaugeFactory = new GaugeFactoryV2();
        gaugeFactory.initialize(address(permissionsRegistry));
        bribeFactory = new BribeFactoryV3();
        bribeFactory.initialize(address(0), address(permissionsRegistry));

        // voter
        voter = new VoterV3();
        voter.initialize(address(ve), address(pairFactory), address(gaugeFactory), address(bribeFactory));
        address[] memory tokens = new address[](2);
        tokens[0] = address(YAKA);
        tokens[1] = address(SKY);
        voter._init(tokens, address(permissionsRegistry), address(minter));

        // ve 上设置voter
        ve.setVoter(address(voter));

        // 在bribeFactory setVoter
        bribeFactory.setVoter(address(voter));

        router = new RouterV2(address(pairFactory), WETH);

        vm.stopPrank();

        

    }

    function createPair() public returns(address) {
        uint256 amount = 10000 * 1e18;
        vm.startPrank(musk);
        YAKA.approve(address(router), amount);
        SKY.approve(address(router), amount);

        /* addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline) */
        uint256 deadline = genesisEpoch + 1 days;
        (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(address(YAKA), address(SKY), false, amount, amount, amount, amount, musk, deadline);
        console2.log("amountA:%d,amountB:%d, liquidity:%d", amountA, amountB, liquidity);
        // 查看pair
        address pair = router.pairFor(address(YAKA), address(SKY), false);
        console2.log("pair:%s", pair);
        vm.stopPrank();
        return pair;
    }

    function createGuage(address _pool) public {
        // createGauge(address _pool, uint256 _gaugeType) external nonReentrant returns (address _gauge, address _internal_bribe, address _external_bribe) 
        vm.startPrank(musk);
       (address _gauge, address _internal_bribe, address _external_bribe) = voter.createGauge(_pool, 0);
       console2.log("_gauge:%s, _internal_bribe:%s _external_bribe:%s", _gauge, _internal_bribe, _external_bribe);
        vm.stopPrank();
    }

    function deployBase1() public {
        VeArtProxyUpgradeable artProxy = new VeArtProxyUpgradeable();
        ve = new VotingEscrow(address(YAKA), address(artProxy));

        initialDistributor = new InitialDistributor(address(ve), LP, COMMUNITY, TEAM, TREASURY);
        minter = new Minter(address(voter), address(ve), address(0), address(initialDistributor), TEAM);

        YAKA.setMinter(address(minter));
        initialDistributor.setMinter(address(minter));
    }



}
