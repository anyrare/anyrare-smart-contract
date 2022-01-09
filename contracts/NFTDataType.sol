pragma solidity ^0.8.0;

contract NFTDataType {
    struct NFTStatus {
        bool custodianSign;
        bool claim;
        bool lockInCollection;
        bool auction;
        bool buyItNow;
        bool offer;
        bool redeem;
        bool freeze;
    }

    struct NFTAddress {
        address auditor;
        address custodian;
        address founder;
        address owner;
    }

    struct NFTFee {
        uint256 maxWeight;
        uint256 founderWeight;
        uint256 founderGeneralFee;
        uint256 founderRedeemWeight;
        uint256 custodianWeight;
        uint256 custodianGeneralFee;
        uint256 custodianRedeemWeight;
        uint256 auditFee;
        uint256 mintFee;
    }

    struct NFTAuctionBid {
        uint32 auctionId;
        uint256 timestamp;
        uint256 value;
        address bidder;
        bool meetReservePrice;
        bool autoRebid;
    }

    struct NFTAuction {
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

    struct NFTBuyItNow {
        uint256 value;
        address owner;
    }

    struct NFTOffer {
        uint256 value;
        address owner;
        address bidder;
        uint256 openOfferTimestamp;
        uint256 closeOfferTimestamp;
    }

    struct NFTOfferBid {
        uint256 value;
        address bidder;
        uint256 timestamp;
    }

    struct NFTInfo {
        bool exists;
        uint256 tokenId;
        NFTStatus status;
        NFTAddress addr;
        NFTFee fee;
        NFTBuyItNow buyItNow;
        NFTOffer offer;
        uint32 totalAuction;
        uint32 offerId;
        uint32 bidId;
        uint256 redeemTimestamp;
        mapping(uint32 => NFTAuction) auctions;
        mapping(uint32 => NFTAuctionBid) bids;
        mapping(uint32 => NFTOfferBid) offerBids;
    }

    struct TransferARA {
        address receiver;
        uint256 amount;
    }
}
