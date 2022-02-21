pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";

struct MemberInfo {
    address memberAddress;
    address referral;
    uint8 accountType;
    string username;
    string thumbnail;
    uint8 multiSigTotalAddress;
    uint8 multiSigTotalApprove;
    uint32 totalAsset;
    uint256 totalBidAuction;
    uint256 totalWonAuction;
    uint32 totalFounderCollection;
    uint32 totalOwnCollection;
    mapping(uint8 => address) multiSigAddresses;
    mapping(uint32 => uint256) assets;
}

struct Member {
    uint256 totalMember;
    mapping(address => MemberInfo) members;
    mapping(bytes32 => address) usernames;
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

struct AssetAuctionBid {
    uint32 auctionId;
    uint256 timestamp;
    uint256 value;
    address bidder;
    bool meetReservePrice;
    bool autoRebid;
}

struct AssetOfferBid {
    uint256 value;
    address owner;
    address bidder;
    uint256 openOfferTimestamp;
    uint256 closeOfferTimestamp;
}

struct AssetInfo {
    uint256 tokenId;
    bool isExists;
    bool isCustodianSign;
    bool isClaim;
    bool isLockInCollection;
    bool isAuction;
    bool isBuyItNow;
    bool isOffer;
    bool isRedeem;
    bool isFreeze;
    address auditorAddress;
    address custodianAddress;
    address founderAddress;
    address ownerAddress;
    uint256 maxWeight;
    uint256 founderWeight;
    uint256 founderGeneralFee;
    uint256 founderRedeemWeight;
    uint256 custodianWeight;
    uint256 custodianGeneralFee;
    uint256 custodianRedeemWeight;
    uint256 auditFee;
    uint256 mintFee;
    uint32 totalAuction;
    uint32 offerId;
    uint32 bidId;
    uint256 mintTimestamp;
    uint256 redeemTimestamp;
    string tokenURI;
    uint256 offerValue;
    address offerBidder;
    uint256 offerTimestamp;
    uint256 buyItNowValue;
    mapping(uint32 => AssetAuction) auctions;
    mapping(uint32 => AssetAuctionBid) auctionBids;
    mapping(uint32 => AssetOfferBid) offerBids;
}

struct Asset {
    uint256 totalAsset;
    mapping(uint256 => AssetInfo) assets;
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

struct CollectionInfo {
    address tokenId;
    address collectorAddress;
    uint256 maxWeight;
    uint256 collateralWeight;
    uint256 collectorFeeWeight;
    uint256 initialValue;
    uint256 dummyCollateralValue;
    uint32 totalAsset;
    uint256 totalShareholder;
    bool isExists;
    bool isAuction;
    bool isFreeze;
    string tokenURI;
    uint256 mintTimestamp;
    uint256 freezeTimestamp;
    uint256 targetPrice;
    uint256 targetPriceTotalSum;
    uint256 targetPriceTotalVoteToken;
    uint32 targetPriceTotalVoter;
    uint32 targetPriceTotalVoterIndex;
    uint256 auctionOpenAuctionTimestamp;
    uint256 auctionCloseAuctionTimestamp;
    address auctionBidder;
    uint256 auctionStartingPrice;
    uint256 auctionValue;
    uint256 auctionMaxBid;
    uint256 auctionMaxWeight;
    uint256 auctionNextBidWeight;
    uint32 auctionTotalBid;
    mapping(uint32 => uint256) assets;
    mapping(uint256 => address) shareholders;
    mapping(uint32 => address) targetPriceVotersAddress;
    mapping(address => CollectionTargetPriceVoteInfo) targetPriceVotes;
    mapping(uint32 => CollectionAuctionBid) bids;
}

struct Collection {
    uint256 totalCollection;
    mapping(uint256 => CollectionInfo) collections;
}

struct GovernanceFounder {
    address addr;
    uint256 controlWeight;
}

struct GovernanceManager {
    address addr;
    uint256 controlWeight;
    string dataURI;
}

struct GovernanceAuditor {
    bool approve;
    string dataURI;
}

struct GovernanceCustodian {
    bool approve;
    string dataURI;
}

struct GovernanceOperation {
    address addr;
    uint256 controlWeight;
    string dataURI;
}

struct GovernancePolicy {
    uint256 policyWeight;
    uint256 maxWeight;
    uint32 voteDuration;
    uint32 effectiveDuration;
    uint256 minWeightOpenVote;
    uint256 minWeightValidVote;
    uint256 minWeightApproveVote;
    uint256 policyValue;
    uint8 decider;
    bool exists;
    bool openVote;
}

struct GovernanceInitPolicy {
    string policyName;
    uint256 policyWeight;
    uint256 maxWeight;
    uint32 voteDuration;
    uint32 effectiveDuration;
    uint256 minWeightOpenVote;
    uint256 minWeightValidVote;
    uint256 minWeightApproveVote;
    uint256 policyValue;
    uint8 decider;
}

struct GovernanceVoter {
    bool voted;
    bool approve;
}

struct Governance {
    bool isInitContractAddress;
    bool isInitPolicy;
    uint16 totalFounder;
    uint16 totalManager;
    uint16 totalAdmin;
    uint16 totalOperation;
    uint256 founderMaxControlWeight;
    uint256 managerMaxControlWeight;
    uint256 operationMaxControlWeight;
    mapping(bytes32 => GovernancePolicy) policies;
    mapping(uint16 => GovernanceFounder) founders;
    mapping(address => uint16) foundersAddress;
    mapping(uint16 => GovernanceManager) managers;
    mapping(address => uint16) managersAddress;
    mapping(uint16 => address) admins;
    mapping(uint16 => GovernanceOperation) operations;
    mapping(address => uint16) operationsAddress;
    mapping(address => GovernanceAuditor) auditors;
    mapping(address => GovernanceCustodian) custodians;
}

struct ManagementFund {
    address governanceContract;
    uint256 managementFundValue;
    uint256 lockupFundValue;
    uint256 lastDistributeFundTimestamp;
    uint256 lastDistributeLockupFundTimestamp;
    uint256 totalLockupFundSlot;
    uint256 firstUnsettleLockupFundSlot;
    mapping(uint256 => ManagementFundLockupFund) lockupFunds;
}

struct ManagementFundLockupFundList {
    address addr;
    uint256 amount;
}

struct ManagementFundLockupFund {
    uint256 startingTotalARAValue;
    uint256 targetTotalARAValue;
    uint256 lastUnlockTotalARAValue;
    uint256 remainLockup;
    uint256 totalLockup;
    uint256 prevUnsettleLockupFundSlot;
    uint256 nextUnsettleLockupFundSlot;
    uint16 totalList;
    mapping(uint16 => ManagementFundLockupFundList) lists;
}

struct ProposalVoter {
    bool voted;
    bool approve;
}

struct ProposalPolicyIndex {
    bytes32 policyIndex;
    uint32 id;
    bool openVote;
    bool exists;
}

struct ProposalPolicy {
    bool exists;
    ProposalPolicyInfo info;
    mapping(uint32 => address) votersAddress;
    mapping(address => ProposalVoter) voters;
}

struct ProposalPolicyInfo {
    bytes32 policyIndex;
    bool openVote;
    bool countVote;
    bool applyProposal;
    uint256 closeVoteTimestamp;
    uint256 policyWeight;
    uint256 maxWeight;
    uint32 voteDuration;
    uint32 effectiveDuration;
    uint256 minWeightOpenVote;
    uint256 minWeightValidVote;
    uint256 minWeightApproveVote;
    uint256 policyValue;
    uint8 decider;
    uint8 voteDecider;
    uint256 totalVoteToken;
    uint256 totalApproveToken;
    uint256 totalSupplyToken;
    bool voteResult;
    uint256 processResultTimestamp;
    uint32 totalVoter;
}

struct ProposalListInfo {
    address addr;
    uint256 controlWeight;
    string dataURI;
}

struct ProposalList {
    bool exists;
    bytes32 policyIndex;
    bool openVote;
    bool countVote;
    bool applyProposal;
    bool voteValid;
    bool voteApprove;
    uint256 maxWeight;
    uint256 closeVoteTimestamp;
    uint256 totalVoteToken;
    uint256 totalApproveToken;
    uint256 totalSupplyToken;
    uint256 processResultTimestamp;
    uint32 totalVoter;
    uint16 totalList;
    mapping(uint32 => address) votersAddress;
    mapping(address => ProposalVoter) voters;
    mapping(uint16 => ProposalListInfo) lists;
}

struct Proposal {
    mapping(bytes32 => ProposalPolicyIndex) policyProposalIndexes;
    mapping(uint32 => ProposalPolicy) policyProposals;
    mapping(uint32 => ProposalList) listProposals;
}

struct CollateralToken {
    address owner;
}

struct AppStorage {
    uint256 x;
    uint256 y;
    uint256 sum;
    bytes m;
    address m2;
    Asset asset;
    Collection collection;
    Member member;
    ManagementFund managementFund;
    Governance governance;
    Proposal proposal;
    CollateralToken collateralToken;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}
