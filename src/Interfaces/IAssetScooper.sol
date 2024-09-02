// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAssetScooper {
    event TokenSwapped(
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountIn,
        uint amountOut
    );

    function owner() external view returns (address);

    function version() external pure returns (string memory);

    function sweepTokens(
        address[] calldata tokenAddress,
        uint256 minAmountOut
    ) external;
}
