// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

abstract contract Constants {
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant FACTORY =
        0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6;

    address public constant DAI = 0xBC45647eA894030a4E9801Ec03479739FA2485F0;
    address public constant BENTO = 0x9DE16c805A3227b9b92e39a446F9d56cf59fe640;

    uint256 public constant STARTING_BALANCE = 1000 * 10 ** 18;
    uint256 public constant SEND_VALUE = 1000 * 10 ** 18;
}
