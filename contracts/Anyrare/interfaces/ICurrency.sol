// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurrency {
    struct TransferCurrency {
        address receiver;
        uint256 amount;
    }
}
