const { ethers  } = require('hardhat');
const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");
const file_utils = require("../fileUtils");


async function main () {

    accounts = await ethers.getSigners();
    owner = accounts[0]
    
    console.log('Deploying Contracts...');

    const contracts_deployed = file_utils.readData(file_utils.deployPath);
    const initConfig = contracts_deployed['InitialDistroConfig']
    
    veAddress = contracts_deployed['VotingEscrow']
    lpAddress = initConfig['LP']
    idoAddress = initConfig['IDO']
    teamAddress = initConfig['TEAM']
    treasuryAddress = initConfig['TREASURY']

    console.log(" ve:%s \n lp:%s \n ido:%s \n team:%s, \ntreasury:%s", veAddress, lpAddress, idoAddress, teamAddress, treasuryAddress);


    data = await ethers.getContractFactory("InitialDistributor");
    initDistro = await data.deploy(veAddress, lpAddress, idoAddress, teamAddress, treasuryAddress);
    txDeployed = await initDistro.deployed();
    console.log("InitialDistributor:", initDistro.address);

    contracts_deployed['InitialDistributor'] = initDistro.address;
    file_utils.saveData(file_utils.deployPath, contracts_deployed);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
