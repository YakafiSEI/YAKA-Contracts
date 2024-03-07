const { hexValue } = require('ethers/lib/utils');
const { ethers, upgrades } = require('hardhat');

const file_utils = require("../fileUtils");

async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    var name = "SKY"
    var symbol = "SKY"
    
    var data = await ethers.getContractFactory("ERC20Token");
    sky20TestContract = await data.deploy(name, symbol);
    txDeployed = await sky20TestContract.deployed();
    console.log("SKY Address: ", sky20TestContract.address)

    name = "SAI"
    symbol = "SAI"
    
    data = await ethers.getContractFactory("ERC20Token");
    sai20TestContract = await data.deploy(name, symbol);
    txDeployed = await sai20TestContract.deployed();
    console.log("SAI Address: ", sai20TestContract.address)

    // save address
    const contracts_deployed = file_utils.readData(file_utils.deployPath);
    const erc20TestToken = {"SKY": sky20TestContract.address, "SAI": sai20TestContract.address}
    contracts_deployed['Erc20Test'] = erc20TestToken;
    file_utils.saveData(file_utils.deployPath, contracts_deployed);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
