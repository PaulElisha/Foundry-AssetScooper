// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "permit2/interfaces/ISignatureTransfer.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../src/AssetScooper.sol";
import "sign-utils/SignUtils.sol";

abstract contract TestHelper is Test, SignUtils {
    struct SwapParams {
        address tokenAddress;
        uint256 minimumOutputAmount;
    }

    function createSwapParams(
        address _aero
    ) public pure returns (AssetScooper.SwapParams memory) {
        AssetScooper.SwapParams memory param = AssetScooper.SwapParams({
            tokenAddress: _aero,
            minimumOutputAmount: 0
        });

        return param;
    }

    function createSignatureTransferData(
        IERC20 token,
        AssetScooper assetScooper,
        address user
    )
        public
        view
        returns (AssetScooper.Permit2SignatureTransferDetails memory)
    {
        uint256 bal = token.balanceOf(user);

        ISignatureTransfer.TokenPermissions
            memory permittedTokens = ISignatureTransfer.TokenPermissions({
                token: address(token),
                amount: bal
            });

        ISignatureTransfer.PermitBatchTransferFrom
            memory permit = ISignatureTransfer.PermitBatchTransferFrom({
                permitted: new ISignatureTransfer.TokenPermissions[](1),
                nonce: 0,
                deadline: block.timestamp + 100
            });

        permit.permitted[0] = permittedTokens;

        ISignatureTransfer.SignatureTransferDetails
            memory transferDetail = ISignatureTransfer
                .SignatureTransferDetails({
                    to: address(assetScooper),
                    requestedAmount: bal
                });

        ISignatureTransfer.SignatureTransferDetails[]
            memory transferDetails = new ISignatureTransfer.SignatureTransferDetails[](
                1
            );

        transferDetails[0] = transferDetail;

        AssetScooper.Permit2SignatureTransferDetails
            memory signatureTransferData = AssetScooper
                .Permit2SignatureTransferDetails({
                    permit: permit,
                    transferDetails: transferDetails
                });

        return signatureTransferData;
    }

    function mkaddr(
        string memory name
    ) public returns (address addr, uint256 privateKey) {
        privateKey = uint256(keccak256(abi.encodePacked(name)));
        // address addr = address(uint160(uint256(keccak256(abi.encodePacked(name)))))
        addr = vm.addr(privateKey);
        vm.label(addr, name);
    }

    function mkpk(string memory name) public pure returns (uint256 privateKey) {
        privateKey = uint256(keccak256(abi.encodePacked(name)));
        // address addr = address(uint160(uint256(keccak256(abi.encodePacked(name)))))
    }

    function getSigPacked(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(r, s, v);
    }
}
