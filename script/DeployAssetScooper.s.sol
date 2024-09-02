// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AssetScooper.sol";

contract DeployAssetScooper is Script {
    function deployAssetScooper() public returns (AssetScooper) {
        vm.startBroadcast();
        AssetScooper assetScooper = new AssetScooper();
        vm.stopBroadcast();

        return assetScooper;
    }

    function run() public returns (AssetScooper) {
        return deployAssetScooper();
    }
}
