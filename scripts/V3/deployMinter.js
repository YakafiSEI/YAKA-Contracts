const { ethers  } = require('hardhat');
const file_utils = require("../fileUtils");


async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');

    // read contract address
    const contracts_deployed = file_utils.readData(file_utils.deployPath);
    const initConfig = contracts_deployed['InitialDistroConfig']
    
    const ve = contracts_deployed['VotingEscrow'];
    const voter =	contracts_deployed['VoterV3'];
    const rewDistro = contracts_deployed['RewardsDistributor'];
    const team = initConfig['TEAM'];
    const initDistro = contracts_deployed['InitialDistributor'];

    console.log(" ve:%s\n voter:%s\n rewDistro:%s\n initDistro:%s\n team:%s\n", ve, voter, rewDistro, initDistro, team);

    data = await ethers.getContractFactory("Minter");
    Minter = await data.deploy(voter, ve, rewDistro, initDistro, team);
    txDeployed = await Minter.deployed();
    console.log("Minter: ", Minter.address);

    // save contract address
    contracts_deployed['Minter'] = Minter.address;
    file_utils.saveData(file_utils.deployPath, contracts_deployed);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
