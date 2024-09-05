// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

contract AssetScooper is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address private immutable i_owner;

    string private constant i_version = "1.0.0";

    IWETH private immutable weth;
    IUniswapV2Router02 private immutable uniswapRouter;

    event TokenSwapped(
        address indexed user,
        address indexed tokenA,
        uint256 amountIn,
        uint256 indexed amountOut
    );

    error AssetScooper__ZeroLengthArray();
    error AssetScooper__InsufficientOutputAmount();
    error AssetScooper__InsufficientUserBalance();
    error AssetScooper__MisMatchLength();
    error AssetScooper__ZeroAddressToken();
    error AssetScooper__UnsuccessfulDecimalCall();
    error AssetScooper__UnsuccessfulBalanceCall();

    constructor(address _weth, address _uniswapRouter) {
        i_owner = msg.sender;
        weth = IWETH(_weth);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    function owner() public view returns (address) {
        return i_owner;
    }

    function version() public pure returns (string memory) {
        return i_version;
    }

    function _getTokenBalance(
        address token,
        address _owner
    ) private view returns (uint256 tokenBalance) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSignature("balanceOf(address)", _owner)
        );
        if (!success || data.length <= 0) {
            revert AssetScooper__UnsuccessfulBalanceCall();
        }
        tokenBalance = abi.decode(data, (uint256));
        return tokenBalance;
    }

    function _getAmountIn(
        address token,
        uint256 tokenBalance
    ) private view returns (uint256 amountIn) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSignature("decimals()")
        );
        if (!success || data.length <= 0) {
            revert AssetScooper__UnsuccessfulDecimalCall();
        }
        /*uint256 tokenDecimals*/ abi.decode(data, (uint256));

        amountIn = tokenBalance;

        return amountIn;
    }

    function normalizeAddress(address addr) private pure returns (address) {
        return address(uint160(addr));
    }

    function sweepTokens(
        address[] calldata tokenAddresses,
        uint256[] calldata minAmountOut
    ) public nonReentrant {
        if (tokenAddresses.length == uint256(0))
            revert AssetScooper__ZeroLengthArray();

        if (tokenAddresses.length != minAmountOut.length) {
            revert AssetScooper__MisMatchLength();
        }

        uint256 totalEth;

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            if (tokenAddresses[i] == address(0))
                revert AssetScooper__ZeroAddressToken();
            address swapToken = normalizeAddress(tokenAddresses[i]);
            totalEth += _swap(swapToken, minAmountOut[i]);
        }
        weth.transfer(msg.sender, totalEth);
    }

    function _swap(
        address tokenIn,
        uint256 minimumOutputAmount
    ) private returns (uint256 amountOut) {
        uint256 tokenBalance = _getTokenBalance(tokenIn, msg.sender);

        if (tokenBalance <= 0) revert AssetScooper__InsufficientUserBalance();

        uint256 amountIn = _getAmountIn(tokenIn, tokenBalance);

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(uniswapRouter), amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = address(weth);

        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amountIn,
            minimumOutputAmount,
            path,
            address(this),
            block.timestamp + 100
        );

        amountOut = amounts[1];

        if (amountOut < minimumOutputAmount) {
            revert AssetScooper__InsufficientOutputAmount();
        }

        emit TokenSwapped(msg.sender, tokenIn, amountIn, amountOut);
    }

    receive() external payable {}
}
