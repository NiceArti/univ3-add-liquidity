// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UniswapV3LiquidityManager} from "../src/UniswapV3LiquidityManager.sol";

contract UniswapV3LiquidityManagerTest is Test {
    address immutable user = makeAddr("User");

    UniswapV3LiquidityManager liquidityManager;
    INonfungiblePositionManager positionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88); // Адрес PositionManager на mainnet
    ISwapRouter swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    
    // USDC in mainnet https://etherscan.io/address/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    
    // WETH in mainnet https://etherscan.io/address/0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // Pool address USDC/WETH mainnet https://etherscan.io/address/0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8
    IUniswapV3Pool pool = IUniswapV3Pool(0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8);

    

    function setUp() public {
        string memory RPC_URL = vm.envString("RPC_URL");
        uint256 BLOCK_NUMBER = 21065020;

        vm.createSelectFork(RPC_URL);
        vm.selectFork(MAINNET_FORK);
        vm.rollFork(BLOCK_NUMBER);

        liquidityManager = new UniswapV3LiquidityManager(address(positionManager), address(swapRouter));

        // Airdrop tokens to user
        deal(address(usdc), user, 1000 * 1e6);
        deal(address(weth), user, 1 * 1e18);

        // Approving user to send tokens in contract
        vm.prank(user);
        usdc.approve(address(liquidityManager), 1000 * 1e6);
        weth.approve(address(liquidityManager), 1 * 1e18);
        vm.stopPrank();
    }

    function testProvideLiquidity() public {
        // Устанавливаем параметры ликвидности
        UniswapV3LiquidityManager.LiquidityParams memory params = UniswapV3LiquidityManager.LiquidityParams({
            poolAddress: address(pool),
            amount0Desired: 1000 * 1e6,  // 1000 USDC
            amount1Desired: 1 * 1e18,    // 1 WETH
            width: 5000                  // Ширина позиции
        });

        // Вызываем функцию provideLiquidity от имени пользователя
        vm.prank(user);
        liquidityManager.provideLiquidity(params);

        // Проверяем, что ликвидность добавлена (например, с помощью события или баланса)
        // Можете добавить ваши утверждения здесь
    }

    function testCalculateLiquidity() public {
        // Устанавливаем параметры ликвидности
        UniswapV3LiquidityManager.LiquidityParams memory params = UniswapV3LiquidityManager.LiquidityParams({
            poolAddress: address(pool),
            amount0Desired: 1000 * 1e6,  // 1000 USDC
            amount1Desired: 1 * 1e18,    // 1 WETH
            width: 5000                  // Ширина позиции
        });

        // Вызываем функцию calculateLiquidity
        (uint256 liquidity, uint256 lowerTick, uint256 upperTick) = liquidityManager.calculateLiquidity(params);

        // Проверяем результаты
        console.log("Liquidity: ", liquidity);
        console.log("Lower tick: ", lowerTick);
        console.log("Upper tick: ", upperTick);

        // Вы можете добавить утверждения (assert) для проверки результатов
        assert(liquidity > 0);  // Проверяем, что рассчитанная ликвидность больше 0
    }
}
