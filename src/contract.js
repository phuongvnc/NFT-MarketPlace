import Web3 from "web3";
import { ContractAddress } from "./config";

class JackpotContract {
  async connect() {
    if (window.ethereum.selectedProvider === null) return;
    const metadata = require("../contract/build/contracts/Jackpot.json");
    this.web3 = new Web3(window.ethereum.selectedProvider);
    this.contract = new this.web3.eth.Contract(metadata.abi, ContractAddress);
    this.owner = await this.getContractOwner();
    this.account = await window.ethereum.request({ method: "eth_accounts" })[0];
    window.ethereum.on("accountsChanged", function (accounts) {
      this.account = accounts[0];
    });
    this.listenerBuyTicketEvent();
  }

  // Common function
  async buyTicket(ticketNumber, amount) {
    const account = await this.getCurrentAccount();
    return await this.contract.methods.buyTicket(ticketNumber).send({
      from: account,
      value: this.web3.utils.toWei(amount.toString(), "ether"),
    });
  }

  async getContractOwner() {
    return this.contract.methods.owner().call();
  }

  async getTotalTicket() {
    const account = await this.getCurrentAccount();
    console.log("account:", account);
    return this.contract.methods.getTotalTicket(account).call();
  }

  async getTicket(index) {
    const account = await this.getCurrentAccount();
    return this.contract.methods.getTicket(account, index).call();
  }

  async getCurrentAccount() {
    const accounts = await window.ethereum.request({ method: "eth_accounts" });
    return accounts[0];
  }

  async totalAmount() {
    return this.contract.methods.totalAmount().call();
  }

  async winnerAmount() {
    return this.contract.methods.winnerAmount().call();
  }

  // Owner function
  async lockContract() {
    return this.contract.methods.lock().send({ from: this.owner });
  }

  async unlockContract() {
    return this.contract.methods.unlock().send({ from: this.owner });
  }

  async setWinNumber(number) {
    return this.contract.methods
      .setWinNumber(number)
      .send({ from: this.owner });
  }

  async withdraw() {
    return this.contract.methods.withdraw().send({ from: this.owner });
  }

  async withdrawToUser(address, amount) {
    return this.contract.methods
      .withdraw(address, amount)
      .send({ from: this.owner });
  }

  // Handle Listener Event
  listenerBuyTicketEvent() {
    this.contract.events
      .BuyTicket(() => {})
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

  listenerWinnerPrizeEvent() {
    this.contract.events
      .WinnerPrize(() => {})
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

export default new JackpotContract();
