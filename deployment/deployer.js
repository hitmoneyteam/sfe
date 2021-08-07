const Web3 = require('web3')
const fs = require('fs')

const network = "bsc"
const contractName = "Lplottery"
const constructorArgs = [
    "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3",
    "0x3ad9594151886ce8538c1ff615efa2385a8c3a88",
    "0x4Fabb145d64652a948d72533023f6E7A623C7C53"
]

const secrets = JSON.parse(fs.readFileSync(`./secrets.json`, 'utf8'))
const account = secrets.account
const privateKey = secrets.privateKey
const rpcURLs = {
    'bsc': 'https://bsc-dataseed.binance.org/',
    'testnet': 'https://data-seed-prebsc-1-s1.binance.org:8545/'
}
 
const deploy = async (_contractName, _constructorArgs, _network) => {

    console.log(`\nDeploying ${_contractName} ...`)

    // web3 instance
    const web3 = new Web3(rpcURLs[_network])

    const contract = JSON.parse(fs.readFileSync(`./build/contracts/${_contractName}.json`, 'utf8'))
    const abi = contract.abi
    const bytecode = contract.bytecode
    
    // Contract Instance
    const deploy_contract = new web3.eth.Contract(abi)

    // Create Trnsaction
    const deployTx = deploy_contract.deploy({
        data: bytecode,
        arguments: _constructorArgs
    })

    // Sign Transaction
    const signedTx = await web3.eth.accounts.signTransaction({
        from: account,
        data: deployTx.encodeABI(),
        gas: web3.utils.toHex(8000000),
        gasPrice: web3.utils.toHex(web3.utils.toWei('30', 'gwei'))
    }, privateKey)
    
    // Send Signed Transaction
    const txReceipt = await web3.eth.sendSignedTransaction(
        signedTx.rawTransaction
    )
    const _contractAddress = txReceipt.contractAddress
    const _txStatus = txReceipt.status
    
    if(_txStatus) {
        console.log('Contract Deployed at Address:', _contractAddress)
    }
}

deploy(contractName, constructorArgs, network)
