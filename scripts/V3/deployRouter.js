const { ethers  } = require('hardhat');
const file_utils = require("../fileUtils");

async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');

    // read contract address
    const contracts_deployed = file_utils.readData(file_utils.deployPath);

    const pairFactoryAddress = contracts_deployed['PairFactory'];
    const wseiAddress = contracts_deployed['WSEI']

    console.log("pairFactory:%s, wsei:%s", pairFactoryAddress, wseiAddress);

    data = await ethers.getContractFactory("RouterV2");
    router = await data.deploy(pairFactoryAddress, wseiAddress);

    txDeployed = await router.deployed();
    console.log("router: ", router.address)

    contracts_deployed['Router'] = router.address;
    file_utils.saveData(file_utils.deployPath, contracts_deployed);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
