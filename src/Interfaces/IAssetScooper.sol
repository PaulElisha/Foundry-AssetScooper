// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAssetScooper {
    function owner() external view returns (address);

    function version() external pure returns (string memory);

    function sweepTokens(
        address[] calldata tokenAddresses,
        uint256[] calldata minAmountOut
    ) external;
}
