// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

//import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
//import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/FeedRegistryInterface.sol";
import "./interfaces/SafeMath.sol";
import "./interfaces/IRateProvider.sol";
import "./interfaces/IbETHPriceFeed.sol";

contract bETHRate is IRateProvider {
    AggregatorV3Interface public immutable pricefeed;
    IbETHPriceFeed public immutable bETHPriceFeed;
    uint256 internal immutable _scalingFactor;
    uint256 internal immutable _scalingFactorbETH;

    constructor(address _feed, address _bethfeed) {
        pricefeed = AggregatorV3Interface(_feed);
        bETHPriceFeed = IbETHPriceFeed(_bethfeed);
        _scalingFactor = 10**SafeMath.sub(36, AggregatorV3Interface(_feed).decimals());
        _scalingFactorbETH = 10**SafeMath.sub(18, IbETHPriceFeed(_bethfeed).decimals());
    }

    function getRate() external view override returns (uint256 rate) {
        (, int256 ethPrice, , , ) = pricefeed.latestRoundData();
        require(ethPrice > 0, "Invalid price rate response");
        uint256 _ethPrice = uint256(ethPrice) * _scalingFactor;
        int256 bETHprice = bETHPriceFeed.latestAnswer();
        require(bETHprice > 0, "Invalid price rate response");
        uint256 _bETHPrice = uint256(bETHprice) * _scalingFactorbETH;
        rate = fdiv(_ethPrice, _bETHPrice, 1 ether);
        return rate;
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            if iszero(eq(div(mul(x,baseUnit),x),baseUnit)) {revert(0,0)}
            z := div(mul(x,baseUnit),y)
        }
    }
}