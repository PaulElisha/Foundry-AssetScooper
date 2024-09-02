// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import necessary contracts from Uniswap
import "./Constants.sol";
import "./Interfaces/IUniswapV2Pair.sol";
import "./Lib/UniswapV2Library.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "forge-std/console.sol";

contract AssetScooper is ReentrancyGuard, Constants {
    using SafeERC20 for IERC20;

    address private immutable i_owner;

    string private constant i_version = "1.0.0";

    IERC20 private immutable weth;

    address private immutable factory;

    event TokenSwapped(
        address indexed user,
        address indexed tokenA,
        uint256 amountIn,
        uint256 indexed amountOut
    );

    error AssetScooper__ZeroLengthArray();
    error AssetScooper__InsufficientOutputAmount();
    error AssetScooper__InsufficientBalance();
    error AssetScooper__MisMatchLength();
    error AssetScooper__EmptyTokens();
    error AssetScooper__UnsuccessfulDecimalCall();
    error AssetScooper__UnsuccessfulBalanceCall();

    constructor() {
        i_owner = msg.sender;
        weth = IERC20(WETH);
        factory = FACTORY;
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
    ) internal view returns (uint256 tokenBalance) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSignature("balanceOf(address)", _owner)
        );
        if (!success && data.length <= 0)
            revert AssetScooper__UnsuccessfulBalanceCall();
        tokenBalance = abi.decode(data, (uint256));
        return tokenBalance;
    }

    function _getAmountIn(
        address token,
        uint256 tokenBalance
    ) internal view returns (uint256 amountIn) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSignature("decimals()")
        );
        if (!success && data.length <= 0)
            revert AssetScooper__UnsuccessfulDecimalCall();
        uint256 tokenDecimals = abi.decode(data, (uint256));
        amountIn = (tokenBalance * (10 ** (18 - tokenDecimals))) / 1;
        return amountIn;
    }

    function sweepTokens(
        address[] calldata tokenAddress,
        uint256[] calldata minAmountOut
    ) public nonReentrant {
        if (tokenAddress.length != minAmountOut.length) {
            revert AssetScooper__MisMatchLength();
        }

        uint256 totalEth;

        for (uint256 i = 0; i < tokenAddress.length; i++) {
            address pairAddress = UniswapV2Library.pairFor(
                factory,
                tokenAddress[i],
                address(weth)
            );
            totalEth += _swap(pairAddress, minAmountOut[i], address(this));
        }
        weth.safeTransfer(msg.sender, totalEth);
    }

    function _swap(
        address pairAddress,
        uint256 minimumOutputAmount,
        address _to
    ) private returns (uint256 amountOut) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        address tokenIn = pair.token0() == address(weth)
            ? pair.token1()
            : pair.token0();
        address tokenOut = pair.token0() == address(weth)
            ? pair.token0()
            : pair.token1();

        console.log(tokenIn);
        console.log(tokenOut);

        uint256 tokenBalance = _getTokenBalance(tokenIn, msg.sender);
        if (tokenBalance <= 0) revert AssetScooper__InsufficientBalance();

        uint256 amountIn = _getAmountIn(tokenIn, tokenBalance);
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(
            factory,
            tokenIn,
            tokenOut
        );

        // 210671548903176615967__40317 reserveA
        // 160367471134620977966 reserveB

        // 996952819354769469885 AmountOut

        console.log(reserveA);
        console.log(reserveB);
        amountOut = UniswapV2Library.getAmountOut(
            amountIn,
            tokenOut == pair.token0() ? reserveA : reserveB,
            tokenIn == pair.token0() ? reserveB : reserveA
        );
        console.log(amountOut);
        if (amountOut < minimumOutputAmount) {
            revert AssetScooper__InsufficientOutputAmount();
        }

        IERC20(tokenIn).safeTransferFrom(msg.sender, pairAddress, amountIn);

        (address token0, ) = UniswapV2Library.sortTokens(tokenIn, tokenOut);

        (uint256 amount0Out, uint256 amount1Out) = tokenIn == token0
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));

        console.log(amount0Out);

        address to = tokenIn == address(0) && tokenOut == address(0)
            ? pairAddress
            : _to;

        console.log(reserveA);
        console.log(reserveB);
        pair.swap(amount0Out, amount1Out, to, new bytes(0));

        emit TokenSwapped(msg.sender, tokenIn, amountIn, amountOut);
    }
}
