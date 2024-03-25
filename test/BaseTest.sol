// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
// import "solmate/test/utils/mocks/MockERC20.sol";
import "../contracts/interfaces/IERC20.sol";
import "../contracts/Yaka.sol";
import "../contracts/Minter.sol";
import "../contracts/VoterV3.sol";
import "../contracts/VotingEscrow.sol";
import "../contracts/VeArtProxyUpgradeable.sol";
import "../contracts/InitialDistributor.sol";
import "./utils/TestOwner.sol";

abstract contract BaseTest is Test {
    uint32 public initBlockTime = 1682553600; //2023-04-27
    uint32 public genesisEpoch = initBlockTime;

    address public admin = address(9999);
    address public TEAM = address(9998);
    address public COMMUNITY = address(9997);
    address public LP = address(9996);

    TestOwner owner;

    Yaka YAKA;
    VoterV3 voter;
    VotingEscrow ve;
    Minter minter;
    InitialDistributor initialDistributor;

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
        YAKA = new Yaka();
    }

    function deployBase() public {
        VeArtProxyUpgradeable artProxy = new VeArtProxyUpgradeable();
        ve = new VotingEscrow(address(YAKA), address(artProxy));

        initialDistributor = new InitialDistributor(address(ve), LP, COMMUNITY, TEAM);
        minter = new Minter(address(voter), address(ve), address(0), address(initialDistributor), TEAM);

        YAKA.setMinter(address(minter));
        initialDistributor.setMinter(address(minter));
    }



    receive() external payable {}
}