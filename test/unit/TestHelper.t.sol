// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "permit2/interfaces/ISignatureTransfer.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../src/AssetScooper.sol";
import "sign-utils/SignUtils.sol";

abstract contract TestHelper is Test, SignUtils {
    function createSwapParams(
        IERC20 aero
    ) public pure returns (AssetScooper.SwapParams memory) {
        AssetScooper.SwapParams memory param = AssetScooper.SwapParams({
            tokenAddress: address(aero),
            minimumOutputAmount: 0
        });

        return param;
    }

    function createSignatureTransferData(
        IERC20 token,
        AssetScooper assetScooper,
        address user
    ) public view returns (AssetScooper.Permit2SignatureTransferData memory) {
        uint256 bal = token.balanceOf(user);

        console.log("Test Helper: User Token Balance", bal);
        console.log("Test Helper: User Token Address", address(token));

        ISignatureTransfer.TokenPermissions
            memory permittedTokens = ISignatureTransfer.TokenPermissions({
                token: address(token),
                amount: bal
            });

        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer
            .PermitTransferFrom({
                permitted: permittedTokens,
                nonce: 0,
                deadline: block.timestamp + 100
            });

        // permit.permitted[0] = permittedTokens;

        ISignatureTransfer.SignatureTransferDetails
            memory transferDetail = ISignatureTransfer
                .SignatureTransferDetails({
                    to: address(assetScooper),
                    requestedAmount: bal
                });

        // ISignatureTransfer.SignatureTransferDetails[]
        //     memory transferDetails = new ISignatureTransfer.SignatureTransferDetails[](
        //         1
        //     );

        // transferDetails[0] = transferDetail;

        AssetScooper.Permit2SignatureTransferData
            memory signatureTransferData = AssetScooper
                .Permit2SignatureTransferData({
                    permit: permit,
                    transferDetails: transferDetail
                });

        return signatureTransferData;
    }

    function constructSig(
        ISignatureTransfer.PermitTransferFrom memory permit,
        uint256 privKey
    ) public view returns (bytes memory sig) {
        bytes32 mhash = hashPermit(permit);

        bytes32 digest = hashTypedData(mhash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, digest);
        sig = getSig(v, r, s);
        // console.log("Test Helper: Sig", sig);
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
}
