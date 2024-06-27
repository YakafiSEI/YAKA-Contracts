require("@nomicfoundation/hardhat-foundry");
// require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-web3");

const { PRIVATEKEY, APIKEY,PRIVATEKEY_MAINNEET } = require("./pvkey.js")

module.exports = {
  // latest Solidity version
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.7.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ]
  },

  networks: {

    bsc: {
      url: "https://bsc-dataseed1.binance.org",
      chainId: 56,
      accounts: PRIVATEKEY
    },

    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: PRIVATEKEY
    },


    op: {
      url: "https://mainnet.optimism.io",
      chainId: 10,
      accounts: PRIVATEKEY
    },
    

    hardhat: {
      forking: {
          url: "https://bsc-dataseed1.binance.org",
          chainId: 56,
      },
      //accounts: []
    },
    sei_dev : {
      url: "https://evm-rpc-arctic-1.sei-apis.com",
      chainId: 713715,
      accounts: PRIVATEKEY,
      allowUnlimitedContractSize: true
    },
    sei_test : {
      url: "https://evm-rpc-testnet.sei-apis.com",
      chainId: 1328,
      accounts: PRIVATEKEY,
      allowUnlimitedContractSize: true
    },
    sei_main : {
      url: "https://evm-rpc.sei-apis.com",
      timeout: 60000,
      chainId: 1329,
      accounts: PRIVATEKEY_MAINNEET,
      allowUnlimitedContractSize: true
    },
    sepolia : {
      url: "https://eth-sepolia.g.alchemy.com/v2/BrzpjuiAd7D6jCuR3FXfB0LH_A5ClzsD",
      chainId: 11155111,
      accounts: PRIVATEKEY,
      allowUnlimitedContractSize: true
    }
  
  },

  etherscan: {
    apiKey: {
      sei_main: "0e0cb6ed-15c4-44fd-bc37-2740ed4f0104"
    },
    customChains: [
      {
        network: "sei_main",
        chainId: 1329,
        urls: {
          apiURL: "https://seitrace.com/pacific-1/api",
          browserURL: "https://seitrace.com"
        }
      }
    ]
  },

  mocha: {
    timeout: 100000000
  },


}
