import Web3 from "web3";

class MarketPlace {
  constructor(contract_address) {
    this.contract_address = "0x517af5EC956b68369eeCde27eF89AE191511bEc3";
    const metadata = require("../contract/build/contracts/Marketplace.json");
    this.web3 = new Web3(window.ethereum.selectedProvider);
    this.contract = new this.web3.eth.Contract(metadata.abi, contract_address);
  }

  async connect() {
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
  async addNFTSupportAddress(address) {
    onlyOwner(this.owner, this.account);
    return this.contract.methods
      .addNFTSupportAddress(address)
      .send({ from: this.account });
  }

  async isNFTAddressSupported(address) {
    return this.contract.methods.isNFTAddressSupported(address).call();
  }

  async createMarketItems(tokenIds, address, price) {
    return this.contract.methods
      .createMarketItems(tokenIds, address, price)
      .send({ from: this.account });
  }

  async createMarketItem(tokenId, address, price) {
    return this.contract.methods
      .createMarketItem(tokenId, address, price)
      .send({ from: this.account });
  }

  async changeMarketItem(tokenId, address, price) {
    return this.contract.methods
      .changeMarketItem(tokenId, address, price)
      .send({ from: this.account });
  }

  async buyMarketItem(itemId, address, price) {
    return this.contract.methods
      .buyMarketItem(itemId, address)
      .send({ from: this.account, value: price });
  }

  async cancelMarketItem(itemId, address) {
    return this.contract.methods
      .buyMarketItem(itemId, address)
      .send({ from: this.account });
  }

  async fetchMarketItems(address) {
    return this.contract.methods.fetchMarketItems(address).call();
  }

  async fetchMyNFTs(sender, address) {
    return this.contract.methods.fetchMyNFTs(sender, address).call();
  }

  async fetchItemsCreated(sender, address) {
    return this.contract.methods.fetchItemsCreated(sender, address).call();
  }

  async setOldContract(address) {
    return this.contract.methods
      .setOldContract(address)
      .send({ from: this.account });
  }

  async setNewContract(address) {
    return this.contract.methods
      .setNewContract(address)
      .send({ from: this.account });
  }

  async migrate() {
    return this.contract.methods.migrate().send({ from: this.account });
  }

  // Handle Listener Event
  listenerMarketItemCreatedEvent() {
    this.contract.events
      .MarketItemCreated(() => {})
      .on("connected", function (subscriptionId) {
        console.log("SubID: ", subscriptionId);
      })
      .on("data", function (event) {
        console.log("Event:", event);
        console.log("Event:", event.returnValues);
      })
      .on("changed", function (event) {})
      .on("error", function (error, receipt) {
        console.log("Error:", error, receipt);
      });
  }

  listenerMarketItemCancelledEvent() {
    this.contract.events
      .MarketItemCancelled(() => {})
      .on("connected", function (subscriptionId) {
        console.log("SubID: ", subscriptionId);
      })
      .on("data", function (event) {
        console.log("Event:", event);
        console.log("Event:", event.returnValues);
      })
      .on("changed", function (event) {})
      .on("error", function (error, receipt) {
        console.log("Error:", error, receipt);
      });
  }

  listenerMarketItemSoldEvent() {
    this.contract.events
      .MarketItemSold(() => {})
      .on("connected", function (subscriptionId) {
        console.log("SubID: ", subscriptionId);
      })
      .on("data", function (event) {
        console.log("Event:", event);
        console.log("Event:", event.returnValues);
      })
      .on("changed", function (event) {})
      .on("error", function (error, receipt) {
        console.log("Error:", error, receipt);
      });
  }
}

export default MarketPlace;
