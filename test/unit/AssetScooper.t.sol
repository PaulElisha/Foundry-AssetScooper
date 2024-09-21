// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/AssetScooper.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../script/DeployAssetScooper.s.sol";
import "../../src/Constants.sol";
import "./TestHelper.t.sol";
import "../mocks/MockERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "permit2/Permit2.sol";

error AssetScooper__InsufficientUserBalance();
error AssetScooper__MisMatchLength();
error AssetScooper__ZeroLengthArray();
error AssetScooper__ZeroAddressToken();

contract AssetScooperTest is Test, Constants, TestHelper {
    AssetScooper private assetScooper;
    // Permit2 permit2;

    // MockERC20 mockErc20;

    IERC20 private aero;
    IERC20 private wgc;

    address userA;
    address userB;

    uint256 privateKey;
    bytes sig;

    uint256 internal mainnetFork;

    AssetScooper.SwapParams[] params;
    AssetScooper.Permit2SignatureTransferDetails _signatureTransferData;

    function setUp() public {
        DeployAssetScooper deployAssetScooper = new DeployAssetScooper();
        assetScooper = deployAssetScooper.run();

        // assetScooper = new AssetScooper(
        //     IWETH(WETH),
        //     IUniswapV2Router02(ROUTER_ADDRESS),
        //     Permit2(PERMIT2)
        // );

        privateKey = vm.envUint("PRIVATE_KEY");
        userA = vm.addr(privateKey);

        // userA = 0xCafc0Cd0eC8DD6F69C68AdBDEc9F2B7EAFeE931f;

        // userA = address(PRANK_USER);
        console.log("UserA address", userA);
        console.log("Asset Scooper", address(assetScooper));
        console.log("UserA privateKey", privateKey);

        // (privateKey) = mkpk("userA");

        // mockErc20 = new MockERC20();
        // mockErc20.mint(userA, 1000 * 10 ** 18);
        // console.log(mockErc20.balanceOf(userA));
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
        _signatureTransferData = createSignatureTransferData(
            aero,
            assetScooper,
            userA
        );

        sig = constructSig(_signatureTransferData, privateKey);

        AssetScooper.SwapParams memory param = createSwapParams(address(aero));

        params[0] = param;

        vm.startPrank(userA);

        assetScooper.sweepTokens(params, _signatureTransferData, sig);

        vm.stopPrank();
    }
}
