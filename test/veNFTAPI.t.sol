// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {veNFTAPI} from "../contracts/APIHelper/veNFTAPI.sol";

interface IVeNFTAPI {
        struct pairVotes {
        address pair;
        uint256 weight;
    }

    struct veNFT {
        uint8 decimals;
        
        bool voted;
        uint256 attachments;

        uint256 id;
        uint128 amount;
        uint256 voting_amount;
        uint256 rebase_amount;
        uint256 lockEnd;
        uint256 vote_ts;
        pairVotes[] votes;        
        
        address account;

        address token;
        string tokenSymbol;
        uint256 tokenDecimals;
    }

    struct Reward {
        
        uint8 decimals;
        uint256 amount;
        address token;
    }

    function getNFTFromAddress(address _user) external view returns(veNFT[] memory venft);
}

contract VeNFTAPITest is Test {
   
    uint256 seiDevFork;
    address public veNFTApiAddress = 0xFFbB38Bb36007ce8Cf5D2d4b2dD1E0Cf0DDc585D;
    IVeNFTAPI public veNFTAPI;

    function setUp() public {
        string memory SEI_DEV_RPC_URL = "https://evm-rpc-arctic-1.sei-apis.com";
        seiDevFork = vm.createFork(SEI_DEV_RPC_URL);
        veNFTAPI = IVeNFTAPI(veNFTApiAddress);
    }

    // forge test --match-path test/veNFTAPI.t.sol --match-contract VeNFTAPITest --match-test test_getNFTFromAddress --fork-url=https://evm-rpc-arctic-1.sei-apis.com -vv
    function test_getNFTFromAddress() public {
        vm.selectFork(seiDevFork);
        address user = 0x18B39D22Fb5EC036f2D75dBB1E45853D90BAB799;
        (IVeNFTAPI.veNFT[] memory venft) = veNFTAPI.getNFTFromAddress(user);
        for(uint256 i = 0; i < venft.length; i++) {
            console2.log("decimals:%d", venft[i].decimals);
            console2.log("voted:%d", venft[i].voted);
            console2.log("attachments:%d", venft[i].attachments);
            console2.log("id:%d", venft[i].id);
            console2.log("amount:%d", venft[i].amount);
            console2.log("voting_amount:%d", venft[i].voting_amount);
            console2.log("rebase_amount:%d", venft[i].rebase_amount);
            console2.log("lockEnd:%d", venft[i].lockEnd);
            console2.log("vote_ts:%d", venft[i].vote_ts);
            console2.log("vote size:%d", venft[i].votes.length);
            console2.log("------- start, size:%d", venft[i].votes.length);
            for(uint256 j = 0; j < venft[i].votes.length; j++) {
                console2.log("vote pair :%s", venft[i].votes[j].pair);
                console2.log("vote weight :%d", venft[i].votes[j].weight);
            }
            console2.log("------- end");
            console2.log("account:%s", venft[i].account);
            console2.log("token:%s", venft[i].token);
            console2.log("tokenSymbol:%s", venft[i].tokenSymbol);
            console2.log("tokenDecimals:%d", venft[i].tokenDecimals);

            console2.log("+++++++++++");

            
        }
    }

}