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
import "permit2/Permit2.sol";
import {console2} from "forge-std/console2.sol";

contract AssetScooper is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address private immutable i_owner;

    string private constant i_version = "1.0.0";

    IWETH private immutable weth;
    IUniswapV2Router02 private immutable uniswapRouter;
    Permit2 public immutable permit2;

    struct SwapParams {
        address tokenAddress;
        uint256 minimumOutputAmount;
    }

    struct Permit2SignatureTransferDetails {
        ISignatureTransfer.PermitBatchTransferFrom permit;
        ISignatureTransfer.SignatureTransferDetails[] transferDetails;
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
        Permit2 _permit2
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
        SwapParams[] calldata params,
        Permit2SignatureTransferDetails calldata _signatureTransferData,
        bytes calldata signature
    ) public nonReentrant {
        if (
            params.length != _signatureTransferData.permit.permitted.length ||
            _signatureTransferData.permit.permitted.length !=
            _signatureTransferData.transferDetails.length
        ) revert AssetScooper__MisMatchLength();

        if (
            params.length == 0 ||
            _signatureTransferData.permit.permitted.length == 0 ||
            _signatureTransferData.transferDetails.length == 0
        ) revert AssetScooper__ZeroLengthArray();

        uint256 amountOut;
        IERC20 erc20;
        uint256 tokenBalance;

        for (uint256 i = 0; i < params.length; i++) {
            if (params[i].tokenAddress == address(0)) {
                revert AssetScooper__ZeroAddressToken();
            }

            if (
                _signatureTransferData.permit.permitted[i].token !=
                params[i].tokenAddress
            ) {
                revert AssetScooper__InvalidTokenAddress();
            }

            if (_signatureTransferData.transferDetails[i].to != address(this)) {
                revert AssetScooper__InvalidTransferDetails();
            }

            console2.log("Before.......................");
            // Make sure the payer has enough of the payment token
            erc20 = IERC20(params[i].tokenAddress);
            uint256 minimumAmountOut = params[i].minimumOutputAmount;
            tokenBalance = _getTokenBalance(address(erc20), msg.sender);
            if (tokenBalance <= 0) {
                revert AssetScooper__InsufficientUserBalance(tokenBalance);
            }
            console2.log("After balance check...............");

            // Transfer token to this contract
            permit2.permitTransferFrom(
                _signatureTransferData.permit,
                _signatureTransferData.transferDetails,
                msg.sender,
                signature
            );
            console2.log("Sender Address", msg.sender);
            console2.log("App......................");
            erc20.approve(address(uniswapRouter), tokenBalance);

            address[] memory path = new address[](2);
            path[0] = address(erc20);
            path[1] = address(weth);

            uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
                tokenBalance,
                minimumAmountOut,
                path,
                address(this),
                block.timestamp + 100
            );

            amountOut += amounts[1];

            if (amountOut < minimumAmountOut) {
                revert AssetScooper__InsufficientOutputAmount();
            }
        }
        emit TokenSwapped(msg.sender, address(erc20), tokenBalance, amountOut);

        weth.transfer(msg.sender, amountOut);
    }

    receive() external payable {}
}
