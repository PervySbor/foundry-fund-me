//SPDX-License-Identifier: MIT

pragma solidity >=0.8.7 <0.9.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256 result) {
        //abi
        //address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        (, int256 price, , , ) = _priceFeed.latestRoundData();
        // ETH in terms of USD
        return uint256(price * 1e10); //returns uint 1e18
    }

    function getConversionRate(
        //returns amt of USDT needed to buy ethAmount
        uint256 ethAmount,
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        return (getPrice(_priceFeed) * ethAmount) / 1e36;
        // Xe18 * Xe18 = (Xe36)  => Xe36 / 1e18 = Xe18
    }
}
