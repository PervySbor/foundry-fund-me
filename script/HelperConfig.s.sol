//SPDX-License-Identifier: MIT

pragma solidity >=0.8.7 <0.9.0;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else if (block.chainid == 42161) {
            activeNetworkConfig = getArbitrumEthConfig();
        } else if (block.chainid == 56) {
            activeNetworkConfig = getBNBChainEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    NetworkConfig public activeNetworkConfig;

    //if we're on a local anvil, we deploy mocks
    //Otherwise, grab the existing addresses from the live network

    struct NetworkConfig {
        address priceFeed;
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        //does everything related to Sepolia
        //price feed address
        //and so on...
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46
        });
        return sepoliaConfig;
    }

    function getArbitrumEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612
        });
        return sepoliaConfig;
    }

    function getBNBChainEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e
        });
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
