// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {INonfungiblePositionManager} from "./univ3-lib/INonfungiblePositionManager.sol";
import {IUniswapV3Factory} from "./univ3-lib/IUniswapV3Factory.sol";
import {TickMath} from "./univ3-lib/TickMath.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

contract UniswapV3LiquidityManager is Context {
    using SafeERC20 for IERC20;

    struct AddLiquidityParams {
        address lp;
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 width;
    }

    uint256 public constant MAX_WAITING_PERIOD = 300; // 5 minutes
    INonfungiblePositionManager public immutable POSITION_MANAGER;
    IUniswapV3Factory public FACTORY;



    constructor(address positionManager, address factory) {
        POSITION_MANAGER = INonfungiblePositionManager(positionManager);
        FACTORY = IUniswapV3Factory(factory);
    }

    function addLiquidityWithFixedWidth(AddLiquidityParams memory params) external returns (uint128) {
        address signer = _msgSender();

        (
            ,,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            ,,,,
        ) = POSITION_MANAGER.positions(params.tokenId);


        require(params.lp == FACTORY.getPool(token0, token1, fee), "LP address not equal");
        require(_calculateWidth(tickLower, tickUpper) == params.width, "Position width does not match expected width");


        IERC20(token0).safeTransferFrom(signer, address(this), params.amount0Desired);
        IERC20(token1).safeTransferFrom(signer, address(this), params.amount1Desired);


        IERC20(token0).approve(address(POSITION_MANAGER), params.amount0Desired);
        IERC20(token1).approve(address(POSITION_MANAGER), params.amount1Desired);


        INonfungiblePositionManager.IncreaseLiquidityParams memory positionParams = INonfungiblePositionManager.IncreaseLiquidityParams({
            tokenId: params.tokenId,
            amount0Desired: params.amount0Desired,
            amount1Desired: params.amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp + MAX_WAITING_PERIOD
        });


        (uint128 liquidity,,) = POSITION_MANAGER.increaseLiquidity(positionParams);

        return liquidity;
    }


    function _calculateWidth(int24 tickLower, int24 tickUpper) internal pure returns (uint256) {
        uint160 sqrtPriceLower = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtPriceUpper = TickMath.getSqrtRatioAtTick(tickUpper);

        uint256 lowPrice = uint256(sqrtPriceLower) * uint256(sqrtPriceLower) / (2**192);
        uint256 highPrice = uint256(sqrtPriceUpper) * uint256(sqrtPriceUpper) / (2**192);

        // Calculating width using this formula: (highPrice - lowPrice) * 10000 / (lowPrice + highPrice)
        return (highPrice - lowPrice) * 10000 / (lowPrice + highPrice);
    }
    
}
