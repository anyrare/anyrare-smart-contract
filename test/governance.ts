import { expect } from "chai";

export const initPolicies = [
  {
    policyName: "ARA_COLLATERAL_WEIGHT",
    policyWeight: 400000,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 432000,
    minWeightOpenVote: 30000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "ARA_MINT_MANAGEMENT_FUND_WEIGHT",
    policyWeight: 600000,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 432000,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "BUYBACK_WEIGHT",
    policyWeight: 50000,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 432000,
    minWeightOpenVote: 50000,
    minWeightValidVote: 150000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "MANAGEMENT_FUND_FOUNDER_WEIGHT",
    policyWeight: 500000,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 432000,
    minWeightOpenVote: 1000000,
    minWeightValidVote: 1000000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "MANAGEMENT_FUND_MANAGER_WEIGHT",
    policyWeight: 300000,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 432000,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "FINANCING_CASHFLOW_LOCKUP_WEIGHT",
    policyWeight: 650000,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 432000,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "FINANCING_CASHFLOW_LOCKUP_TARGET_VALUE_WEIGHT",
    policyWeight: 3000000,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 432000,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "FINANCING_CASHFLOW_LOCKUP_PARTIAL_UNLOCK_WEIGHT",
    policyWeight: 50000,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 432000,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "MANAGEMENT_FUND_DISTRIBUTE_FUND_PERIOD",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 432000,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 21600,
    decider: 1,
  },

  {
    policyName: "MANAGEMENT_FUND_DISTRIBUTE_LOCKUP_FUND_PERIOD",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 432000,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 21600,
    decider: 1,
  },
  {
    policyName: "OPEN_AUCTION_NFT_PLATFORM_FEE",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 90000,
    decider: 1,
  },
  {
    policyName: "OPEN_AUCTION_NFT_REFERRAL_FEE",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 10000,
    decider: 0,
  },
  {
    policyName: "EXTENDED_AUCTION_NFT_TIME_TRIGGER",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 300,
    decider: 1,
  },
  {
    policyName: "EXTENDED_AUCTION_NFT_DURATION",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 300,
    decider: 1,
  },

  {
    policyName: "EXTENDED_AUCTION_COLLECTION_TIME_TRIGGER",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 300,
    decider: 1,
  },
  {
    policyName: "EXTENDED_AUCTION_COLLECTION_DURATION",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 300,
    decider: 1,
  },
  {
    policyName: "MEET_RESERVE_PRICE_AUCTION_NFT_TIME_LEFT",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 86400,
    decider: 1,
  },
  {
    policyName: "CLOSE_AUCTION_NFT_PLATFORM_FEE",
    policyWeight: 22500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "CLOSE_AUCTION_NFT_REFERRAL_BUYER_FEE",
    policyWeight: 2500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "CLOSE_AUCTION_NFT_REFERRAL_SELLER_FEE",
    policyWeight: 2000,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "CLOSE_AUCTION_NFT_REFERRAL_FOUNDER_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "CLOSE_AUCTION_NFT_PLATFORM_FOUNDER_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "CLOSE_AUCTION_NFT_REFERRAL_CUSTODIAN_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "CLOSE_AUCTION_NFT_PLATFORM_CUSTODIAN_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "MINT_NFT_FEE",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 10000,
    decider: 1,
  },
  {
    policyName: "MINT_NFT_REFERRAL_AUDITOR_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "MINT_NFT_PLATFORM_AUDITOR_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "NFT_CUSTODIAN_CAN_CLAIM_DURATION",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 7776000,
    decider: 1,
  },
  {
    policyName: "CREATE_COLLECTION_FEE",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 10000,
    decider: 1,
  },
  {
    policyName: "CREATE_COLLECTION_REFERRAL_COLLECTOR_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "BUY_COLLECTION_PLATFORM_FEE",
    policyWeight: 200,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "BUY_COLLECTION_PLATFORM_COLLECTOR_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "BUY_COLLECTION_REFERRAL_COLLECTOR_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "BUY_COLLECTION_REFERRAL_INVESTOR_FEE",
    policyWeight: 25,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "SELL_COLLECTION_PLATFORM_FEE",
    policyWeight: 200,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "SELL_COLLECTION_PLATFORM_COLLECTOR_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "SELL_COLLECTION_REFERRAL_COLLECTOR_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "SELL_COLLECTION_REFERRAL_INVESTOR_FEE",
    policyWeight: 25,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "TRANSFER_COLLECTION_PLATFORM_FEE",
    policyWeight: 200,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "TRANSFER_COLLECTION_REFERRAL_COLLECTOR_FEE",
    policyWeight: 25,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "TRANSFER_COLLECTION_REFERRAL_SENDER_FEE",
    policyWeight: 25,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "TRANSFER_COLLECTION_REFERRAL_RECEIVER_FEE",
    policyWeight: 25,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "OPEN_AUCTION_COLLECTION_DURATION",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 432000,
    decider: 1,
  },
  {
    policyName: "OPEN_AUCTION_COLLECTION_NEXT_BID_WEIGHT",
    policyWeight: 100000,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "CLOSE_AUCTION_COLLECTION_PLATFORM_FEE",
    policyWeight: 200,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "CLOSE_AUCTION_COLLECTION_REFERRAL_COLLECTOR_FEE",
    policyWeight: 25,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "CLOSE_AUCTION_COLLECTION_REFERRAL_INVESTOR_FEE",
    policyWeight: 25,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "MANAGERS_LIST",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 432000,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "OPERATIONS_LIST",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 432000,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "AUDITORS_LIST",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 110000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "CUSTODIANS_LIST",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "OPEN_BUY_IT_NOW_NFT_PLATFORM_FEE",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 10000,
    decider: 1,
  },
  {
    policyName: "OPEN_BUY_IT_NOW_NFT_REFERRAL_FEE",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 1000,
    decider: 1,
  },
  {
    policyName: "BUY_IT_NOW_NFT_PLATFORM_FEE",
    policyWeight: 22500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "BUY_IT_NOW_NFT_REFERRAL_BUYER_FEE",
    policyWeight: 2500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "BUY_IT_NOW_NFT_REFERRAL_SELLER_FEE",
    policyWeight: 2000,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "BUY_IT_NOW_NFT_REFERRAL_FOUNDER_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "BUY_IT_NOW_NFT_PLATFORM_FOUNDER_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "BUY_IT_NOW_NFT_REFERRAL_CUSTODIAN_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "BUY_IT_NOW_NFT_PLATFORM_CUSTODIAN_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "OFFER_NFT_DURATION",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 864000,
    decider: 1,
  },
  {
    policyName: "OFFER_NFT_PLATFORM_FEE",
    policyWeight: 22500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "OFFER_NFT_REFERRAL_BUYER_FEE",
    policyWeight: 2500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "OFFER_NFT_REFERRAL_SELLER_FEE",
    policyWeight: 2000,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "OFFER_NFT_REFERRAL_FOUNDER_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "OFFER_NFT_PLATFORM_FOUNDER_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "OFFER_NFT_REFERRAL_CUSTODIAN_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "OFFER_NFT_PLATFORM_CUSTODIAN_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "REDEEM_NFT_PLATFORM_FEE",
    policyWeight: 20000,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 1000,
    decider: 1,
  },
  {
    policyName: "REDEEM_NFT_REFERRAL_FEE",
    policyWeight: 20000,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 1000,
    decider: 1,
  },
  {
    policyName: "REDEEM_NFT_REFERRAL_FOUNDER_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "REDEEM_NFT_PLATFORM_FOUNDER_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "REDEEM_NFT_REFERRAL_CUSTODIAN_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "REDEEM_NFT_PLATFORM_CUSTODIAN_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "REDEEM_NFT_REFERRAL_OWNER_FEE",
    policyWeight: 1250,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 10,
    decider: 1,
  },
  {
    policyName: "REDEEM_NFT_REVERT_DURATION",
    policyWeight: 0,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 604800,
    decider: 1,
  },
  {
    policyName: "TRANSFER_NFT_PLATFORM_FEE",
    policyWeight: 22500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 100,
    decider: 1,
  },
  {
    policyName: "TRANSFER_NFT_REFERRAL_SENDER_FEE",
    policyWeight: 2000,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 1000,
    decider: 0,
  },
  {
    policyName: "TRANSFER_NFT_REFERRAL_RECEIVER_FEE",
    policyWeight: 2500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 1000,
    decider: 0,
  },
  {
    policyName: "TRANSFER_NFT_REFERRAL_FOUNDER_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "TRANSFER_NFT_PLATFORM_FOUNDER_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
  {
    policyName: "TRANSFER_NFT_REFERRAL_CUSTODIAN_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 0,
  },
  {
    policyName: "TRANSFER_NFT_PLATFORM_CUSTODIAN_FEE",
    policyWeight: 12500,
    maxWeight: 1000000,
    voteDuration: 432000,
    effectiveDuration: 86400,
    minWeightOpenVote: 100000,
    minWeightValidVote: 510000,
    minWeightApproveVote: 750000,
    policyValue: 0,
    decider: 1,
  },
];

export const initGovernancePolicies = async (
  governanceContract: any,
  founder: any,
  manager: any,
  operation: any,
  auditor: any,
  custodian: any
) => {
  console.log("\n*** Init Governance Policies");

  console.log(initPolicies.length);
  await governanceContract.initPolicy(
    1,
    [{ addr: founder.address, controlWeight: 1000000 }],
    manager.address,
    operation.address,
    auditor.address,
    custodian.address,
    initPolicies.length,
    initPolicies
  );

  console.log("governance policies");

  expect(
    (await governanceContract.getPolicy("ARA_COLLATERAL_WEIGHT")).policyWeight
  ).to.equal(400000);
  console.log("Test: Get ARA_COLLATERAL_WEIGHT");
  expect(
    (await governanceContract.getPolicy("OPEN_AUCTION_NFT_PLATFORM_FEE"))
      .decider
  ).to.equal(1);
  expect(
    +(await governanceContract.getPolicy("OPEN_AUCTION_NFT_PLATFORM_FEE"))
      .policyValue
  ).to.equal(90000);

  console.log("Test: Get OPEN_AUCTION_PLATFORM_FEE");
  expect(
    (
      await governanceContract.getPolicy(
        "MEET_RESERVE_PRICE_AUCTION_NFT_TIME_LEFT"
      )
    ).policyValue
  ).to.equal(86400);
  console.log("Test: Get MEET_RESERVE_PRICE_AUCTION_NFT_TIME_LEFT");

  const getManager = await governanceContract.getManager(0);
  expect({
    addr: getManager.addr,
    controlWeight: +getManager.controlWeight,
  }).to.eql({
    addr: manager.address,
    controlWeight: 1000000,
  });
  console.log("Test: Get manager");
  expect(await governanceContract.isAuditor(auditor.address)).to.equal(true);
  console.log("Test: auditor is auditor");
  expect(await governanceContract.isCustodian(custodian.address)).to.equal(
    true
  );
  console.log("Test: custodian is custodian");
  expect(await governanceContract.isManager(manager.address)).to.equal(true);
  console.log("Test: manager is manager");
  expect(
    (await governanceContract.getPolicy("CLOSE_AUCTION_NFT_PLATFORM_FEE"))
      .policyWeight
  ).to.equal(22500);
  console.log("Test: close auction platform fee to equal 22500");
};
