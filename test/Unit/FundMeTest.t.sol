//SPDX-License-Identifier: MIT

pragma solidity >=0.8.7 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract FundMeTest is Test, ZkSyncChainChecker {
    address USER = makeAddr("user");
    uint256 constant GAS_PRICE = 1;

    FundMe fundMe;
    DeployFundMe deployFundMe = new DeployFundMe();
    HelperConfig helperConfig = new HelperConfig();

    //for deployment
    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        //console.log("test contract's address: %s", address(this));
        //console.log("deployFundMe's address: %s", address(deployFundMe));
        fundMe = deployFundMe.run();
        viewPriceFeedInfo();
        deal(USER, 3e18);
        console.log("fundMe's owner: %s", fundMe.getOwner());
        console.log("fundMe's balance: %s", address(fundMe).balance);
        console.log("test contract address: %s", address(this));
        console.log("msg.sender address: %s", msg.sender);
        deal(fundMe.getOwner(), 0);
        console.log("msg.sender's balance: %s", msg.sender.balance);
    }

    modifier skipAnvil() {
        if (block.chainid == 31337) {
            return;
        } else {
            _;
        }
    }

    //skipping Anvil, cause we're double creating HelperConfig, which double Creates MockV3Aggregator
    //as the result, we check different MockV3Aggregator's addresses
    //in forks MockV3Aggregators aren't created
    function testPriceFeedSetCorrectly() public skipAnvil skipZkSync {
        address retreivedPriceFeed = address(fundMe.getUSDPriceFeedAddress());
        address expectedPriceFeed = helperConfig.activeNetworkConfig();
        assertEq(retreivedPriceFeed, expectedPriceFeed);
    }

    function viewPriceFeedInfo() internal view {
        console.log("Chain ID: %s", block.chainid);
        console.log("Oracle version: %s", fundMe.getOracleVersion());
        console.log("ETH/USDT Price Feed: %e", fundMe.getEthPrice());
    }

    function testMinimumUsdtLimit() public view {
        console.logUint(fundMe.getMinimumUSD());
        assertEq(fundMe.getMinimumUSD(), 50);
    }

    function testContractOwner() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testOracleVersion() public view {
        console.logUint(fundMe.getOracleVersion());
        if (block.chainid == 1) {
            assertEq(fundMe.getOracleVersion(), 6);
        } else {
            assertEq(fundMe.getOracleVersion(), 4);
        }
    }

    modifier funded(address sender, uint256 amount) {
        vm.prank(sender);
        (bool sent,) = address(fundMe).call{value: amount}("");
        console.logBool(sent);
        _;
    }

    function testTx() public funded(USER, 2e18) funded(address(this), 1e18) {
        console.log("Test contract address: %s", address(this));
        (uint256 amount,) = fundMe.getTxInfoByAddress(address(this));
        console.logUint(amount);
        assertEq(amount, 1e18);
        (amount,) = fundMe.getTxInfoByAddress(USER);
        console.logUint(amount);
        assertEq(amount, 2e18);
    }

    function test_RevertWhen_WithdrawerIsNotOwner() public {
        console.log("USER address: %s", USER);
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawSingleFunder() public funded(USER, 1e18) {
        console.log("test contract balance before transactions: %s", fundMe.getOwner().balance);
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();
        vm.prank(fundMe.getOwner()); //just to make sure
        fundMe.withdraw();
        console.log("test contract balance after transactions: %s", fundMe.getOwner().balance);

        uint256 gasLeft = gasleft();
        uint256 gasUsed = (gasStart - gasLeft) * tx.gasprice;
        console.log("gas left: %s, gas used: %s", gasLeft, gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public {
        //Arrange
        uint160 numberOfFunders = 10;
        for (uint160 i = 0; i < numberOfFunders; i++) {
            hoax(address(i + 1));
            (bool sent,) = address(fundMe).call{value: 1e18}("");
            if (!sent) {
                console.log("transaction N %s failed", i);
            }
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();
        vm.startPrank(fundMe.getOwner());
        //vm.startBroadcast();
        fundMe.withdraw();
        //vm.stopBroadcast();
        vm.stopPrank();
        uint256 gasLeft = gasleft();
        uint256 gasUsed = (gasStart - gasLeft) * tx.gasprice;
        console.log("gas left: %s, gas used: %s", gasLeft, gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
    }

    function testWithdrawFromMultipleFundersCheaper() public {
        //Arrange
        uint160 numberOfFunders = 10;
        console.log("starting fundMe balance: %s", address(fundMe).balance);
        for (uint160 i = 0; i < numberOfFunders; i++) {
            hoax(address(i + 1));
            (bool sent,) = address(fundMe).call{value: 1e18}("");
            if (!sent) {
                console.log("transaction N %s failed", i);
            }
            console.log("fundMe balance: %s", address(fundMe).balance);
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();
        vm.startPrank(fundMe.getOwner());
        fundMe.cheapWithdraw();
        vm.stopPrank();
        uint256 gasLeft = gasleft();
        uint256 gasUsed = (gasStart - gasLeft) * tx.gasprice;
        console.log("gas left: %s, gas used: %s", gasLeft, gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
    }
}
