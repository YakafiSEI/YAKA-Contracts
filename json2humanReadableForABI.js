const { ethers } = require("ethers");
const fs = require('fs');
const path = require('path');

const folderPath = './out';
const abiOutPutPath = "./out/abi";

async function main() {

  if (!fs.existsSync(abiOutPutPath)) {
    fs.mkdirSync(abiOutPutPath);
  }

  const files = fs.readdirSync(folderPath);

  files.forEach(file => {
    if (path.extname(file) === '.sol') {

      try {
        let baseName = path.basename(file, '.sol');
        let abiPath = "./out/" + baseName + ".sol/" + baseName + ".json";
  
        let jsonAbi = require(abiPath).abi;
  
        const iface = new ethers.utils.Interface(jsonAbi);
        let formattedAbi = iface.format(false);//true : minimal | false : human readable
        // console.log(formattedAbi);

        let outputFilePath = path.join(abiOutPutPath, `${baseName}.abi`);
        const jsonContent = JSON.stringify(formattedAbi, null, 2);
        fs.writeFileSync(outputFilePath, jsonContent, 'utf8');
        console.log(`ABI for ${baseName} written to ${outputFilePath}`);


      } catch (error) {
        console.error(`An error occurred while processing ${file}: ${error}`);
      }
    }
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
