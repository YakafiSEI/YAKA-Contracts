// 1:1 with Hardhat test
pragma solidity 0.8.20;

import "./BaseTest.sol";

contract MinterTest is BaseTest {

    function setUp() public {
        vm.warp(genesisEpoch);
        deployAll();
    }

    //forge test --match-test test_mint_initialize -vvv
    function test_mint_initialize() public {
        minter.initialize();
        assertEq(IERC20(address(YAKA)).balanceOf(address(initialDistributor)), 200_000_000 * 1e18);
        assertEq(minter.active_period(), 0);
        assertEq(minter.genesis_time(), 0);
        
        vm.warp(genesisEpoch + 1);
        minter.startActivePeriod();
        assertEq(minter.active_period(), genesisEpoch);
        assertEq(minter.genesis_time(), genesisEpoch);
    }


}