import Web3 from "web3";
import dotenv from 'dotenv';

 async function deploy(contractName, args, from, gas) {
  dotenv.config();
  const { PROJECT_ID } = process.env;
  const provider = `https://goerli.infura.io/v3/${PROJECT_ID}`;
  const web3Provider = new Web3.providers.HttpProvider(provider);
  const web3 = new Web3(web3Provider);

  console.log(`deploying ${contractName}`);

  const buildPath = `./build/contracts/${contractName}.json`;

  const metadata = require(buildPath);
  const contract = new web3.eth.Contract(metadata.abi);

  const newContractInstance = await contract.deploy({
    data: metadata.bytecode,
    arguments: args,
  }).contractSend.send({
    from: from,
    gas: 1500000,
  });

  return newContractInstance.options;
}

export default deploy;