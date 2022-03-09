// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Transaction {
    bool isSettle;
    bool senderType;
    string transactionId;
    address wallet;
    uint256 amount;
}

struct Collateral {
    uint16 chainId;
    address contractAddress;
    uint256 totalValue;
    uint256 totalTransaction;
    // mapping(address => Transaction) transactionsByAddress;
    mapping(string => Transaction) transactions;
    mapping(address => uint256) balances;
}

struct AppStorage {
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => uint256) balances;
    address[] approvedContracts;
    mapping(address => uint256) approvedContractIndexes;
    bytes32[1000] emptyMapSlots;
    address contractOwner;
    uint256 totalSupply;
    uint256 totalCollateralValue;
    uint256 managementFundValue;
    address anyrare;
    address owner;
    mapping(uint16 => Collateral) collaterals;
}
