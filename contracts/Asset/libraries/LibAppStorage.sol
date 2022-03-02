// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AssetAuctionBid {
    uint32 auctionId;
    uint256 timestamp;
    uint256 value;
    address bidder;
    bool meetReservePrice;
    bool autoRebid;
}

struct AssetAuction {
    uint256 openAuctionTimestamp;
    uint256 closeAuctionTimestamp;
    address owner;
    address bidder;
    uint256 startingPrice;
    uint256 reservePrice;
    uint256 value;
    uint256 maxBid;
    uint256 maxWeight;
    uint256 nextBidWeight;
    uint32 totalBid;
    bool meetReservePrice;
}

struct AssetOfferBid {
    uint256 value;
    address bidder;
    uint256 timestamp;
}

struct AssetInfo {
    address owner;
    address founder;
    address custodian;
    address auditor;
    string tokenURI;
    uint256 maxWeight;
    uint256 founderWeight;
    uint256 founderRedeemWeight;
    uint256 founderGeneralFee;
    uint256 auditFee;
    uint256 mintFee;
    uint256 custodianWeight;
    uint256 custodianGeneralFee;
    uint256 custodianRedeemWeight;
    bool isCustodianSign;
    bool isPayFeeAndClaimToken;
    bool isAuction;
    bool isBuyItNow;
    bool isOffer;
    bool isLockInCollection;
    bool isRedeem;
    bool isFreeze;
    uint256 buyItNowValue;
    address buyItNowOwner;
    uint256 offerValue;
    address offerOwner;
    address offerBidder;
    uint256 offerOpenOfferTimestamp;
    uint256 offerCloseOfferTimestamp;
    uint32 totalAuction;
    uint32 bidId;
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
    mapping(uint256 => mapping(uint32 => AssetAuction)) auctions;
    mapping(uint256 => mapping(uint32 => AssetAuctionBid)) bids;
    mapping(uint256 => mapping(uint32 => AssetOfferBid)) offerBids;
}
