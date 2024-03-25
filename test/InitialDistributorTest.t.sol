pragma solidity 0.8.20;

import "./BaseTest.sol";

contract InitialDistributorTest is BaseTest {

    address public Alice = address(1);
    address public Bob = address(2);

    function setUp() public {
        vm.label(address(Alice), "Alice");
        vm.label(address(Bob), "Bob");

        vm.warp(genesisEpoch);
        deployAll();

        minter.initialize();
        assertEq(IERC20(address(YAKA)).balanceOf(address(initialDistributor)), 200_000_000 * 1e18);
    }

    //forge test --match-test test_supplyImmediately -vvv
    function test_supplyImmediately() public {
        
        initialDistributor.supplyImmediately();
        assertEq(IERC20(address(YAKA)).balanceOf(COMMUNITY), 50_000_000 * 1e18);
        assertEq(IERC20(address(YAKA)).balanceOf(LP), 10_000_000 * 1e18);
    }

    //forge test --match-test test_claimForPresale -vvv
    function test_claimForPresale() public {
        address[] memory users = new address[](2);
        users[0] = Alice;
        users[1] = Bob;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1000;
        amounts[1] = 2000;

        initialDistributor.addWhitelistOfPresale(users, amounts);

        uint256 amount = initialDistributor.claimableForPresale(Alice);
        assertEq(amount, 0);
        launchDex();

        vm.warp(genesisEpoch + 3 days);
        vm.roll(1);
        vm.startPrank(Alice);
        initialDistributor.claimForPresale();
        vm.stopPrank();
        amount = IERC20(address(YAKA)).balanceOf(Alice);
        assertEq(300, amount);

        //=========== week 1 =============
        vm.warp(genesisEpoch + 1 weeks);
        vm.roll(2);
        vm.startPrank(Alice);
        initialDistributor.claimForPresale();
        vm.stopPrank();

        amount = IERC20(address(YAKA)).balanceOf(Alice);
        assertEq(300 + 1*58, amount);

        //=========== week 2 =============
        vm.warp(genesisEpoch + 2 weeks);
        vm.roll(3);
        vm.startPrank(Alice);
        initialDistributor.claimForPresale();
        vm.stopPrank();

        amount = IERC20(address(YAKA)).balanceOf(Alice);
        assertEq(300 + 2*58, amount);

        //=========== week 3 =============
        vm.warp(genesisEpoch + 3 weeks);
        vm.roll(4);
        vm.startPrank(Alice);
        initialDistributor.claimForPresale();
        vm.stopPrank();

        amount = IERC20(address(YAKA)).balanceOf(Alice);
        assertEq(300 + 3 * 58, amount);

        //=========== week 12 =============
        vm.warp(genesisEpoch + 13 weeks + 1 days);
        vm.roll(5);
        vm.startPrank(Alice);
        initialDistributor.claimForPresale();
        vm.stopPrank();

        amount = IERC20(address(YAKA)).balanceOf(Alice);
        assertEq(300 + 700, amount);
    }


    //forge test --match-test test_claimForPartner -vvv
    function test_claimForPartner() public {
        initialDistributor.addWhitelistOfPartner(true, Alice, 1000);

        uint256 amount = initialDistributor.claimableForPartner(true, Alice);
        assertEq(amount, 0);
        launchDex();

        vm.warp(genesisEpoch + 1 weeks);
        vm.roll(1);
        amount = initialDistributor.claimableForPartner(true, Alice);
        assertEq(1000, amount);

        vm.roll(2);
        vm.startPrank(Alice);
        initialDistributor.claimForPartner(true, Alice);
        vm.stopPrank();

        uint256 veLength = ve.balanceOf(Alice);
        uint256 veYakaId = ve.tokenOfOwnerByIndex(Alice, 0);
        (int128 lockedBalance, uint256 end) = ve.locked(veYakaId);
        assertEq(1000, lockedBalance);
        assertEq(1, veLength);
        assertEq(1, veYakaId);
        assertEq(genesisEpoch + 1 weeks + 104 weeks, end);//lock 104 weeks

        vm.warp(genesisEpoch + 2 weeks);
        vm.roll(3);
        amount = initialDistributor.claimableForPartner(true, Alice);
        assertEq(0, amount);
    }

    //forge test --match-test test_addForPartner -vvv
    function test_addForPartner() public {
        uint256 MAX_1 = 40_000_000 * 1e18;
        uint256 MAX_2 = 30_000_000 * 1e18;
        initialDistributor.addWhitelistOfPartner(true, Alice, MAX_1);

        initialDistributor.addWhitelistOfPartner(false, Alice, MAX_2);
    }

    //forge test --match-test test_claimForTeam -vvv
    function test_claimForTeam() public {
        launchDex();
        vm.roll(1);
        vm.warp(genesisEpoch + 1 weeks);


        vm.startPrank(TEAM);
        initialDistributor.claimForTeam();
        vm.stopPrank();

        uint256 amount = IERC20(address(YAKA)).balanceOf(TEAM);
        uint256 veLength = ve.balanceOf(TEAM);
        uint256 veYakaId = ve.tokenOfOwnerByIndex(TEAM, 0);
        (int128 lockedBalance, uint256 end) = ve.locked(veYakaId);
        assertEq(15_000_000 * 1e18, lockedBalance);
        assertEq(genesisEpoch + 1 weeks + 104 weeks, end);//lock 104 weeks
        assertEq(1, veLength);
        assertEq(1, veYakaId);
        assertEq(amount, 0);

        vm.warp(genesisEpoch + 27 weeks);
        vm.roll(2);
        vm.startPrank(TEAM);
        initialDistributor.claimForTeam();
        vm.stopPrank();
        amount = IERC20(address(YAKA)).balanceOf(TEAM);
        uint256 week = 104;
        uint256 expect = 15000000 * 1e18 / week;
        assertEq(amount, expect);

        uint256 veLength2 = ve.balanceOf(TEAM);
        assertEq(1, veLength2);

    }

    //forge test --match-test test_claimForVestor -vvv
    // function test_claimForVestor() public {
    //     initialDistributor.addWhitelistOfVestor(Alice, 1000);

    //     uint256 amount = initialDistributor.claimableForVestor(Alice);
    //     assertEq(amount, 0);
    //     launchDex();

    //     vm.warp(genesisEpoch + 1 weeks);
    //     vm.roll(1);
    //     amount = initialDistributor.claimableForVestor(Alice);
    //     assertEq(0, amount);

    //     vm.warp(genesisEpoch + 27 weeks);
    //     vm.roll(2);

    //     vm.startPrank(Alice);
    //     initialDistributor.claimForVestor(Alice);
    //     vm.stopPrank();

    //     amount = IERC20(address(YAKA)).balanceOf(Alice);
    //     assertEq(amount, 9);

    //     vm.warp(genesisEpoch + 129 weeks);
    //     vm.roll(3);

    //     vm.startPrank(Alice);
    //     initialDistributor.claimForVestor(Alice);
    //     vm.stopPrank();
    //     amount = IERC20(address(YAKA)).balanceOf(Alice);
    //     assertEq(amount, 989);
    // }

    //forge test --match-test test_addForVestor -vvv
    // function test_addForVestor() public {
    //     uint256 MAX = 6_000_000 * 1e18;
    //     initialDistributor.addWhitelistOfVestor(Alice, MAX/2);
    //     initialDistributor.addWhitelistOfVestor(Bob, MAX/2);
    // }


    function launchDex() internal {
        assertEq(minter.active_period(), 0);

        vm.warp(genesisEpoch + 1);
        minter.startActivePeriod();
        assertEq(minter.active_period(), genesisEpoch);
        assertEq(minter.genesis_time(), genesisEpoch);
    }
}