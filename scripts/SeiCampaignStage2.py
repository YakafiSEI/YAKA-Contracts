from web3 import Web3
import requests
import os

providerUrl = "https://evm-rpc-arctic-1.sei-apis.com"

adapter = requests.adapters.HTTPAdapter(pool_connections=20, pool_maxsize=20)
session = requests.Session()
session.mount('http://', adapter)
session.mount('https://', adapter)

w3 = Web3(Web3.HTTPProvider(providerUrl, session=session, request_kwargs={'timeout': 60}))



contractAddresss = "0x12c738CAeebCa375c529e6F7919423D18076ccca"

abi = '[{"type":"constructor","inputs":[{"name":"_router","type":"address","internalType":"address"}],"stateMutability":"nonpayable"},{"type":"function","name":"addLiquidity","inputs":[{"name":"tokenA","type":"address","internalType":"address"},{"name":"tokenB","type":"address","internalType":"address"},{"name":"stable","type":"bool","internalType":"bool"},{"name":"amountADesired","type":"uint256","internalType":"uint256"},{"name":"amountBDesired","type":"uint256","internalType":"uint256"},{"name":"amountAMin","type":"uint256","internalType":"uint256"},{"name":"amountBMin","type":"uint256","internalType":"uint256"},{"name":"deadline","type":"uint256","internalType":"uint256"},{"name":"inviter","type":"address","internalType":"address"}],"outputs":[{"name":"amountA","type":"uint256","internalType":"uint256"},{"name":"amountB","type":"uint256","internalType":"uint256"},{"name":"liquidity","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"addPair","inputs":[{"name":"_pair","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"admin","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"batchGetPoints","inputs":[{"name":"start","type":"uint256","internalType":"uint256"},{"name":"end","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"},{"name":"","type":"uint256[]","internalType":"uint256[]"}],"stateMutability":"view"},{"type":"function","name":"boardingTimeOf","inputs":[{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"depositBadgeOf","inputs":[{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"depositCntOf","inputs":[{"name":"","type":"address","internalType":"address"},{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint32","internalType":"uint32"}],"stateMutability":"view"},{"type":"function","name":"getDepositCntOf","inputs":[{"name":"user","type":"address","internalType":"address"},{"name":"pool","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getPoints","inputs":[{"name":"user","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"},{"name":"","type":"uint256","internalType":"uint256"},{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getSwapCntOf","inputs":[{"name":"user","type":"address","internalType":"address"},{"name":"pool","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getUserCnt","inputs":[],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"inviteBadgeOf","inputs":[{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"invitedCntOf","inputs":[{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"pairWhiteList","inputs":[{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"pairs","inputs":[{"name":"","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"removeLiquidity","inputs":[{"name":"tokenA","type":"address","internalType":"address"},{"name":"tokenB","type":"address","internalType":"address"},{"name":"stable","type":"bool","internalType":"bool"},{"name":"liquidity","type":"uint256","internalType":"uint256"},{"name":"amountAMin","type":"uint256","internalType":"uint256"},{"name":"amountBMin","type":"uint256","internalType":"uint256"},{"name":"deadline","type":"uint256","internalType":"uint256"},{"name":"inviter","type":"address","internalType":"address"}],"outputs":[{"name":"amountA","type":"uint256","internalType":"uint256"},{"name":"amountB","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"router","inputs":[],"outputs":[{"name":"","type":"address","internalType":"contract RouterV2"}],"stateMutability":"view"},{"type":"function","name":"superiorOf","inputs":[{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"swapBadgeOf","inputs":[{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"swapCntOf","inputs":[{"name":"","type":"address","internalType":"address"},{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint32","internalType":"uint32"}],"stateMutability":"view"},{"type":"function","name":"swapExactTokensForTokens","inputs":[{"name":"amountIn","type":"uint256","internalType":"uint256"},{"name":"amountOutMin","type":"uint256","internalType":"uint256"},{"name":"routes","type":"tuple[]","internalType":"struct RouterV2.route[]","components":[{"name":"from","type":"address","internalType":"address"},{"name":"to","type":"address","internalType":"address"},{"name":"stable","type":"bool","internalType":"bool"}]},{"name":"deadline","type":"uint256","internalType":"uint256"},{"name":"inviter","type":"address","internalType":"address"}],"outputs":[{"name":"amounts","type":"uint256[]","internalType":"uint256[]"}],"stateMutability":"nonpayable"},{"type":"function","name":"users","inputs":[{"name":"","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"}]'


campaignContract = w3.eth.contract(address=contractAddresss, abi=abi)
#读取
admin = campaignContract.functions.admin().call()
print(admin)
pairs = campaignContract.functions.pairs(1).call()
print(pairs)
#写入
accountInfo = {
    "address":"",
    "privateKey":""
}

pair='0x61C8b1F76BFd469da872b5D90eb1652d526e233e'
chain_id=713715
print('nonce:', w3.eth.get_transaction_count(accountInfo['address']))
def addPair():
    transferTx = campaignContract.functions.addPair(pair).build_transaction(
        {"chainId": chain_id, "gasPrice": w3.eth.gas_price, "from": accountInfo['address'],'nonce': w3.eth.get_transaction_count(accountInfo['address'])}
    )
    #签名
    signedTx = w3.eth.account.sign_transaction(transferTx, accountInfo['privateKey'])
    #发送签名后的交易
    txHash = w3.eth.send_raw_transaction(signedTx.rawTransaction)
    print("txHash", Web3.to_hex(txHash))
    #等待交易执行完成
    txReceipt = w3.eth.wait_for_transaction_receipt(txHash)
    print(Web3.to_json(txReceipt))




def addLiquidity():
    tokenA = '0x5F70F0B1b079885885746Bf58B37B96dfd91bA64'
    tokenB = '0x3973fC5d8b4b118B010489Ebbc3CeBA052bD0ac4'
    stable = False
    amountADesired = 100000000000000000000000
    amountBDesired = 200000000000000000000000
    amountAMin = 100000000000000000000000
    amountBMin = 200000000000000000000000
    deadline = 1714504329
    inviter= '0x0000000000000000000000000000000000000000'
    transferTx = campaignContract.functions.addLiquidity(tokenA, tokenB, stable, amountADesired, amountBDesired, amountAMin, amountBMin, deadline, inviter).build_transaction(
        {"chainId": chain_id, "gasPrice": w3.eth.gas_price, "from": accountInfo['address'],'nonce': w3.eth.get_transaction_count(accountInfo['address'])}
    )
    #签名
    signedTx = w3.eth.account.sign_transaction(transferTx, accountInfo['privateKey'])
    #发送签名后的交易
    txHash = w3.eth.send_raw_transaction(signedTx.rawTransaction)
    print("txHash", Web3.to_hex(txHash))
    #等待交易执行完成
    txReceipt = w3.eth.wait_for_transaction_receipt(txHash)
    print(Web3.to_json(txReceipt))

addLiquidity()