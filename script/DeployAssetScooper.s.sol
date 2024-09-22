// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/AssetScooper.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "permit2/interfaces/ISignatureTransfer.sol";
import "permit2/interfaces/IPermit2.sol";
import "../src/Constants.sol";

contract DeployAssetScooper is Script, Constants {
    function deployAssetScooper() public returns (AssetScooper) {
        vm.startBroadcast();
        AssetScooper assetScooper = new AssetScooper(
            IWETH(WETH),
            IUniswapV2Router02(ROUTER_ADDRESS),
            ISignatureTransfer(PERMIT2)
        );
        vm.stopBroadcast();

        return assetScooper;
    }

    function run() public returns (AssetScooper) {
        return deployAssetScooper();
    }
}
