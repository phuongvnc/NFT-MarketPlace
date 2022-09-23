function getEnviroment() {
    const dotenv = require("dotenv");
    dotenv.config();
    return process.env;
}

async function deploy(contractName, args) {
    console.log(`Start Deploying ${contractName}`);
    const Web3 = require("web3");
    const { PROJECT_ID } = getEnviroment();
    const provider = `https://goerli.infura.io/v3/${PROJECT_ID}`;
    const web3Provider = new Web3.providers.HttpProvider(provider);
    const web3 = new Web3(web3Provider);
    const metadata = require(`./build/contracts/${contractName}.json`);
    const contract = new web3.eth.Contract(metadata.abi);

    contract.deploy({
        data: metadata.bytecode,
        arguments: args,
    });

    provider.engine.stop();
    console.log(`End Deploying ${contractName}`);
}

deploy("Marketplace", null);
