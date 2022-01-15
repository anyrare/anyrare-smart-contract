pragma solidity ^0.8.0;

contract CollectionDataType {
    struct CollectionShareholder {
        bool exists;
        address addr;
    }

    struct CollectionTargetPrice {
        uint256 price;
        uint256 totalSum;
        uint256 totalVoteToken;
        uint32 totalVoter;
        uint32 totalVoterIndex;
    }

    struct CollectionTargetPriceVoteInfo {
        uint256 price;
        uint256 voteToken;
        bool vote;
        bool exists;
    }

    struct CollectionAuctionBid {
        uint256 timestamp;
        uint256 value;
        address bidder;
        bool autoRebid;
    }

    struct CollectionAuction {
        uint256 openAuctionTimestamp;
        uint256 closeAuctionTimestamp;
        address bidder;
        uint256 startingPrice;
        uint256 value;
        uint256 maxBid;
        uint256 maxWeight;
        uint256 nextBidWeight;
        uint32 totalBid;
    }

    struct CollectionInfo {
        address collector;
        uint256 maxWeight;
        uint256 collateralWeight;
        uint256 collectorFeeWeight;
        uint256 dummyCollateralValue;
        uint32 totalNft;
        uint32 totalShareholder;
        bool exists;
        bool auction;
        bool freeze;
        string tokenURI;
    }

    struct TransferARA {
        address receiver;
        uint256 amount;
    }

    struct CollectionPurchaseFee {
        uint256 _collectorFee;
        uint256 collectorFee;
        uint256 platformCollectorFee;
        uint256 referralCollectorFee;
        uint256 platformFee;
        uint256 referralInvestorFee;
    }

    struct CollectionSaleFee {
        uint256 _collectorFee;
        uint256 collectorFee;
        uint256 platformCollectorFee;
        uint256 referralCollectorFee;
        uint256 platformFee;
        uint256 referralInvestorFee;
    }
}
