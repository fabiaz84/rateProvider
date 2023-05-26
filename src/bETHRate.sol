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
        _scalingFactor = 10**SafeMath.sub(18, AggregatorV3Interface(_feed).decimals());
        _scalingFactorbETH = 10**SafeMath.sub(18, IbETHPriceFeed(_bethfeed).decimals());
    }

    /**
     * @return the value of the quote currency in terms of the base currency
     */
    function _getETHRate() internal view returns (uint256) {
        (, int256 price, , , ) = pricefeed.latestRoundData();
        require(price > 0, "Invalid price rate response");
        return uint256(price) * _scalingFactor;
    }

    function _getbETHConversion() internal view returns (uint256) {
        int256 _bETHprice;
        _bETHprice = bETHPriceFeed.latestAnswer();
        require(_bETHprice > 0, "Invalid price rate response");
        return fdiv((uint256(_bETHprice) * _scalingFactorbETH), _getETHRate(), 1 ether);
    } 

    function getRate() external view override returns (uint256 rate) {
        rate = _getbETHConversion();
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