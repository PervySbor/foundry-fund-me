//SPDX-License-Identifier: MIT

pragma solidity >=0.8.7 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    address private immutable i_owner;

    uint256 private s_bank;

    uint256 private s_minimumUSD;

    AggregatorV3Interface private immutable priceFeed;

    struct Transaction {
        address sender;
        uint256 amount;
        uint256 time;
    }

    Transaction[] private s_transactions;
    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    constructor(address _priceFeed) {
        console.log("constructor called, msg.sender = owner: %s", msg.sender);
        i_owner = msg.sender;
        s_bank = 0;
        s_minimumUSD = 50;
        priceFeed = AggregatorV3Interface(_priceFeed);
        console.log("FundMe's balance in constructor: %s", address(this).balance);
    }

    modifier onlyOwner() {
        console.log("tried withdraw from address %s", msg.sender);
        console.log("fundMe owner again: %s", i_owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    //function fund(uint256 value) external payable {}

    receive() external payable {
        /* require(
            msg.value * getPrice() >= minimumUSD,
            "Your donation is less than minimum donation amount"
        );*/
        console.log("your donation value in USD : %s", msg.value.getConversionRate(priceFeed));
        require(msg.value.getConversionRate(priceFeed) > 50, "Your donation is less than minimum donation amount");
        s_transactions.push(Transaction(msg.sender, msg.value, block.timestamp));
        s_bank += msg.value;
    }

    function cheapWithdraw() external onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (uint256 i = 0; i < fundersLength; i++) {
            s_addressToAmountFunded[s_funders[i]] = 0;
        }
        s_funders = new address[](0);
        delete s_transactions;
        address payable walletAddress = payable(msg.sender);
        console.log("s_bank: %s, actual balance: %s", s_bank, address(this).balance);
        (bool success,) = walletAddress.call{value: s_bank}("");
        require(success, "Failed to withdraw");
        s_bank = 0;
    }

    function withdraw() external onlyOwner {
        for (uint256 i = 0; i < s_funders.length; i++) {
            s_addressToAmountFunded[s_funders[i]] = 0;
        }
        s_funders = new address[](0);
        delete s_transactions;
        address payable walletAddress = payable(msg.sender);
        console.log("s_bank: %s, actual balance: %s", s_bank, address(this).balance);
        (bool success,) = walletAddress.call{value: s_bank}("");
        require(success, "Failed to withdraw");
        s_bank = 0;
    }

    function readTransactions() external view returns (Transaction[] memory) {
        return s_transactions;
    }

    function setMinimumUSD(uint256 _amtOfUSD) external {
        require(_amtOfUSD > 0 && _amtOfUSD < 1000, "inapropriate range");
        s_minimumUSD = _amtOfUSD;
    }

    function getOracleVersion() external view returns (uint256) {
        return priceFeed.version();
    }

    function getEthPrice() external view returns (uint256) {
        uint256 eth = 1e18;
        return eth.getConversionRate(priceFeed);
    }

    function getTxInfoByAddress(address _address) external view returns (uint256 amount, uint256 time) {
        for (uint256 i = 0; i < s_transactions.length; i++) {
            if (s_transactions[i].sender == _address) {
                return (s_transactions[i].amount, s_transactions[i].time);
            }
        }
        return (0, 0);
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getBank() external view returns (uint256) {
        return s_bank;
    }

    function getMinimumUSD() external view returns (uint256) {
        return s_minimumUSD;
    }

    function getUSDPriceFeedAddress() external view returns (address) {
        return address(priceFeed);
    }
}
