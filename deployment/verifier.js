const util = require('util')
const exec = util.promisify(require('child_process').exec)


const contractName = "LPLottery"
const contractAddress = "0xE7fFD13C2090530b81D62Be7FCFb1765104d2eF0"
const network = "testnet"

const verify = async (_contractName, _contractAddress, _network) => {
    console.log("\nVerifying ...")
    console.log('Contract:', _contractName)
    console.log('Address:', _contractAddress)
    console.log('Network:', _network)

    const { stdout, stderr } = await exec(`truffle run verify ${_contractName}@${_contractAddress} --network ${_network}`)
    if(stderr != null) {
        console.log(stdout)
    } else {
        console.log('stderr:', stderr)
    }
}

verify(contractName, contractAddress, network)
