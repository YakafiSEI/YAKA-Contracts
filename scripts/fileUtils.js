
const fs = require('fs');
 

module.exports = {

    readData: function(path) {
        try {
            const data = fs.readFileSync(path); 
            return JSON.parse(data);
        } catch (error) {
            console.log(`read data error：${error}`);
            throw error;
        }
    },

    saveData : function(path, data) {
        try {
            const jsonData = JSON.stringify(data);
            fs.writeFileSync(path, jsonData);
        } catch (error) {
            console.log(`write data error：${error}`);
            throw error;
        }
    },
    deployPath: "/Users/carlos/WorkSpace/DaoProject/YAKA-Contracts/scripts/contracts.json"
}
