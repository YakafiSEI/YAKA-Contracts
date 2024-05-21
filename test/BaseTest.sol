// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
// import "solmate/test/utils/mocks/MockERC20.sol";
import "../contracts/interfaces/IERC20.sol";
import "../contracts/Yaka.sol";
import "../contracts/Minter.sol";
import "../contracts/VoterV3.sol";
import "../contracts/factories/PairFactory.sol";
import {GaugeFactoryV2} from "../contracts/factories/GaugeFactoryV2.sol";
import {BribeFactoryV3} from "../contracts/factories/BribeFactoryV3.sol";
import {RouterV2} from "../contracts/RouterV2.sol";
import "../contracts/VotingEscrow.sol";
import "../contracts/VeArtProxyUpgradeable.sol";
import "../contracts/InitialDistributor.sol";
import {SeiCampaignStage2} from "../contracts/SeiCampaignStage2.sol";
import "./utils/TestOwner.sol";
import "./utils/WETH.sol";
import {PermissionsRegistry} from "../contracts/PermissionsRegistry.sol";

abstract contract BaseTest is Test {
    uint32 public initBlockTime = 1682553600; //2023-04-27
    uint32 public genesisEpoch = initBlockTime;

    address public admin = address(9999);
    address public TEAM = address(9998);
    address public COMMUNITY = address(9997);
    address public LP = address(9996);
    address public TREASURY = address(9995);

    TestOwner owner;

    Yaka YAKA;
    VoterV3 voter;
    VotingEscrow ve;
    Minter minter;
    PairFactory factory;
    GaugeFactoryV2 gaugeFactory;
    BribeFactoryV3 bribeFactory;

    RouterV2 router;
    InitialDistributor initialDistributor;
    SeiCampaignStage2 seiCampaignStage2;
    PermissionsRegistry permissionsRegistry;
    WETH weth;

    function deployAll() public {
        deployOwners();
        deployCoins();   
        deployBase();
    }

    function deployOwners() public {
        owner = TestOwner(address(this));
    }

    function deployCoins() public {
        // USDC = new MockERC20("USDC", "USDC", 6);
        weth = new WETH();
        YAKA = new Yaka();
    }

    function deployBase() public {
        console.log("owner %s", address(owner));
        VeArtProxyUpgradeable artProxy = new VeArtProxyUpgradeable();
        ve = new VotingEscrow(address(YAKA), address(artProxy));

        permissionsRegistry = new PermissionsRegistry();
        permissionsRegistry.setRoleFor(address(owner), "GOVERNANCE");
        permissionsRegistry.setRoleFor(address(owner), "VOTER_ADMIN");
        console2.log("permissionsRegistry %s", address(permissionsRegistry));

        factory = new PairFactory();
        factory.setDibs(address(99999999));
        router = new RouterV2(address(factory), address(weth));

        gaugeFactory = new GaugeFactoryV2();
        gaugeFactory.initialize(address(permissionsRegistry));

        bribeFactory = new BribeFactoryV3();
        bribeFactory.initialize(address(0), address(permissionsRegistry));

        voter = new VoterV3();
        voter.initialize(address(ve), address(factory), address(gaugeFactory), address(bribeFactory));
        bribeFactory.setVoter(address(voter));
        ve.setVoter(address(voter));

        initialDistributor = new InitialDistributor(address(ve), LP, COMMUNITY, TEAM, TREASURY);
        minter = new Minter(address(voter), address(ve), address(0), address(initialDistributor), TEAM);
        address[] memory _tokens = new address[](0);
        voter._init(_tokens, address(permissionsRegistry), address(minter));


        YAKA.setMinter(address(minter));
        initialDistributor.setMinter(address(minter));
    }



    receive() external payable {}
}