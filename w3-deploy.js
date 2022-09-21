export default async function deploy(contractName, args) {
    console.log(`Start Deploying ${contractName}`);
    const Truffle = require("./truffle-config");
    const Web3 = require("web3");
    const web3 = new Web3(Truffle.networks.goerli.provider);
    const metadata = require(`./build/contracts/${contractName}.json`);
    const accounts = await web3.eth.getAccounts();
    const contract = new web3.eth.Contract(metadata.abi);

    const newContractInstance = await contract
        .deploy({
            data: metadata.bytecode,
            arguments: args,
        })
        .send({
            from: accounts[0],
            gas: 1500000,
        });

    provider.engine.stop();
    console.log(`End Deploying ${contractName}`);
}