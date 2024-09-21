// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

abstract contract Constants {
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant FACTORY =
        0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6;
    address public constant ROUTER_ADDRESS =
        0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address public constant PERMIT2 =
        0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address public constant AERO = 0x3C281A39944a2319aA653D81Cfd93Ca10983D234;
    address public constant WGC = 0xAfb89a09D82FBDE58f18Ac6437B3fC81724e4dF6;

    address public constant PRANK_USER =
        0xCafc0Cd0eC8DD6F69C68AdBDEc9F2B7EAFeE931f;

    uint256 public constant PRIVATE_KEY =
        0xe95e23bb89eadd0e4d715cca0540499d37c93ea745e307f985d00f72687bdffe;

    string public constant FORK_URL =
        "https://base-mainnet.g.alchemy.com/v2/0yadBjzhtsJKAysNRGkKbCwD7qpmRknG";
}
