// SPDX-License-Identifier: MIT

//Fund
//Withdraw

pragma solidity >=0.8.7 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "src/FundMe.sol";

contract FundFundMe is Test {
    uint256 constant SEND_VALUE = 0.1 ether;

    //FundMe public fundMe;

    function fundFundMe(address _mostRecentlyDeployed) public payable {
        //fundMe = FundMe(_mostRecentlyDeployed);
        (bool sent,) = address(payable(_mostRecentlyDeployed)).call{value: SEND_VALUE}("");
        console.log("trying to send from address: %s", msg.sender);
        console.log("sent status: %s, sent value: %e", sent, SEND_VALUE);
    }

    function run() external {
        console.log("trying to fund the most recently deployed contract");
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        console.log("current FundMe address: %s", mostRecentlyDeployed);
        vm.startBroadcast();
        fundFundMe(mostRecentlyDeployed);
        vm.stopBroadcast();
    }
}

contract WithdrawFundMe is Test {
    function withdrawFundMe(address _mostRecentlyDeployed) public {
        console.log("WithdrawFundMe's address %s", address(this));
        vm.startBroadcast();
        FundMe(payable(_mostRecentlyDeployed)).cheapWithdraw();
        vm.stopBroadcast();
    }

    function run() external {
        console.log("trying to withdraw from the most recently deployed contract");
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        console.log("current FundMe address: %s", mostRecentlyDeployed);

        withdrawFundMe(mostRecentlyDeployed);
    }
}
