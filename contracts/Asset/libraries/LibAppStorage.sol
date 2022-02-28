// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AssetInfo {
    address founder;
    address custodian;
    address auditor;
    string tokenURI;
    uint256 maxWeight;
    uint256 founderWeight;
    uint256 founderRedeemWeight;
    uint256 founderGeneralFee;
    uint256 auditFee;
    uint256 custodianWeight;
    uint256 custodianGeneralFee;
    uint256 custodianRedeemWeight;
    bool isCustodianSign;
    bool isPayFeeAndClaimToken;
}
    
struct AppStorage {
    address owner;
    string name;
    string symbol;
    uint256 totalAsset;
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;
    mapping(uint256 => AssetInfo) assets;
}
