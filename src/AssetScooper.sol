// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces/IAssetScooper.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "permit2/interfaces/ISignatureTransfer.sol";
import "permit2/interfaces/IPermit2.sol";
import "permit2/Permit2.sol";
import "forge-std/console2.sol";

contract AssetScooper is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address private immutable i_owner;
    string private constant i_version = "1.0.0";

    IWETH private immutable weth;
    IUniswapV2Router02 private immutable uniswapRouter;
    ISignatureTransfer public immutable permit2;

    struct SwapParams {
        address tokenAddress;
        uint256 minimumOutputAmount;
    }

    struct Permit2SignatureTransferData {
        ISignatureTransfer.PermitTransferFrom permit;
        ISignatureTransfer.SignatureTransferDetails transferDetails;
    }

    event TokenSwapped(
        address indexed user,
        address indexed tokenA,
        uint256 amountIn,
        uint256 indexed amountOut
    );

    error AssetScooper__ZeroLengthArray();
    error AssetScooper__InsufficientOutputAmount();
    error AssetScooper__InsufficientUserBalance(uint256);
    error AssetScooper__MisMatchLength();
    error AssetScooper__ZeroAddressToken();
    error AssetScooper__UnsuccessfulBalanceCall();
    error AssetScooper__InvalidAddress();
    error AssetScooper__InvalidTokenAddress();
    error AssetScooper__InvalidTransferDetails();

    constructor(
        IWETH _weth,
        IUniswapV2Router02 _uniswapRouter,
        ISignatureTransfer _permit2
    ) {
        i_owner = msg.sender;
        weth = _weth;
        uniswapRouter = _uniswapRouter;
        permit2 = _permit2;
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

    function sweepTokens(
        SwapParams calldata params,
        ISignatureTransfer.PermitTransferFrom calldata permit,
        ISignatureTransfer.SignatureTransferDetails calldata transferDetails,
        bytes memory sig
    ) public {
        // // Validate lengths of input parameters
        // if (
        //     // params.length != _signatureTransferData.permit.permitted.length ||
        //     _signatureTransferData.permit.permitted.length !=
        //     _signatureTransferData.transferDetails.length
        // ) revert AssetScooper__MisMatchLength();

        // if (
        //     // params.length == 0 ||
        //     _signatureTransferData.permit.permitted.length == 0 ||
        //     _signatureTransferData.transferDetails.length == 0
        // ) revert AssetScooper__ZeroLengthArray();

        // console2.log("Asset Scooper: Signature", signature);
        // console2.log(
        //     "Asset Scooper: Permit Struct",
        //     _signatureTransferData.permit
        // );

        uint256 totalAmountOut; // Track total output amount
        IERC20 erc20;

        // Make sure the payer has enough of the payment token
        erc20 = IERC20(params.tokenAddress);
        uint256 minimumAmountOut = params.minimumOutputAmount;
        uint256 tokenBalance = _getTokenBalance(address(erc20), msg.sender);

        console2.log("Asset Scooper: User balance", tokenBalance);

        if (tokenBalance <= 0) {
            revert AssetScooper__InsufficientUserBalance(tokenBalance);
        }
        // Transfer tokens to this contract using Permit2's method
        permit2.permitTransferFrom(
            permit,
            transferDetails,
            msg.sender,
            sig // Ensure this is the correct signature for the current transfer detail
        );

        console2.log("Asset Scooper: Sender Address", msg.sender);

        // Approve Uniswap router to spend the tokens
        erc20.approve(address(uniswapRouter), tokenBalance);

        // Set up path for swapping tokens: ERC20 -> WETH
        address[] memory path = new address[](2);
        path[0] = address(erc20);
        path[1] = address(weth);

        // Execute the swap on Uniswap
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            tokenBalance,
            minimumAmountOut,
            path,
            address(this),
            block.timestamp + 100 // Allowing a small time window for the swap to complete
        );

        totalAmountOut += amounts[1]; // Accumulate total output amount

        // Check if the output amount meets the minimum requirement
        if (totalAmountOut < minimumAmountOut) {
            revert AssetScooper__InsufficientOutputAmount();
        }

        emit TokenSwapped(msg.sender, address(erc20), tokenBalance, amounts[1]);

        // for (uint256 i = 0; i < params.length; i++) {
        //     if (params[i].tokenAddress == address(0)) {
        //         revert AssetScooper__ZeroAddressToken();
        //     }

        //     // Validate token permissions
        //     if (
        //         _signatureTransferData.permit.permitted[i].token !=
        //         params[i].tokenAddress
        //     ) {
        //         revert AssetScooper__InvalidTokenAddress();
        //     }

        //     // Ensure transfer details are directed to this contract
        //     if (_signatureTransferData.transferDetails[i].to != address(this)) {
        //         revert AssetScooper__InvalidTransferDetails();
        //     }
        // }

        // Transfer the accumulated WETH to the user after all swaps are done
        weth.transfer(msg.sender, totalAmountOut);
    }

    receive() external payable {}
}
