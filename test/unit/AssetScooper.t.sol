// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/AssetScooper.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../script/DeployAssetScooper.s.sol";
import "../../src/Constants.sol";
import "./TestHelper.t.sol";
import "../mocks/MockERC20.sol";
import "forge-std/console2.sol";
import "permit2/interfaces/ISignatureTransfer.sol";

error AssetScooper__InsufficientUserBalance();
error AssetScooper__MisMatchLength();
error AssetScooper__ZeroLengthArray();
error AssetScooper__ZeroAddressToken();

contract AssetScooperTest is Test, Constants, TestHelper {
    AssetScooper private assetScooper;
    Permit2 permit2;

    IERC20 private aero;
    IERC20 private wgc;

    address userA;
    address userB;

    uint256 privateKey;
    bytes sig;

    uint256 internal mainnetFork;

    AssetScooper.SwapParams params;
    ISignatureTransfer.PermitTransferFrom permit;
    ISignatureTransfer.SignatureTransferDetails transferDetail;

    function setUp() public {
        DeployAssetScooper deployAssetScooper = new DeployAssetScooper();
        (assetScooper) = deployAssetScooper.run();

        privateKey = vm.envUint("PRIVATE_KEY");
        userA = vm.addr(privateKey);
        console2.log(userA);

        aero = IERC20(AERO);
        wgc = IERC20(WGC);

        mainnetFork = vm.createFork(FORK_URL);
        vm.selectFork(mainnetFork);
    }

    function testOwner() public view {
        assertEq(assetScooper.owner(), msg.sender);
    }

    function testVersion() public view {
        assertEq(assetScooper.version(), "1.0.0");
    }

    function testSweep() public {
        vm.startPrank(userA);
        (permit, transferDetail) = createSignatureTransferData(
            aero,
            assetScooper,
            userA
        );

        sig = constructSig(permit, userA, privateKey);

        AssetScooper.SwapParams memory param = createSwapParams(aero);

        params = param;

        assetScooper.sweepTokens(params, permit, transferDetail, sig);

        vm.stopPrank();
    }
}
