const { ethers  } = require('hardhat');
const file_utils = require("../fileUtils");

async function main () {

    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    // YAKA
    data = await ethers.getContractFactory("Yaka");
    yaka = await data.deploy();
    txDeployed = await yaka.deployed();
    console.log("Yaka Address: ", yaka.address)

    // VeArtProxyUpgradeable
    data = await ethers.getContractFactory("VeArtProxyUpgradeable");
    veArtProxy = await upgrades.deployProxy(data,[], {initializer: 'initialize'});
    txDeployed = await veArtProxy.deployed();
    console.log("VeArtProxy Address: ", veArtProxy.address)

    // VotingEscrow
    data = await ethers.getContractFactory("VotingEscrow");
    veYaka = await data.deploy(yaka.address, veArtProxy.address);
    txDeployed = await veYaka.deployed();
    console.log("VotingEscrow Address: ", veYaka.address)

    // RewardsDistributor
    data = await ethers.getContractFactory("RewardsDistributor");
    RewardsDistributor = await data.deploy(veYaka.address);
    txDeployed = await RewardsDistributor.deployed();
    console.log("RewardsDistributor Address: ", RewardsDistributor.address)


    // save deploy contract address to file
  const contracts_deployed = file_utils.readData(file_utils.deployPath);

  contracts_deployed['Yaka'] = yaka.address;
  contracts_deployed['VeArtProxy'] = veArtProxy.address;
  contracts_deployed['VotingEscrow'] = veYaka.address;
  contracts_deployed['RewardsDistributor'] = RewardsDistributor.address;

  file_utils.saveData(file_utils.deployPath, contracts_deployed);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
