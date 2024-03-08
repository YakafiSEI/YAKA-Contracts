const { ethers } = require('hardhat');
const file_utils = require("../fileUtils");

async function main() {

  accounts = await ethers.getSigners();
  owner = accounts[0];

  console.log('Deploying Contract...');

  const contracts_deployed = file_utils.readData(file_utils.deployPath);
  // get contract address

  // PairAPI
  const voter = contracts_deployed['VoterV3']

  console.log("deploy PairAPI, params: voter:%s", voter);
  // deploy
  data = await ethers.getContractFactory("PairAPI");
  input = [voter]
  PairAPI = await upgrades.deployProxy(data, input, { initializer: 'initialize' });
  txDeployed = await PairAPI.deployed();
  console.log("PairAPI: ", PairAPI.address)

  // RewardAPI deploy
  console.log("deploy RewardAPI, params: voter:%s", voter);

  data = await ethers.getContractFactory("RewardAPI");
  input = [voter]
  RewardAPI = await upgrades.deployProxy(data, input, { initializer: 'initialize' });
  txDeployed = await RewardAPI.deployed();
  console.log("RewardAPI: ", RewardAPI.address)

  // veNFTAPI deploy
  const rewDistro = contracts_deployed['RewardsDistributor'];

  console.log("deploy veNFTAPI, params: voter:%s rewDistro:%s", voter, rewDistro);
  
  data = await ethers.getContractFactory("veNFTAPI");
  input = [voter, rewDistro, PairAPI.address]
  veNFTAPI = await upgrades.deployProxy(data, input, { initializer: 'initialize' });
  txDeployed = await veNFTAPI.deployed();
  console.log("veNFTAPI: ", veNFTAPI.address);

  // save address
  const APIS = {"PairAPI": PairAPI.address, "RewardAPI": RewardAPI.address, "VeNFTAPI": veNFTAPI.address};
  contracts_deployed["APIS"] = APIS;
  file_utils.saveData(file_utils.deployPath, contracts_deployed);


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
