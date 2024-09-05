// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AssetScooper.sol";
import "../src/Constants.sol";

contract DeployAssetScooper is Script, Constants {
    function deployAssetScooper() public returns (AssetScooper) {
        vm.startBroadcast();
        AssetScooper assetScooper = new AssetScooper(WETH, ROUTER_ADDRESS);
        vm.stopBroadcast();

        return assetScooper;
    }

    function run() public returns (AssetScooper) {
        return deployAssetScooper();
    }
}
