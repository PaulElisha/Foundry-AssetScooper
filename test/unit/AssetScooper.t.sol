// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/AssetScooper.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../script/DeployAssetScooper.s.sol";
import "../../src/Constants.sol";

error AssetScooper__InsufficientUserBalance();
error AssetScooper__MisMatchLength();
error AssetScooper__ZeroLengthArray();
error AssetScooper__ZeroAddressToken();

contract AssetScooperTest is Test, Constants {
    AssetScooper private assetScooper;
    IERC20 private aero;
    IERC20 private wgc;
    address private USER = address(0xe6A7d4082a79bb196597ea42F75ddD85e41F599C);
    address private USER_2 = makeAddr("USER_2");

    uint256 internal mainnetFork;

    function setUp() public {
        DeployAssetScooper deployAssetScooper = new DeployAssetScooper();
        assetScooper = deployAssetScooper.run();

        aero = IERC20(AERO);
        wgc = IERC20(WGC);

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

        uint256 aeroBalanceBefore = aero.balanceOf(USER);
        uint256 wgcBalanceBefore = wgc.balanceOf(USER);
        console.log("AERO Balance Before:", aeroBalanceBefore);
        console.log("WGC Balance Before:", wgcBalanceBefore);

        aero.approve(address(assetScooper), aeroBalanceBefore);
        wgc.approve(address(assetScooper), wgcBalanceBefore);
        console.log(
            "AERO Allowance:",
            aero.allowance(USER, address(assetScooper))
        );
        console.log(
            "WGC Allowance:",
            wgc.allowance(USER, address(assetScooper))
        );

        address[] memory tokens = new address[](2);
        tokens[0] = address(aero);
        tokens[1] = address(wgc);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        assetScooper.sweepTokens(tokens, amounts);

        uint256 aeroBalanceAfter = aero.balanceOf(USER);
        uint256 wgcBalanceAfter = wgc.balanceOf(USER);
        console.log("AERO Balance After:", aeroBalanceAfter);
        console.log("WGC Balance After:", wgcBalanceAfter);

        uint256 bal = address(USER).balance;
        console.log("User's Weth Balance:", bal);

        assertGt(aeroBalanceBefore, aeroBalanceAfter);
        assertGt(wgcBalanceBefore, wgcBalanceAfter);
        assertGt(bal, 0);
        vm.stopPrank();
    }

    function testSweepRevertsWithInsufficientUserBalance() public {
        vm.startPrank(USER);

        uint256 aeroBalance = aero.balanceOf(USER);
        uint256 wgcBalance = wgc.balanceOf(USER);
        console.log("AERO Balance:", aeroBalance);
        console.log("WGC Balance:", wgcBalance);

        aero.transfer(USER_2, aeroBalance);
        wgc.transfer(USER_2, wgcBalance);

        uint256 aeroBalanceAfter = aero.balanceOf(USER);
        uint256 wgcBalanceAfter = wgc.balanceOf(USER);
        console.log("AERO Balance After:", aeroBalanceAfter);
        console.log("WGC Balance After:", wgcBalanceAfter);

        aero.approve(address(assetScooper), aeroBalance);
        wgc.approve(address(assetScooper), wgcBalance);
        console.log(
            "AERO Allowance:",
            aero.allowance(USER, address(assetScooper))
        );
        console.log(
            "WGC Allowance:",
            wgc.allowance(USER, address(assetScooper))
        );

        address[] memory tokens = new address[](2);
        tokens[0] = address(aero);
        tokens[1] = address(wgc);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        assertLt(aeroBalanceAfter, aeroBalance);
        assertLt(wgcBalanceAfter, wgcBalance);

        vm.expectRevert(AssetScooper__InsufficientUserBalance.selector);
        assetScooper.sweepTokens(tokens, amounts);
        vm.stopPrank();
    }

    function testSweepRevertsWithMisMatchLength() public {
        vm.startPrank(USER);

        uint256 aeroBalance = aero.balanceOf(USER);
        uint256 wgcBalance = wgc.balanceOf(USER);
        console.log("AERO Balance:", aeroBalance);
        console.log("WFC Balance:", wgcBalance);

        aero.approve(address(assetScooper), aeroBalance);
        wgc.approve(address(assetScooper), wgcBalance);
        console.log(
            "AERO Allowance:",
            aero.allowance(USER, address(assetScooper))
        );
        console.log(
            "wgc Allowance:",
            wgc.allowance(USER, address(assetScooper))
        );

        address[] memory tokens = new address[](2);
        tokens[0] = address(aero);
        tokens[1] = address(wgc);

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

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        vm.expectRevert(AssetScooper__ZeroAddressToken.selector);
        assetScooper.sweepTokens(tokens, amounts);

        vm.stopPrank();
    }
}
