// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/AssetScooper.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../script/DeployAssetScooper.s.sol";
import "../../src/Constants.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

error AssetScooper__InsufficientUserBalance();
error AssetScooper__MisMatchLength();
error AssetScooper__ZeroLengthArray();
error AssetScooper__ZeroAddressToken();

contract AssetScooperTest is Test, Constants {
    AssetScooper private assetScooper;
    IERC20 private usdc;
    IERC20 private shib;
    address private USER = address(0xf584F8728B874a6a5c7A8d4d387C9aae9172D621);
    address private USER_2 = makeAddr("USER_2");
    IWETH private weth;

    uint256 internal mainnetFork;

    function setUp() public {
        DeployAssetScooper deployAssetScooper = new DeployAssetScooper();
        assetScooper = deployAssetScooper.run();

        usdc = IERC20(USDC);
        shib = IERC20(SHIB);

        string
            memory fork_url = "https://base-mainnet.g.alchemy.com/v2/0yadBjzhtsJKAysNRGkKbCwD7qpmRknG";
        mainnetFork = vm.createFork(fork_url);
        vm.selectFork(mainnetFork);
    }

    function testOwner() public view {
        assertEq(assetScooper.owner(), msg.sender);
    }

    function testVersion() public view {
        assertEq(assetScooper.version(), "1.0.0");
    }

    function testSweep() public {
        vm.startPrank(USER);

        uint256 usdcBalance = usdc.balanceOf(USER);
        uint256 shibBalance = shib.balanceOf(USER);
        console.log("USDC Balance:", usdcBalance);
        console.log("SHIB Balance:", shibBalance);

        usdc.approve(address(assetScooper), usdcBalance);
        shib.approve(address(assetScooper), shibBalance);
        console.log(
            "USDC Allowance:",
            usdc.allowance(USER, address(assetScooper))
        );
        console.log(
            "SHIB Allowance:",
            shib.allowance(USER, address(assetScooper))
        );

        address[] memory tokens = new address[](2);
        tokens[0] = address(usdc);
        tokens[1] = address(shib);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        assetScooper.sweepTokens(tokens, amounts);
        vm.stopPrank();
    }

    function testSweepRevertsWithInsufficientUserBalance() public {
        vm.startPrank(USER);

        uint256 usdcBalance = usdc.balanceOf(USER);
        uint256 shibBalance = shib.balanceOf(USER);
        console.log("USDC Balance:", usdcBalance);
        console.log("SHIB Balance:", shibBalance);

        usdc.transfer(USER_2, usdcBalance);
        shib.transfer(USER_2, shibBalance);

        usdc.approve(address(assetScooper), usdcBalance);
        shib.approve(address(assetScooper), shibBalance);
        console.log(
            "USDC Allowance:",
            usdc.allowance(USER, address(assetScooper))
        );
        console.log(
            "SHIB Allowance:",
            shib.allowance(USER, address(assetScooper))
        );

        address[] memory tokens = new address[](2);
        tokens[0] = address(usdc);
        tokens[1] = address(shib);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        vm.expectRevert(AssetScooper__InsufficientUserBalance.selector);
        assetScooper.sweepTokens(tokens, amounts);

        vm.stopPrank();
    }

    function testSweepRevertsWithMisMatchLength() public {
        vm.startPrank(USER);

        uint256 usdcBalance = usdc.balanceOf(USER);
        uint256 shibBalance = shib.balanceOf(USER);
        console.log("USDC Balance:", usdcBalance);
        console.log("SHIB Balance:", shibBalance);

        usdc.approve(address(assetScooper), usdcBalance);
        shib.approve(address(assetScooper), shibBalance);
        console.log(
            "USDC Allowance:",
            usdc.allowance(USER, address(assetScooper))
        );
        console.log(
            "SHIB Allowance:",
            shib.allowance(USER, address(assetScooper))
        );

        address[] memory tokens = new address[](2);
        tokens[0] = address(usdc);
        tokens[1] = address(shib);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        vm.expectRevert(AssetScooper__MisMatchLength.selector);
        assetScooper.sweepTokens(tokens, amounts);

        vm.stopPrank();
    }

    function testSweepRevertsWithZeroLengthArray() public {
        vm.startPrank(USER);

        address[] memory tokens;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        vm.expectRevert(AssetScooper__ZeroLengthArray.selector);
        assetScooper.sweepTokens(tokens, amounts);

        vm.stopPrank();
    }

    function testSweepRevertsAddressZeroToken() public {
        vm.startPrank(USER);

        address[] memory tokens = new address[](2);
        tokens[0] = address(0);
        tokens[1] = address(0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        vm.expectRevert(AssetScooper__ZeroAddressToken.selector);
        assetScooper.sweepTokens(tokens, amounts);

        vm.stopPrank();
    }
}
