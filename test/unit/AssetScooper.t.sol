// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/AssetScooper.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../script/DeployAssetScooper.s.sol";
import "../../src/Constants.sol";

contract AssetScooperTest is Test, Constants {
    AssetScooper public assetScooper;
    IERC20 public dai;
    IERC20 public bento;
    address public USER = makeAddr("user");

    function setUp() public {
        DeployAssetScooper deployAssetScooper = new DeployAssetScooper();
        assetScooper = deployAssetScooper.run();

        dai = IERC20(DAI);
        bento = IERC20(BENTO);
    }

    function testOwner() public view {
        assertEq(assetScooper.owner(), msg.sender);
    }

    function testVersion() public view {
        assertEq(assetScooper.version(), "1.0.0");
    }

    function testSweep() public {
        deal(address(dai), USER, STARTING_BALANCE, true);
        deal(address(bento), USER, STARTING_BALANCE, true);

        vm.startPrank(USER);
        dai.approve(address(assetScooper), SEND_VALUE);
        bento.approve(address(assetScooper), SEND_VALUE);

        address[] memory tokens = new address[](2);
        tokens[0] = address(dai);
        tokens[1] = address(bento);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        assetScooper.sweepTokens(tokens, amounts);
        vm.stopPrank();
    }
}
