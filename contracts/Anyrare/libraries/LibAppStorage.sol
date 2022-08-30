// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";

struct MemberInfo {
    address addr;
    address referral;
    string username;
    string thumbnail;
    uint256 totalAsset;
    uint256 totalBidAuction;
    uint256 totalWonAuction;
    uint256 totalFounderCollection;
    uint256 totalOwnCollection;
    mapping(uint256 => uint256) assets;
    mapping(uint256 => uint256) collections;
}

struct Member {
    uint256 totalMember;
    mapping(address => MemberInfo) members;
    mapping(bytes32 => address) usernames;
}

struct GovernanceManager {
    address addr;
    string dataURI;
    uint256 controlWeight;
}

struct GovernanceAuditor {
    bool approve;
    string dataURI;
}

struct GovernanceCustodian {
    bool approve;
    string dataURI;
}

struct GovernancePolicy {
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
    bool exists;
    bool openVote;
}

struct Governance {
    bool isInitContractAddress;
    bool isInitPolicy;
    uint8 totalManager;
    uint256 managerMaxControlWeight;
    mapping(bytes32 => GovernancePolicy) policies;
    mapping(uint8 => GovernanceManager) managers;
    mapping(address => uint8) managersAddress;
    mapping(uint8 => address) admins;
    mapping(address => uint8) adminsAddress;
    mapping(address => GovernanceAuditor) auditors;
    mapping(address => GovernanceCustodian) custodians;
}

struct ContractAddress {
    address araDiamond;
    address assetDiamond;
    address collectionDiamond;
    address currency;
}

struct ProposalVoter {
    bool voted;
    bool approve;
}

struct PolicyProposalIndex {
    bytes32 policyIndex;
    uint32 id;
    bool openVote;
    bool exists;
}

struct PolicyProposal {
    bool exists;
    PolicyProposalInfo info;
    mapping(uint32 => address) votersAddress;
    mapping(address => ProposalVoter) voters;
}

struct PolicyProposalInfo {
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

struct ListProposalListInfo {
    address addr;
    uint256 controlWeight;
    string dataURI;
}

struct ListProposalInfo {
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
}

struct ListProposal {
    bool exists;
    ListProposalInfo info;
    mapping(uint32 => address) votersAddress;
    mapping(address => ProposalVoter) voters;
    mapping(uint16 => ListProposalListInfo) lists;
}

struct Proposal {
    uint32 policyProposalId;
    uint32 listProposalId;
    mapping(bytes32 => PolicyProposalIndex) policyProposalIndexes;
    mapping(uint32 => PolicyProposal) policyProposals;
    mapping(uint32 => ListProposal) listProposals;
}

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
    uint256 offerOpenTimestamp;
    uint256 offerCloseTimestamp;
    uint256 redeemTimestamp;
    uint32 totalAuction;
    uint32 bidId;
    uint32 offerId;
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
    address addr;
    address collector;
    string name;
    string symbol;
    string tokenURI;
    uint8 lowestDecimal;
    uint8 precision;
    uint256 totalSupply;
    uint256 maxWeight;
    uint256 collectorFeeWeight;
    uint16 totalAsset;
    uint32 totalShareholder;
    bool isAuction;
    bool isFreeze;
    uint256 targetPrice;
    uint256 targetPriceTotalSum;
    uint256 targetPriceTotalVoteToken;
    uint32 targetPriceTotalVoter;
    // uint32 targetPriceTotalVoterIndex;
}

struct CollectionOrderbookInfo {
    address collectionAddr;
    uint256 collectionId;
    address owner;
    uint256 price;
    uint256 volume;
    uint256 filledVolume;
    uint256 timestamp;
    uint8 status;
}

struct Collection {
    uint256 totalCollection;
    uint256 totalBidInfo;
    uint256 totalAskInfo;
    mapping(uint256 => CollectionInfo) collections;
    mapping(address => uint256) collectionIndexes;
    mapping(uint256 => mapping(uint16 => uint256)) collectionAssets;
    mapping(uint256 => mapping(uint64 => address)) targetPriceVotersAddress;
    mapping(uint256 => mapping(address => CollectionTargetPriceVoteInfo)) targetPriceVotes;
    mapping(uint256 => mapping(address => uint64)) shareholderIndexes;
    mapping(uint256 => mapping(uint64 => address)) shareholders;
    mapping(uint256 => uint256[256]) bidsPrice;
    mapping(uint256 => mapping(uint8 => mapping(uint8 => uint256))) bidsVolume;
    mapping(uint256 => uint256) totalBidInfoCollection;
    mapping(uint256 => CollectionOrderbookInfo) bidsInfo;
    mapping(uint256 => mapping(uint8 => mapping(uint8 => uint256))) bidsInfoIndexTotal;
    mapping(uint256 => mapping(uint8 => mapping(uint8 => mapping(uint256 => uint256)))) bidsInfoIndex;
    mapping(uint256 => uint256[256]) asksPrice;
    mapping(uint256 => mapping(uint8 => mapping(uint8 => mapping(uint256 => uint256)))) asksVolume;
    mapping(uint256 => uint256) totalAskInfoCollection;
    mapping(uint256 => CollectionOrderbookInfo) asksInfo;
    mapping(uint256 => mapping(uint8 => mapping(uint8 => uint256))) asksInfoIndexTotal;
    mapping(uint256 => mapping(uint8 => mapping(uint8 => CollectionOrderbookInfo))) asksInfoIndex;
}

struct CollectionStorage {
    bool isInit;
    address owner;
    uint96 totalSupply;
    string name;
    string symbol;
    string tokenURI;
    bytes32[1000] emptyMapSlots;
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => uint256) balances;
    address[] approvedContracts;
    mapping(address => uint256) approvedContractIndexes;
}

struct ManagementFund {
    uint256 managementFundValue;
}

struct AppStorage {
    Member member;
    Collection collection;
    ContractAddress contractAddress;
    Governance governance;
    Proposal proposal;
    ManagementFund managementFund;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}
