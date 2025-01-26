//SPDX-License-Identifier: MIT

pragma solidity >=0.8.7 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        HelperConfig helperConfig = new HelperConfig();
        address ethToUsdtPriceFeed = helperConfig.activeNetworkConfig();
        //as everything before vm.startBroadcast() is calculated localy and not send as a transaction
        vm.startBroadcast();
        console.log("deployFundMe's address (from the inside): %s", address(this));
        console.log("msg.sender in DeployFundMe: %s", msg.sender);
        //FundMe fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        FundMe fundMe = new FundMe(ethToUsdtPriceFeed);
        console.log("FundMe's balance (inside deployment script): %s", address(fundMe).balance);
        //console.log("fundMe's owner: %s", fundMe.owner());
        vm.stopBroadcast();
        return fundMe;
    }
}
