// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UniswapV3LiquidityManager {
    INonfungiblePositionManager public positionManager;
    ISwapRouter public swapRouter;

    constructor(address _positionManager, address _swapRouter) {
        positionManager = INonfungiblePositionManager(_positionManager);
        swapRouter = ISwapRouter(_swapRouter);
    }

    struct LiquidityParams {
        address poolAddress;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 width;  // Ширина позиции
    }

 

    function provideLiquidity(
        LiquidityParams memory params
    ) external {
        IUniswapV3Pool pool = IUniswapV3Pool(params.poolAddress);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();  // Получаем текущую цену

        uint256 currentPrice = uint256(sqrtPriceX96) * uint256(sqrtPriceX96) / (2**192);  // Цена, преобразованная из формата Q64.96

        // Рассчитываем нижнюю и верхнюю цены на основе заданной ширины
        uint256 upperPrice = currentPrice * (10000 + params.width) / 10000;
        uint256 lowerPrice = currentPrice * (10000 - params.width) / 10000;

        // Преобразуем цены в тики для Uniswap
        int24 lowerTick = TickMath.getTickAtSqrtRatio(uint160(sqrt(lowerPrice) << 96));
        int24 upperTick = TickMath.getTickAtSqrtRatio(uint160(sqrt(upperPrice) << 96));

        // Разрешаем positionManager забирать наши токены
        IERC20(pool.token0()).transferFrom(msg.sender, address(this), params.amount0Desired);
        IERC20(pool.token1()).transferFrom(msg.sender, address(this), params.amount1Desired);

        IERC20(pool.token0()).approve(address(positionManager), params.amount0Desired);
        IERC20(pool.token1()).approve(address(positionManager), params.amount1Desired);

        // Добавляем ликвидность
        INonfungiblePositionManager.MintParams memory mintParams = INonfungiblePositionManager.MintParams({
            token0: pool.token0(),
            token1: pool.token1(),
            fee: pool.fee(),
            tickLower: lowerTick,
            tickUpper: upperTick,
            amount0Desired: params.amount0Desired,
            amount1Desired: params.amount1Desired,
            amount0Min: 0,  // Минимумы можно настроить на основе slippage tolerance
            amount1Min: 0,
            recipient: msg.sender,
            deadline: block.timestamp + 300  // 5 минут
        });

        positionManager.mint(mintParams);  // Создаем позицию с ликвидностью
    }

    // Геттер-функция для расчета возможной ликвидности
    function calculateLiquidity(
        LiquidityParams memory params
    ) external view returns (uint256 liquidity, uint256 lowerTick, uint256 upperTick) {
        IUniswapV3Pool pool = IUniswapV3Pool(params.poolAddress);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();  // Получаем текущую цену

        uint256 currentPrice = uint256(sqrtPriceX96) * uint256(sqrtPriceX96) / (2**192);  // Цена, преобразованная из формата Q64.96

        // Рассчитываем нижнюю и верхнюю цены на основе заданной ширины
        uint256 upperPrice = currentPrice * (10000 + params.width) / 10000;
        uint256 lowerPrice = currentPrice * (10000 - params.width) / 10000;

        // Преобразуем цены в тики для Uniswap
        lowerTick = TickMath.getTickAtSqrtRatio(uint160(sqrt(lowerPrice) << 96));
        upperTick = TickMath.getTickAtSqrtRatio(uint160(sqrt(upperPrice) << 96));

        // Рассчитываем ликвидность для заданного диапазона
        liquidity = _calculateLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(int24(lowerTick)),
            TickMath.getSqrtRatioAtTick(int24(upperTick)),
            params.amount0Desired,
            params.amount1Desired
        );
    }

    // Вспомогательная функция для расчета ликвидности
    function _calculateLiquidityForAmounts(
        uint160 sqrtPriceX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) internal pure returns (uint256 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) {
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        }

        uint256 liquidity0 = (amount0Desired * (uint256(sqrtRatioBX96) - uint256(sqrtRatioAX96))) /
            (uint256(sqrtPriceX96) * uint256(sqrtRatioBX96) / 2**96);

        uint256 liquidity1 = (amount1Desired * 2**96) / (uint256(sqrtRatioBX96) - uint256(sqrtRatioAX96));

        liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
    }

    // Функция sqrt для расчета
    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
