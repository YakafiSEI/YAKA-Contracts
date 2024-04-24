const { ethers  } = require('hardhat');
const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");
const file_utils = require("../fileUtils");


async function main () {

    accounts = await ethers.getSigners();
    owner = accounts[0]
    

    console.log('Deploying Contracts...');

    const contracts_deployed = file_utils.readData(file_utils.deployPath);
    
    voter = contracts_deployed['VoterV3']
    maxLoops = 100

    console.log(" voter:%s, maxLoops:%d", voter, maxLoops);


    data = await ethers.getContractFactory("DistributeFees");
    

    DistributeFees = await data.deploy(voter, maxLoops);
    txDeployed = await DistributeFees.deployed();
    console.log("DistributeFees: ", DistributeFees.address);

    /*
    input = [voter, maxLoops];
    DistributeFees = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    txDeployed = await DistributeFees.deployed();
    console.log("DistributeFees: ", DistributeFees.address);
    */

    contracts_deployed['DistributeFees'] = DistributeFees.address;
    file_utils.saveData(file_utils.deployPath, contracts_deployed);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
