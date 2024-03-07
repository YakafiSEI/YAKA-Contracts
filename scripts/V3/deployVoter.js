const { ethers  } = require('hardhat');
const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");
const file_utils = require("../fileUtils");


async function main () {

    accounts = await ethers.getSigners();
    owner = accounts[0]
    

    console.log('Deploying Contracts...');

    const contracts_deployed = file_utils.readData(file_utils.deployPath);
    
    ve = contracts_deployed['VotingEscrow']
    pairFactory = contracts_deployed['PairFactory']
    gaugeFactoryV2 = contracts_deployed['GaugeFactoryV2']
    bribeFactoryV3 = contracts_deployed['BribeFactoryV3']

    console.log(" votingEscrow:%s \n pairFactory:%s \n gaugeFactoryV2:%s \n bribeFactoryV3:%s", 
    ve, pairFactory, gaugeFactoryV2, bribeFactoryV3);


    data = await ethers.getContractFactory("VoterV3");
    input = [ve, pairFactory , gaugeFactoryV2, bribeFactoryV3]
    VoterV3 = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    txDeployed = await VoterV3.deployed();
    console.log("Voter: ", VoterV3.address);

    contracts_deployed['VoterV3'] = VoterV3.address;
    file_utils.saveData(file_utils.deployPath, contracts_deployed);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
