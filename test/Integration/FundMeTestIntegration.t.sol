//SPDX-License-Identifier: MIT

pragma solidity >=0.8.7 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTestIntegration is Test {
    FundMe fundMe;
    DeployFundMe deployFundMe = new DeployFundMe();
    FundFundMe fundFundMe = new FundFundMe();
    WithdrawFundMe withdrawFundMe = new WithdrawFundMe();

    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant GAS_PRICE = 1;
    address USER = makeAddr("user");

    function setUp() external {
        console.log("msg.sender address: %s", msg.sender);
        fundMe = deployFundMe.run();
        console.log("FundMeIntegration's address: %s", address(this));
        deal(USER, 2 ether);
    }

    function testUserCanFundInteractions() external {
        console.log("FundMETestIntegration's address: %s", address(this));
        console.log("fundFundMe's address: %s", address(fundFundMe));
        console.log("USER's address: %s, USER's balance: %e", USER, USER.balance);
        vm.prank(USER);
        fundFundMe.fundFundMe{value: SEND_VALUE}(address(fundMe));
        (uint256 amount,) = fundMe.getTxInfoByAddress(address(fundFundMe));
        console.log("amount sent by %s is %s", address(fundFundMe), amount);
        (amount,) = fundMe.getTxInfoByAddress(address(fundFundMe));
        console.log("amount sent by %s is %s", USER, amount);
        //transaction is intended to be performed by USER
        //checking contract address's transaction just in case
        assertEq(amount, SEND_VALUE);
    }

    modifier fundedInteractions() {
        //vm.prank(USER);
        fundFundMe.fundFundMe{value: SEND_VALUE}(address(fundMe));
        console.log("sending to: %s", address(fundMe));
        _;
    }

    function testUserCanWithdrawIntegrations() external fundedInteractions {
        uint256 userBalanceStart = msg.sender.balance;
        uint256 fundMeBalanceStart = address(fundMe).balance;
        console.log("userBalanceStart: %s, fundMeBalanceStart: %s", userBalanceStart, fundMeBalanceStart);

        console.log("tryng to withdraw from: %s", address(fundMe));

        withdrawFundMe.withdrawFundMe(address(fundMe));

        uint256 userBalanceEnd = msg.sender.balance;
        uint256 fundMeBalanceEnd = address(fundMe).balance;
        console.log("userBalanceEnd: %s, fundMeBalanceEnd: %s", userBalanceEnd, fundMeBalanceEnd);
        assertEq(userBalanceStart + SEND_VALUE, userBalanceEnd);
        assertEq(fundMeBalanceStart - SEND_VALUE, fundMeBalanceEnd);
    }
}
