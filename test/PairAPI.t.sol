// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "../contracts/APIHelper/PairAPI.sol";
    
interface IPairAPI {
    struct PairInfo {
        // pair info
        address pair_address; 			// pair contract address
        uint decimals; 			        // pair decimals
        PoolType pooltype; 				// pair pool type 
        uint total_supply; 			    // pair tokens supply
    
        // token pair info
        address token0; 				// pair 1st token address
        string token0_symbol; 			// pair 1st token symbol
        uint token0_decimals; 		    // pair 1st token decimals
        uint reserve0; 			        // pair 1st token reserves (nr. of tokens in the contract)

        address token1; 				// pair 2nd token address
        string token1_symbol;           // pair 2nd token symbol
        uint token1_decimals;    		// pair 2nd token decimals
        uint reserve1; 			        // pair 2nd token reserves (nr. of tokens in the contract)

        // pairs gauge
        address gauge; 				    // pair gauge address
        uint gauge_total_supply; 		// pair staked tokens (less/eq than/to pair total supply)
        address fee; 				    // pair fees contract address
        address bribe; 				    // pair bribes contract address
        uint emissions; 			    // pair emissions (per second)
        address emissions_token; 		// pair emissions token address
        uint emissions_token_decimals; 	// pair emissions token decimals

    }

    struct UserInfo {
        
        // User deposit
        
        address pair_address; 			// pair contract address
        uint claimable0;                // claimable 1st token from fees (for unstaked positions)
        uint claimable1; 			    // claimable 2nd token from fees (for unstaked positions)
        uint account_lp_balance; 		// account LP tokens balance
        uint account_gauge_balance;     // account pair staked in gauge balance
        uint account_gauge_earned; 		// account earned emissions for this pair
    }


    struct tokenBribe {
        address token;
        uint8 decimals;
        uint256 amount;
        string symbol;
    }
    

    struct pairBribeEpoch {
        uint256 epochTimestamp;
        uint256 totalVotes;
        address pair;
        tokenBribe[] bribes;
    }

    // stable/volatile classic x*y=k, CL = conc. liquidity algebra
    enum PoolType {STABLE, VOLATILE, CL}

    function getAllPair(uint _amounts, uint _offset) external view returns(PairInfo[] memory Pairs);
}

interface IVoterV3 {
    function createGauge(address _pool, uint256 _gaugeType) external returns (address _gauge, address _internal_bribe, address _external_bribe);
}

contract PairAPITest is Test {
   
    uint256 seiDevFork;
    address public pairAPIAddress = 0x4C770F6E1eE2E44Ec0BB93836eDA4EAc0b74A7ac;
    address public voterAddress = 0xaC1Ade0E515bE9F798B1f972cF59848bFe98b8F3;
    IPairAPI public pairAPI;
    IVoterV3 public voterV3;

    function setUp() public {
        string memory SEI_DEV_RPC_URL = "https://evm-rpc-arctic-1.sei-apis.com";
        seiDevFork = vm.createFork(SEI_DEV_RPC_URL);
        pairAPI = IPairAPI(pairAPIAddress);
        voterV3 = IVoterV3(voterAddress);
    }

    // forge test --match-path test/PairAPI.t.sol --match-contract PairAPITest --match-test test_getAllPair --fork-url=https://evm-rpc-arctic-1.sei-apis.com
    function test_getAllPair() public {
        vm.selectFork(seiDevFork);
        (IPairAPI.PairInfo[] memory pairs) =  pairAPI.getAllPair(5, 0);

        console2.log("length:%d", pairs.length);

        for(uint256 i = 0; i < pairs.length; i++) {
            console2.log("pair_address:%s", pairs[i].pair_address);
            console2.log("decimals:%d", pairs[i].decimals);
            //console2.log("pooltype:%s", pairs[i].pooltype);
            console2.log("total_supply:%d", pairs[i].total_supply);

            console2.log("token0:%s", pairs[i].token0);
            console2.log("token0_symbol:%s", pairs[i].token0_symbol);
            console2.log("token0_decimals:%d", pairs[i].token0_decimals);
            console2.log("reserve0:%d", pairs[i].reserve0);

            console2.log("token1:%s", pairs[i].token1);
            console2.log("token1_symbol:%s", pairs[i].token1_symbol);
            console2.log("token1_decimals:%d", pairs[i].token1_decimals);
            console2.log("reserve1:%d", pairs[i].reserve1);

            console2.log("gauge:%s", pairs[i].gauge);
            console2.log("gauge_total_supply:%d", pairs[i].gauge_total_supply);
            console2.log("fee:%s", pairs[i].fee);
            console2.log("bribe:%s", pairs[i].bribe);
            console2.log("emissions:%d", pairs[i].emissions);
            console2.log("emissions_token:%s", pairs[i].emissions_token);
            console2.log("emissions_token_decimals:%d", pairs[i].emissions_token_decimals);

            console2.log("--------");

        }

    }

     // forge test --match-path test/PairAPI.t.sol --match-contract PairAPITest --match-test test_createGuage --fork-url=https://evm-rpc-arctic-1.sei-apis.com
    function test_createGuage() public {
        vm.selectFork(seiDevFork);
        address pool = 0xAEc12dF3B29A7eC4213aB14Fdd781D5d2C829760;

        (address _gauge, address _internal_bribe, address _external_bribe) = voterV3.createGauge(pool, 0);
        console2.log("_gauge:%s,_internal_bribe:%s,_external_bribe:%s", _gauge, _internal_bribe, _external_bribe);
    }


}
