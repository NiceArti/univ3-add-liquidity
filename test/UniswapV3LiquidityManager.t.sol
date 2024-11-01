// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UniswapV3LiquidityManager} from "../src/UniswapV3LiquidityManager.sol";
import {INonfungiblePositionManager} from "../src/univ3-lib/INonfungiblePositionManager.sol";
import {IUniswapV3Factory} from "../src/univ3-lib/IUniswapV3Factory.sol";

contract UniswapV3LiquidityManagerTest is Test {
    UniswapV3LiquidityManager liquidityManager;

    address immutable user = makeAddr("user");
    address constant LP_OWNER = 0x1920C59D9dB5A261716ca91fB5910C12DA6716d2;

    // NFT of this LP can be found here https://opensea.io/assets/ethereum/0xc36442b4a4522e871399cd717abdd847ab11fe88/461870
    address constant USDC_WETH_LP = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;

    // USDC in mainnet https://etherscan.io/address/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    
    // WETH in mainnet https://etherscan.io/address/0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // Factory address USDC/WETH mainnet https://etherscan.io/address/0x1F98431c8aD98523631AE4a59f267346ea31F984
    IUniswapV3Factory factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    // Position manager https://etherscan.io/address/0xC36442b4a4522E871399CD717aBDD847Ab11FE88
    INonfungiblePositionManager positionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88); // Адрес PositionManager на mainnet
    


    function setUp() public {
        string memory RPC_URL = vm.envString("RPC_URL");
        uint256 BLOCK_NUMBER = 20675491;

        vm.createSelectFork(RPC_URL);
        vm.rollFork(BLOCK_NUMBER);

        liquidityManager = new UniswapV3LiquidityManager(address(positionManager), address(factory));

        // Airdrop tokens to
        deal(LP_OWNER, 10 * 1e18);
        deal(address(usdc), LP_OWNER, 100000000000000000 * 1e6);
        deal(address(weth), LP_OWNER, 1000000 * 1e18);


        deal(user, 10 * 1e18);
        deal(address(usdc), user, 100000000000000000 * 1e6);
        deal(address(weth), user, 1000000 * 1e18);

        vm.startPrank(LP_OWNER);
        usdc.approve(address(liquidityManager), type(uint256).max);
        weth.approve(address(liquidityManager), type(uint256).max);
        vm.stopPrank();


        vm.startPrank(user);
        usdc.approve(address(liquidityManager), type(uint256).max);
        weth.approve(address(liquidityManager), type(uint256).max);
        vm.stopPrank();
    }

    function testProvideLiquidity() external {
        UniswapV3LiquidityManager.AddLiquidityParams memory params = UniswapV3LiquidityManager.AddLiquidityParams({
            lp: USDC_WETH_LP,
            tokenId: 461870,
            amount0Desired: 10000000 * 1e6,
            amount1Desired: 120000 * 1e18,
            width: 364
        });

        uint128 liquidity;
        vm.startPrank(LP_OWNER);
        liquidity = liquidityManager.addLiquidityWithFixedWidth(params);
        vm.stopPrank();

        vm.startPrank(LP_OWNER);
        liquidity = liquidityManager.addLiquidityWithFixedWidth(params);
        vm.stopPrank();


        vm.startPrank(user);
        liquidity = liquidityManager.addLiquidityWithFixedWidth(params);
        vm.stopPrank();


        assertNotEq(liquidity, 0);
    }

    function testLpAddressNotEqual() external {
        UniswapV3LiquidityManager.AddLiquidityParams memory params = UniswapV3LiquidityManager.AddLiquidityParams({
            lp: address(0),
            tokenId: 461870,
            amount0Desired: 10000000 * 1e6,
            amount1Desired: 120000 * 1e18,
            width: 364
        });

       
        vm.startPrank(LP_OWNER);
        vm.expectRevert("LP address not equal");
        liquidityManager.addLiquidityWithFixedWidth(params);
        vm.stopPrank();
    }


    function testWidthIsNotEqual() external {
        UniswapV3LiquidityManager.AddLiquidityParams memory params = UniswapV3LiquidityManager.AddLiquidityParams({
            lp: USDC_WETH_LP,
            tokenId: 461870,
            amount0Desired: 10000000 * 1e6,
            amount1Desired: 120000 * 1e18,
            width: 5000
        });

       
        vm.startPrank(LP_OWNER);
        vm.expectRevert("Position width does not match expected width");
        liquidityManager.addLiquidityWithFixedWidth(params);
        vm.stopPrank();
    }
}
