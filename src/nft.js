import Web3 from "web3";

class NFT {
  constructor(contract_address) {
    this.contract_address = contract_address;
  }

  async connect() {
    if (window.ethereum.selectedProvider === null) return;
    const metadata = require("../contract/build/contracts/TomosiaNFT.json");
    this.web3 = new Web3(window.ethereum.selectedProvider);
    this.contract = new this.web3.eth.Contract(
      metadata.abi,
      this.contract_address
    );
    this.owner = await this.getContractOwner();
    this.account = await window.ethereum.request({ method: "eth_accounts" })[0];
    window.ethereum.on("accountsChanged", function (accounts) {
      this.account = accounts[0];
    });
  }

  async getContractOwner() {
    return this.contract.methods.owner().call();
  }

  // Contract Method

  async setBaseURI(base_uri) {
    return this.contract.methods.setBaseURI(base_uri).send({ from: this.owner });
  }

  async mintNfts(urls) {
    await this.checkContractOwner();
    return this.contract.methods.mintNfts(urls).send({ from: this.owner });
  }

  async mintNft(url) {
    await this.checkContractOwner();
    return this.contract.methods.mintNft(url).send({ from: this.owner });
  }

  async safeTransferFrom(from, to, tokenId) {
    return this.contract.methods
      .safeTransferFrom(from, to, tokenId)
      .send({ from: this.account });
  }

  async transferFrom(from, to, tokenId) {
    return this.contract.methods
      .transferFrom(from, to, tokenId)
      .send({ from: this.account });
  }

  async setApprovalForAll(operator, approved) {
    return this.contract.methods
      .setApprovalForAll(operator, approved)
      .send({ from: this.owner });
  }

  async approve(to, tokenId) {
    return this.contract.methods.approve(to, tokenId).send({ from: this.owner });
  }

  async burn(tokenId) {
    return this.contract.methods.burn(tokenId).send({ from: this.account });
  }

  // Get methods

  async ownerTokenIds(owner) {
    return this.contract.methods.ownerTokenIds(owner).call();
  }

  async balanceOf(owner) {
    return this.contract.methods.balanceOf(owner).call();
  }

  async isApprovedForAll(owner, operator) {
    return this.contract.methods.isApprovedForAll(owner, operator).call();
  }

  async ownerOf(tokenId) {
    return this.contract.methods.ownerOf(tokenId).call();
  }

  async paused(tokenId) {
    return this.contract.methods.paused().call();
  }

  async tokenURI(tokenId) {
    return this.contract.methods.tokenURI(tokenId).call();
  }

  async checkContractOwner() {
    if (this.owner === null || this.owner === undefined) {
      this.owner = await this.getContractOwner();
    }
  }
}

export default NFT;
