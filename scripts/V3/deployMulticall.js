const { ethers  } = require('hardhat');
const file_utils = require("../fileUtils");


async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');

    // read contract address
    const contracts_deployed = file_utils.readData(file_utils.deployPath);

    data = await ethers.getContractFactory("Multicall2");
    Multicall = await data.deploy();
    txDeployed = await Multicall.deployed();
    console.log("Multicall2: ", Multicall.address);

    // save contract address
    contracts_deployed['Multicall2'] = Multicall.address;
    file_utils.saveData(file_utils.deployPath, contracts_deployed);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
