const { ethers  } = require('hardhat');
const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");
const file_utils = require("../fileUtils");


async function main () {

    accounts = await ethers.getSigners();
    owner = accounts[0]
    

    console.log('Deploying Contracts...');

    const contracts_deployed = file_utils.readData(file_utils.deployPath);
    
    yakaAddress = contracts_deployed['Yaka']
    // 1 yaka
    const maxClaimAmount = ethers.BigNumber.from("1000000000000000000")

    console.log("yakaAddress:%s maxClaimAmount:%d", yakaAddress, maxClaimAmount);


    data = await ethers.getContractFactory("YakaFaucet");
    YakaFaucet = await data.deploy(yakaAddress, maxClaimAmount);
    txDeployed = await YakaFaucet.deployed();
    console.log("YakaFaucet: ", YakaFaucet.address);

    contracts_deployed['YakaFaucet'] = YakaFaucet.address;
    file_utils.saveData(file_utils.deployPath, contracts_deployed);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
