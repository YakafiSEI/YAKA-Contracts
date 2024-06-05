const { ethers  } = require('hardhat');
const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");
const file_utils = require("../fileUtils");


async function main () {

    accounts = await ethers.getSigners();
    owner = accounts[0]
    

    console.log('Deploying Contracts...');

    const contracts_deployed = file_utils.readData(file_utils.deployPath);
    
    router = contracts_deployed['Router']
    const wseiAddress = contracts_deployed['WSEI']
    const voter = contracts_deployed['VoterV3']

    console.log(" router:%s, wseiAddress:%s,voter:%s", router,wseiAddress, voter);


    data = await ethers.getContractFactory("SeiCampaignStage2");
    SeiCampaignStage2 = await data.deploy(router, wseiAddress, voter);
    txDeployed = await SeiCampaignStage2.deployed();
    console.log("SeiCampaignStage2: ", SeiCampaignStage2.address);

    contracts_deployed['SeiCampaignStage2'] = SeiCampaignStage2.address;
    file_utils.saveData(file_utils.deployPath, contracts_deployed);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
