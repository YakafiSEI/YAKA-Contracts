const { ethers  } = require('hardhat');
const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");
const file_utils = require("../fileUtils");

async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  // PERMISSION REGISTRY
  data = await ethers.getContractFactory("PermissionsRegistry");
  PermissionsRegistry = await data.deploy();
  txDeployed = await PermissionsRegistry.deployed();
  console.log("PermissionsRegistry: ", PermissionsRegistry.address)

  // pair factory
  data = await ethers.getContractFactory("PairFactory");
  pairFactory = await data.deploy();
  txDeployed = await pairFactory.deployed();
  console.log("pairFactory: ", pairFactory.address)

  // GAUGE FACTORY
  data = await ethers.getContractFactory("GaugeFactoryV2");
  input = [PermissionsRegistry.address]
  GaugeFactoryV2 = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
  txDeployed = await GaugeFactoryV2.deployed();
  console.log("GaugeFactoryV2: ", GaugeFactoryV2.address)

  // BRIBE FACTORY
  data = await ethers.getContractFactory("BribeFactoryV3");
  input = [ZERO_ADDRESS, PermissionsRegistry.address]
  BribeFactoryV3 = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
  txDeployed = await BribeFactoryV3.deployed();
  console.log("BribeFactoryV3: ", BribeFactoryV3.address)

  // GAUGE FACTORY _ CL
  data = await ethers.getContractFactory("GaugeFactoryV2_CL");
  input = [PermissionsRegistry.address, '0x993Ae2b514677c7AC52bAeCd8871d2b362A9D693']
  GaugeFactoryV2_CL = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
  txDeployed = await GaugeFactoryV2_CL.deployed();
  console.log("GaugeFactoryV2_CL: ", GaugeFactoryV2_CL.address)


  // save deploy contract address to file
  const contracts_deployed = file_utils.readData(file_utils.deployPath);

  contracts_deployed['PermissionsRegistry'] = PermissionsRegistry.address;
  contracts_deployed['PairFactory'] = pairFactory.address;
  contracts_deployed['GaugeFactoryV2'] = GaugeFactoryV2.address;
  contracts_deployed['BribeFactoryV3'] = BribeFactoryV3.address;
  contracts_deployed['GaugeFactoryV2_CL'] = GaugeFactoryV2_CL.address;

  file_utils.saveData(file_utils.deployPath, contracts_deployed);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
