import { expect } from "chai";
import { ethers } from "hardhat";

describe("AnyRare Smart Contracts", async () => {
  it("Long Pipeline Testing", async () => {
    console.log("*** Initialize wallet address");

    const [
      root,
      user1,
      user2,
      user3,
      user4,
      user5,
      auditor0,
      auditor1,
      custodian0,
      custodian1,
      manager0,
    ] = await ethers.getSigners();

    console.log("root wallet: ", root.address);
    console.log("user1 wallet: ", user1.address);
    console.log("user2 wallet: ", user2.address);
    console.log("user3 wallet: ", user3.address);
    console.log("user4 wallet: ", user4.address);
    console.log("user5 wallet: ", user5.address);
    console.log("auditor0 wallet: ", auditor0.address);
    console.log("auditor1 wallet: ", auditor1.address);
    console.log("custodian0 wallet: ", custodian0.address);
    console.log("custodian1 wallet: ", custodian1.address);
    console.log("manager0 wallet: ", manager0.address);

    console.log("\n*** Deploy Contract");

    const MemberContract = await ethers.getContractFactory("Member");
    const GovernanceContract = await ethers.getContractFactory("Governance");
    const BancorFormulaContract = await ethers.getContractFactory(
      "BancorFormula"
    );
    const ARATokenContract = await ethers.getContractFactory("ARAToken");
    const CollateralTokenContract = await ethers.getContractFactory(
      "CollateralToken"
    );
    const ProposalContract = await ethers.getContractFactory("Proposal");
    const NFTFactoryContract = await ethers.getContractFactory("NFTFactory");
    const ManagementFundContract = await ethers.getContractFactory(
      "ManagementFund"
    );

    const memberContract = await MemberContract.deploy(root.address);
    const governanceContract = await GovernanceContract.deploy();
    const bancorFormulaContract = await BancorFormulaContract.deploy();
    const collateralTokenContract = await CollateralTokenContract.deploy(
      root.address,
      "wDAI",
      "wDAI",
      100
    );
    const araTokenContract = await ARATokenContract.deploy(
      governanceContract.address,
      bancorFormulaContract.address,
      "ARA",
      "ARA",
      collateralTokenContract.address,
      2 ** 32
    );
    const proposalContract = await ProposalContract.deploy(
      governanceContract.address
    );
    const nftFactoryContract = await NFTFactoryContract.deploy(
      governanceContract.address,
      "AnyRare NFT Factory",
      "AnyRare NFT Factory"
    );
    const managementFundContract = await ManagementFundContract.deploy(
      governanceContract.address
    );

    console.log("MemberContract Addr: ", memberContract.address);
    console.log("GovernanceContract Addr: ", governanceContract.address);
    console.log("BancorFormulaContract Addr: ", bancorFormulaContract.address);
    console.log(
      "CollateralTokenContract Addr: ",
      collateralTokenContract.address
    );
    console.log("ARATokenContract Addr: ", araTokenContract.address);
    console.log("ProposalContract Addr: ", proposalContract.address);
    console.log("NFTFactoryContract Addr: ", nftFactoryContract.address);

    console.log("\n*** Governance Contract");
    console.log("**** Init contract address");
    await governanceContract.initContractAddress(
      memberContract.address,
      araTokenContract.address,
      proposalContract.address,
      nftFactoryContract.address,
      managementFundContract.address
    );

    expect(await governanceContract.getMemberContract()).to.equal(
      memberContract.address
    );
    expect(await governanceContract.getARATokenContract()).to.equal(
      araTokenContract.address
    );
    expect(await governanceContract.getProposalContract()).to.equal(
      proposalContract.address
    );
    expect(await governanceContract.getNFTFactoryContract()).to.equal(
      nftFactoryContract.address
    );
    console.log("Test: GetMemberContract Pass!");
    console.log("Test: GetARATokenContract Pass!");
    console.log("Test: GetProposalContract Pass!");
    console.log("Test: GetNFTFactoryContract Pass!");

    console.log("**** Init policy");
    // decider: 0 is ARA Token Owner, 1 is Manager
    const initPolicies = [
      {
        policyName: "ARA_COLLATERAL_WEIGHT",
        policyWeight: 400000,
        maxWeight: 1000000,
        voteDuration: 432000,
        minWeightOpenVote: 100000,
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
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 0,
      },
      {
        policyName: "OPEN_AUCTION_NFT_PLATFORM_FEE",
        policyWeight: 0,
        maxWeight: 1000000,
        voteDuration: 432000,
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
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 10000,
        decider: 1,
      },
      {
        policyName: "EXTENDED_AUCTION_NFT_TIME_TRIGGER",
        policyWeight: 0,
        maxWeight: 1000000,
        voteDuration: 432000,
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 600,
        decider: 1,
      },
      {
        policyName: "EXTENDED_AUCTION_NFT_DURATION",
        policyWeight: 0,
        maxWeight: 1000000,
        voteDuration: 432000,
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 600,
        decider: 1,
      },
      {
        policyName: "MEET_RESERVE_PRICE_AUCTION_NFT_TIME_LEFT",
        policyWeight: 0,
        maxWeight: 1000000,
        voteDuration: 432000,
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
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 1,
      },
      {
        policyName: "CLOSE_AUCTION_NFT_REFERRAL_SELLER_FEE",
        policyWeight: 2000,
        maxWeight: 1000000,
        voteDuration: 432000,
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 1,
      },
      {
        policyName: "NFT_MINT_FEE",
        policyWeight: 0,
        maxWeight: 1000000,
        voteDuration: 432000,
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 10000,
        decider: 1,
      },
      {
        policyName: "CREATE_COLLECTION_FEE",
        policyWeight: 0,
        maxWeight: 1000000,
        voteDuration: 432000,
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 10000,
        decider: 1,
      },
      {
        policyName: "BUY_COLLECTION_PLATFORM_FEE",
        policyWeight: 200,
        maxWeight: 1000000,
        voteDuration: 432000,
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 1,
      },
      {
        policyName: "BUY_COLLECTION_REFERRAL_COLLECTOR_FEE",
        policyWeight: 25,
        maxWeight: 1000000,
        voteDuration: 432000,
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 1,
      },
      {
        policyName: "BUY_COLLECTION_REFERRAL_INVESTOR_FEE",
        policyWeight: 25,
        maxWeight: 1000000,
        voteDuration: 432000,
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 1,
      },
      {
        policyName: "SELL_COLLECTION_PLATFORM_FEE",
        policyWeight: 200,
        maxWeight: 1000000,
        voteDuration: 432000,
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 1,
      },
      {
        policyName: "SELL_COLLECTION_REFERRAL_COLLECTOR_FEE",
        policyWeight: 25,
        maxWeight: 1000000,
        voteDuration: 432000,
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 1,
      },
      {
        policyName: "SELL_COLLECTION_REFERRAL_INVESTOR_FEE",
        policyWeight: 25,
        maxWeight: 1000000,
        voteDuration: 432000,
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 1,
      },
      {
        policyName: "TRANSFER_COLLECTION_PLATFORM_FEE",
        policyWeight: 200,
        maxWeight: 1000000,
        voteDuration: 432000,
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
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 1,
      },
      {
        policyName: "OPEN_AUCTION_COLLECTION_DURATION",
        policyWeight: 0,
        maxWeight: 1000000,
        voteDuration: 432000,
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
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 1,
      },
      {
        policyName: "CLOSE_AUCTION_COLLECTION_REFERRAL_INVESTOR_FEE",
        policyWeight: 25,
        maxWeight: 1000000,
        voteDuration: 432000,
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 1,
      },
      {
        policyName: "MANAGERS_LIST",
        policyWeight: 0,
        maxWeight: 1000000,
        voteDuration: 432000,
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 0,
      },
      {
        policyName: "AUDITORS_LIST",
        policyWeight: 0,
        maxWeight: 1000000,
        voteDuration: 432000,
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
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 10000,
        decider: 1,
      },
      {
        policyName: "BUY_IT_NOW_NFT_PLATFORM_FEE",
        policyWeight: 22500,
        maxWeight: 1000000,
        voteDuration: 432000,
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
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 1,
      },
      {
        policyName: "BUY_IT_NOW_NFT_REFERRAL_SELLER_FEE",
        policyWeight: 2000,
        maxWeight: 1000000,
        voteDuration: 432000,
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
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 1,
      },
      {
        policyName: "OFFER_NFT_REFERRAL_SELLER_FEE",
        policyWeight: 2000,
        maxWeight: 1000000,
        voteDuration: 432000,
        minWeightOpenVote: 100000,
        minWeightValidVote: 510000,
        minWeightApproveVote: 750000,
        policyValue: 0,
        decider: 1,
      },
    ];
    await governanceContract.initPolicy(
      manager0.address,
      auditor0.address,
      custodian0.address,
      initPolicies.length,
      initPolicies
    );
    expect(
      (await governanceContract.getPolicy("ARA_COLLATERAL_WEIGHT")).policyWeight
    ).to.equal(400000);
    console.log("Test: Get ARA_COLLATERAL_WEIGHT policyWeight");
    expect(
      (await governanceContract.getPolicy("OPEN_AUCTION_NFT_PLATFORM_FEE"))
        .decider
    ).to.equal(1);
    console.log("Test: Get OPEN_AUCTION_PLATFORM_FEE decider");
    const getManager0 = await governanceContract.getManager(0);
    expect({
      addr: getManager0.addr,
      controlWeight: +getManager0.controlWeight,
    }).to.eql({
      addr: manager0.address,
      controlWeight: 1000000,
    });
    console.log("Test: Get manager0");
    expect(await governanceContract.isAuditor(auditor0.address)).to.equal(true);
    console.log("Test: auditor0 is auditor");
    expect(await governanceContract.isCustodian(custodian0.address)).to.equal(
      true
    );
    console.log("Test: custodian0 is custodian");
    expect(await governanceContract.isManager(manager0.address)).to.equal(true);
    console.log("Test: manager0 is manager");
    expect(
      (await governanceContract.getPolicy("CLOSE_AUCTION_NFT_PLATFORM_FEE"))
        .policyWeight
    ).to.equal(22500);
    console.log("Test: close auction platform fee to equal 22500");

    console.log("\n*** Member Contract");
    await memberContract.setMember(user1.address, root.address);
    await memberContract.setMember(user2.address, root.address);
    await expect(memberContract.setMember(user3.address, user3.address)).to.be
      .reverted;
    console.log("Test: Should be revert if referral is self referrence.");

    expect(await memberContract.members(root.address)).to.equal(root.address);
    expect(await memberContract.getReferral(user1.address)).to.equal(
      root.address
    );
    expect(await memberContract.members(user1.address)).to.equal(root.address);
    expect(await memberContract.members(user2.address)).to.equal(root.address);
    expect(+(await memberContract.members(user3.address))).to.equal(0x0);
    expect(await memberContract.isMember(user2.address)).to.equal(true);
    expect(await memberContract.isMember(user3.address)).to.equal(false);
    console.log("Test: referral for root is root");
    console.log("Test: referral for user1 is root");
    console.log("Test: referral for user2 is user1");
    console.log("Test: referral for user3 is null");
    console.log("Test: user2 is member");
    console.log("Test: user3 is not member");

    await memberContract.setMember(user3.address, root.address);
    await memberContract.setMember(user4.address, user3.address);
    await memberContract.setMember(auditor1.address, user4.address);
    await memberContract.setMember(custodian1.address, user4.address);
    console.log("Set user3 and user4 to be member for next step");

    console.log("\n*** Bancor Formula");
    expect(
      +(await bancorFormulaContract.purchaseTargetAmount(200, 100, 400000, 500))
    ).to.equal(209);
    expect(
      +(await bancorFormulaContract.purchaseTargetAmount(409, 600, 400000, 500))
    ).to.equal(112);
    expect(
      +(await bancorFormulaContract.purchaseTargetAmount(
        10033333,
        104442323322300,
        10333,
        3283333332444444
      ))
    ).to.equal(367276);
    expect(
      +(await bancorFormulaContract.purchaseTargetAmount(
        2 ** 32,
        100,
        400000,
        100
      ))
    ).to.equal(1372276027);
    expect(
      +(await bancorFormulaContract.saleTargetAmount(200, 100, 400000, 50))
    ).to.equal(51);
    console.log("Test: PurchaseTargetAmount");
    console.log("Test: SaleTargetAmount");

    console.log("\n*** Collateral Token");
    await collateralTokenContract.mint(300000);
    expect(+(await collateralTokenContract.balanceOf(root.address))).to.equal(
      300100
    );
    console.log(
      "Mint: 300,000 wDAI to root, now root wallet have 300,100 wDAI"
    );
    await collateralTokenContract.mint(500000);
    expect(+(await collateralTokenContract.balanceOf(root.address))).to.equal(
      800100
    );
    console.log(
      "Mint: 500,000 wDAI to root, now root wallet have 800,100 wDAI"
    );
    expect(+(await collateralTokenContract.totalSupply())).to.equal(800100);
    console.log("Total Supply for wDAI is 800,100");
    await collateralTokenContract.transfer(user1.address, 15000);
    console.log("Transfer: 15,000 wDAI from root to user1");
    await collateralTokenContract.transfer(araTokenContract.address, 100);
    console.log(
      "Transfer: 100 wDAI from root to ARATokenContract as a seed collateral"
    );
    expect(+(await collateralTokenContract.balanceOf(root.address))).to.equal(
      785000
    );
    console.log("Balance: root wallet is 785,000 wDAI");
    await collateralTokenContract.connect(user1).transfer(user2.address, 500);
    console.log("Transfer: 500 wDai from user1 to user2");
    expect(+(await collateralTokenContract.balanceOf(user1.address))).to.equal(
      14500
    );
    console.log("Balance: wDAI for user1 has remain 14,500 from 15,000");
    expect(+(await collateralTokenContract.balanceOf(user2.address))).to.equal(
      500
    );
    console.log("Balance: user2 has 500 wDAI");
    await expect(collateralTokenContract.connect(user1).mint(1000)).to.be
      .reverted;
    console.log(
      "User1 try to mint new wDAI but failed because of has no permission. Only root wallet can allow to mint new wDAI."
    );

    console.log("\n*** ARATokenContract");
    await expect(araTokenContract.connect(user3).mint(300)).to.be.reverted;
    console.log(
      "User3 try to mint new ARA token but failed because of is not a member."
    );
    await collateralTokenContract
      .connect(user1)
      .approve(araTokenContract.address, 2 ** 52);
    console.log(
      "User1 approve spending limit for ARATokenContract for 2 ** 52 wDAI."
    );
    expect(
      await collateralTokenContract
        .connect(user1)
        .allowance(user1.address, araTokenContract.address)
    ).to.equal(2 ** 52);
    console.log("Test: check spending limit for user1 to ARATokenContract.");
    expect(
      await collateralTokenContract.balanceOf(araTokenContract.address)
    ).to.equal(100);
    console.log(
      "Balance of wDAI for ARATokenContract as a collateral reserve is 100 wDAI."
    );
    console.log("\n**** Mint");
    expect(await araTokenContract.totalSupply()).to.equal(2 ** 32);
    const araTotalSupply0 = 2 ** 32;
    const araCollateral0 = +(await collateralTokenContract.balanceOf(
      araTokenContract.address
    ));
    await araTokenContract.connect(user1).mint(100);
    const araTotalSupply1 = +(await araTokenContract.totalSupply());
    const user1Balance0 = +(await araTokenContract.balanceOf(user1.address));
    const managementFundBalance0 = +(await araTokenContract.balanceOf(
      managementFundContract.address
    ));
    const araCollateral1 = +(await collateralTokenContract.balanceOf(
      araTokenContract.address
    ));
    console.log(
      "Balance: (user1, managementFund) ",
      user1Balance0,
      managementFundBalance0
    );
    console.log(
      "TotalSupply: (beforeMint, afterMint) ",
      araTotalSupply0,
      araTotalSupply1
    );
    expect(araTotalSupply1 - araTotalSupply0).to.equal(
      user1Balance0 + managementFundBalance0
    );
    console.log("Test: Increment supply = user1 + managementfund");
    expect(araCollateral1 - araCollateral0).to.equal(100);
    console.log(
      "Collateral: (beforeMint, afterMint) ",
      araCollateral0,
      araCollateral1
    );

    console.log("\n**** Transfer");
    await araTokenContract.connect(user1).approve(user2.address, 2 ** 52);
    await araTokenContract.connect(user1).transfer(user2.address, 2 ** 16);
    expect(+(await araTokenContract.balanceOf(user2.address))).to.equal(
      2 ** 16
    );
    console.log("Test: transfer 2**16 ARA from user1 to user2");
    await araTokenContract.connect(user2).transfer(user3.address, 2 ** 4);
    expect(+(await araTokenContract.balanceOf(user3.address))).to.equal(2 ** 4);
    expect(+(await araTokenContract.balanceOf(user2.address))).to.equal(
      2 ** 16 - 2 ** 4
    );
    console.log("Test: transfer 2**4 ARA from user2 to user3");
    await araTokenContract.connect(user3).transfer(user1.address, 2 ** 2);
    console.log("Test: transfer 2**2 ARA from user3 to user1");

    console.log("\n**** Withdraw");
    const user1ColBalance2 = +(await collateralTokenContract.balanceOf(
      user1.address
    ));
    const user1ARABalance2 = +(await araTokenContract.balanceOf(user1.address));
    const araTotalSupply2 = +(await araTokenContract.totalSupply());
    const araColBalance2 = +(await collateralTokenContract.balanceOf(
      araTokenContract.address
    ));
    const managementFundBalance2 = +(await araTokenContract.balanceOf(
      managementFundContract.address
    ));
    await araTokenContract.connect(user1).withdraw(user1ARABalance2 / 3);
    const user1ColBalance3 = +(await collateralTokenContract.balanceOf(
      user1.address
    ));
    const user1ARABalance3 = +(await araTokenContract.balanceOf(user1.address));
    const araTotalSupply3 = +(await araTokenContract.totalSupply());
    const araColBalance3 = +(await collateralTokenContract.balanceOf(
      araTokenContract.address
    ));
    const managementFundBalance3 = +(await araTokenContract.balanceOf(
      managementFundContract.address
    ));

    console.log(
      "User1 Collateral: (beforeWithdraw, afterWithdraw) ",
      user1ColBalance2,
      user1ColBalance3
    );
    console.log(
      "ARA Collateral: (beforeWithdraw, afterWithdraw) ",
      araColBalance2,
      araColBalance3
    );
    console.log(
      "User1 ARA: (beforeWithdraw, afterWithdraw, diff) ",
      user1ARABalance2,
      user1ARABalance3,
      user1ARABalance3 - user1ARABalance2
    );
    console.log(
      "ARA TotalSupply: (beforeWithdraw, afterWithdraw, diff) ",
      araTotalSupply2,
      araTotalSupply3,
      araTotalSupply3 - araTotalSupply2
    );
    console.log(
      "ManagmentFund ARA: (beforeWithdraw, afterWithdraw) ",
      managementFundBalance2,
      managementFundBalance3
    );

    console.log("\n**** Burn");
    const totalSupply17 = +(await araTokenContract.totalSupply());
    const user1Balance17 = +(await araTokenContract.balanceOf(user1.address));
    const collateral17 = +(await collateralTokenContract.balanceOf(
      araTokenContract.address
    ));
    const buyTarget17 = +(await bancorFormulaContract.purchaseTargetAmount(
      totalSupply17,
      collateral17,
      400000,
      3000
    ));
    await araTokenContract.connect(user1).burn(1000000);
    console.log("Burn: user1 burn 1000000");
    const totalSupply18 = +(await araTokenContract.totalSupply());
    const user1Balance18 = +(await araTokenContract.balanceOf(user1.address));
    const collateral18 = +(await collateralTokenContract.balanceOf(
      araTokenContract.address
    ));
    const buyTarget18 = +(await bancorFormulaContract.purchaseTargetAmount(
      totalSupply18,
      collateral18,
      400000,
      3000
    ));
    console.log(
      "Balance: user1 ",
      user1Balance17,
      user1Balance18,
      user1Balance18 - user1Balance17
    );
    console.log(
      "Balance: totalSupply ",
      totalSupply17,
      totalSupply18,
      totalSupply18 - totalSupply17
    );
    console.log(
      "Balance: collateral ",
      collateral17,
      collateral18,
      collateral18 - collateral17
    );
    console.log(
      "Buy Target: ",
      buyTarget17,
      buyTarget18,
      buyTarget18 - buyTarget17
    );

    console.log("\n*** Proposal");
    console.log("Transfer token from root to user");
    await araTokenContract.connect(root).transfer(user1.address, 2 ** 32 / 4);
    await araTokenContract.connect(root).transfer(user2.address, 2 ** 32 / 4);
    await araTokenContract.connect(root).transfer(user3.address, 2 ** 32 / 4);
    await araTokenContract.connect(root).transfer(user4.address, 2 ** 32 / 16);
    const araTotalSupply4 = +(await araTokenContract.totalSupply());
    const rootBalance4 = +(await araTokenContract.balanceOf(root.address));
    const user1Balance4 = +(await araTokenContract.balanceOf(user1.address));
    const user2Balance4 = +(await araTokenContract.balanceOf(user2.address));
    const user3Balance4 = +(await araTokenContract.balanceOf(user3.address));
    const user4Balance4 = +(await araTokenContract.balanceOf(user4.address));

    console.log("Total ARA Supply: ", araTotalSupply4);
    console.log("root: ", rootBalance4);
    console.log("user1: ", user1Balance4);
    console.log("user2: ", user2Balance4);
    console.log("user3: ", user3Balance4);
    console.log("user4: ", user4Balance4);

    console.log("\n**** Adjust Buyback Weight with success vote");

    const policyName0 = "BUYBACK_WEIGHT";
    await proposalContract.openPolicyProposal(
      policyName0,
      80000,
      1000000,
      432000,
      100000,
      510000,
      750000,
      0,
      0
    );
    const policyProposal0 = await proposalContract.getCurrentPolicyProposal(
      policyName0
    );
    expect(policyProposal0.policyWeight).to.equal(80000);
    expect(policyProposal0.minWeightApproveVote).to.equal(750000);
    console.log("Test: Open policy proposal");

    await expect(
      proposalContract.openPolicyProposal(
        policyName0,
        80000,
        1000000,
        432000,
        100000,
        510000,
        750000,
        0,
        0
      )
    ).to.be.reverted;
    console.log("Test: attemp to open duplicate policy with open vote");

    await expect(
      proposalContract
        .connect(user4)
        .openPolicyProposal(
          "DIVIDEND_WEIGHT",
          80000,
          1000000,
          432000,
          100000,
          510000,
          750000,
          0,
          0
        )
    ).to.be.reverted;
    await expect(
      proposalContract
        .connect(user4)
        .openPolicyProposal(
          "ARA_COLLATERAL_WEIGHT",
          80000,
          1000000,
          432000,
          100000,
          510000,
          750000,
          0,
          0
        )
    ).to.be.reverted;
    console.log(
      "Test: attemp to open new policy proposal but not enough token"
    );
    await proposalContract.connect(user1).votePolicyProposal(policyName0, true);
    console.log("Vote: user1 vote approve");
    await proposalContract.connect(user2).votePolicyProposal(policyName0, true);
    console.log("Vote: user2 vote approve");
    await proposalContract.connect(user3).votePolicyProposal(policyName0, true);
    console.log("Vote: user3 vote reject");
    await proposalContract
      .connect(user4)
      .votePolicyProposal(policyName0, false);
    console.log("Vote: user4 vote approve");
    await expect(proposalContract.processPolicyProposal(policyName0)).to.be
      .reverted;
    console.log(
      "Test: Try to process vote result but failed because not ending"
    );
    await ethers.provider.send("evm_increaseTime", [432000]);
    console.log("Increase block timestamp");
    await proposalContract.processPolicyProposal(policyName0);
    console.log("Process: vote result");
    const voteResult0 = await proposalContract.getCurrentPolicyProposal(
      policyName0
    );
    expect(voteResult0.totalApproveToken).to.equal(
      user1Balance4 + user2Balance4 + user3Balance4
    );
    expect(voteResult0.voteResult).to.equal(true);
    expect(voteResult0.policyWeight).to.equal(80000);
    console.log("Test: vote result");
    expect(
      (await governanceContract.getPolicy(policyName0)).policyWeight
    ).to.equal(80000);
    console.log("Test: policy in governance should be change");
    await expect(proposalContract.processPolicyProposal(policyName0)).to.be
      .reverted;
    console.log("Test: avoid duplicate process result");

    await expect(
      proposalContract.connect(user3).votePolicyProposal(policyName0, true)
    ).to.be.reverted;
    console.log("Test: Try to vote close proposal should be reverted");

    console.log(
      "\n**** Adjust ARA Collateral Weight with failed vote because not enough token to valid vote"
    );
    const policyName1 = "ARA_COLLATERAL_WEIGHT";
    await proposalContract.openPolicyProposal(
      policyName1,
      300000,
      1000000,
      432000,
      100000,
      510000,
      750000,
      0,
      0
    );
    await proposalContract.getCurrentPolicyProposal(policyName1);
    expect(
      (await governanceContract.getPolicy(policyName1)).policyWeight
    ).to.equal(400000);
    await proposalContract.connect(user1).votePolicyProposal(policyName1, true);
    console.log("Vote: user1 vote approve");
    await ethers.provider.send("evm_increaseTime", [432000]);
    await proposalContract.processPolicyProposal(policyName1);
    const voteResult1 = await proposalContract.getCurrentPolicyProposal(
      policyName1
    );
    expect(voteResult1.voteResult).to.equal(false);
    expect(
      (await governanceContract.getPolicy(policyName1)).policyWeight
    ).to.equal(400000);
    console.log("Process: vote result equal false, nothing happend");

    console.log(
      "\n**** Adjust ARA Collateral Weight with failed vote because not enough token to valid vote"
    );
    const policyName2 = "ARA_COLLATERAL_WEIGHT";
    await proposalContract.openPolicyProposal(
      policyName1,
      300000,
      1000000,
      432000,
      100000,
      510000,
      750000,
      0,
      0
    );
    await proposalContract.getCurrentPolicyProposal(policyName2);
    expect(
      (await governanceContract.getPolicy(policyName1)).policyWeight
    ).to.equal(400000);
    await proposalContract.connect(user1).votePolicyProposal(policyName2, true);
    await proposalContract.connect(user2).votePolicyProposal(policyName2, true);
    await proposalContract
      .connect(user3)
      .votePolicyProposal(policyName2, false);
    console.log("Vote: user1 vote approve");
    console.log("Vote: user2 vote approve");
    console.log("Vote: user3 vote reject");
    await ethers.provider.send("evm_increaseTime", [432000]);
    await proposalContract.processPolicyProposal(policyName2);
    const voteResult2 = await proposalContract.getCurrentPolicyProposal(
      policyName1
    );
    expect(voteResult2.voteResult).to.equal(false);
    expect(
      (await governanceContract.getPolicy(policyName1)).policyWeight
    ).to.equal(400000);
    console.log("Process: vote result equal false, nothing happend");

    console.log("\n**** Adjust managment list");
    await proposalContract.openManagerProposal(3, 1000000, [
      {
        addr: user1.address,
        controlWeight: 400000,
      },
      {
        addr: user2.address,
        controlWeight: 300000,
      },
      { addr: user3.address, controlWeight: 30000 },
    ]);

    console.log("Set: open manager proposal");
    await proposalContract.connect(user1).voteManagerProposal(true);
    await proposalContract.connect(user2).voteManagerProposal(true);
    await proposalContract.connect(user3).voteManagerProposal(true);
    console.log("Vote: user 1, 2, 3 vote approve");
    await ethers.provider.send("evm_increaseTime", [432000]);
    await proposalContract.processManagerProposal();
    await proposalContract.getCurrentManagerProposal();
    console.log("Process: vote result to be accept");
    expect(await governanceContract.getTotalManager()).to.equal(3);
    console.log("Test: Total manager = 3");
    const newManager1 = await governanceContract.getManager(0);
    const newManager2 = await governanceContract.getManager(1);
    const newManager3 = await governanceContract.getManager(2);
    expect({
      addr: newManager1.addr,
      controlWeight: +newManager1.controlWeight,
    }).to.eql({
      addr: user1.address,
      controlWeight: 400000,
    });
    expect({
      addr: newManager2.addr,
      controlWeight: +newManager2.controlWeight,
    }).to.eql({
      addr: user2.address,
      controlWeight: 300000,
    });
    expect({
      addr: newManager3.addr,
      controlWeight: +newManager2.controlWeight,
    }).to.eql({
      addr: user3.address,
      controlWeight: 300000,
    });
    expect(await governanceContract.isManager(user1.address)).to.equal(true);
    expect(await governanceContract.isManager(user2.address)).to.equal(true);
    expect(await governanceContract.isManager(user3.address)).to.equal(true);
    console.log("Test: New managers list should be set");

    console.log("\n*** Open auditor proposal");
    expect(await governanceContract.isAuditor(auditor1.address)).to.equal(
      false
    );
    console.log("Test: auditor1 is not an auditor");
    await expect(proposalContract.openAuditorProposal(auditor1.address)).to.be
      .reverted;
    console.log(
      "Test: root cannot open auditor proposal because is not a manager"
    );

    await proposalContract.connect(user1).openAuditorProposal(auditor1.address);

    console.log("Test: open proposal");

    await expect(proposalContract.voteAuditorProposal(true)).to.be.reverted;
    console.log("Test: root cannot vote auditor because is not a manager");
    await proposalContract.connect(user1).voteAuditorProposal(true);
    await proposalContract.connect(user2).voteAuditorProposal(true);
    await proposalContract.connect(user3).voteAuditorProposal(true);
    console.log("Vote: manager 1, 2, 3 vote approve");
    await ethers.provider.send("evm_increaseTime", [432000]);
    await proposalContract.processAuditorProposal();
    console.log("Proccess: vote result");
    expect(await governanceContract.isAuditor(auditor1.address)).to.equal(true);
    console.log("Result: auditor1 is an auditor");

    console.log("\n*** Open custodian proposal");
    expect(await governanceContract.isCustodian(custodian1.address)).to.equal(
      false
    );
    console.log("Test: custodian1 is not a custodian");
    await expect(proposalContract.openCustodianProposal(custodian1.address)).to
      .be.reverted;
    console.log(
      "Test: root cannot open custodian proposal because is not a manager"
    );
    await proposalContract
      .connect(user1)
      .openCustodianProposal(custodian1.address);

    await expect(proposalContract.voteCustodianProposal(true)).to.be.reverted;
    console.log("Test: root cannot vote custodian because is not a manager");
    await proposalContract.connect(user1).voteCustodianProposal(true);
    await proposalContract.connect(user2).voteCustodianProposal(true);
    await proposalContract.connect(user3).voteCustodianProposal(true);
    console.log("Vote: manager 1, 2, 3 vote approve");
    await ethers.provider.send("evm_increaseTime", [432000]);
    await proposalContract.processCustodianProposal();
    console.log("Proccess: vote result");
    expect(await governanceContract.isCustodian(custodian1.address)).to.equal(
      true
    );
    console.log("Result: custodian1 is a custodian");

    console.log("\n*** NFT Factory");
    const nft0 = await nftFactoryContract
      .connect(auditor0)
      .mint(
        user1.address,
        custodian0.address,
        "https://example/metadata.json",
        1000000,
        100000,
        3000000,
        1000
      );
    console.log("Process: Mint nft");
    await araTokenContract
      .connect(user1)
      .approve(nftFactoryContract.address, 2 ** 52);
    expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
      nftFactoryContract.address
    );
    expect(await nftFactoryContract.tokenURI(nft0.value)).to.equal(
      "https://example/metadata.json"
    );
    console.log("mint: lock nft in smart contract, tokenId: ", +nft0.value);
    await nftFactoryContract
      .connect(custodian0)
      .custodianSign(nft0.value, 25000, 130430);
    console.log("sign: custodian sign");
    await nftFactoryContract.connect(user1).payFeeAndClaimToken(nft0.value);
    console.log("User1 pay fee and claim token");
    expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
      user1.address
    );
    console.log("Now user1 is owner of token0");
    await expect(
      nftFactoryContract.connect(user1).payFeeAndClaimToken(nft0.value)
    ).to.be.reverted;
    console.log("Test: user1 try to claim token again but failed");
    await nftFactoryContract
      .connect(user1)
      .transferFrom(user1.address, user2.address, nft0.value);
    console.log("Transfer: user1 transfer nft token to user2");
    expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
      user2.address
    );
    console.log("Test: owner of token0 is user2");

    console.log("\n**** NFT Auction");
    await nftFactoryContract
      .connect(user2)
      .openAuction(nft0.value, 432000, 25600, 1000000, 100000);
    console.log("Process: Open nft0 auction");
    const user1Balance6 = +(await araTokenContract.balanceOf(user1.address));
    await nftFactoryContract.connect(user1).bidAuction(nft0.value, 25600);
    const user1Balance7 = +(await araTokenContract.balanceOf(user1.address));
    console.log(
      "Bid: User1 bid 25600, Balance: (beforeBid, afterBid) ",
      user1Balance6,
      user1Balance7,
      user1Balance7 - user1Balance6
    );
    const nftBalance6 = +(await araTokenContract.balanceOf(
      nftFactoryContract.address
    ));
    console.log("Balance: nft ARA balance ", nftBalance6);
    const user2Balance6 = +(await araTokenContract.balanceOf(user2.address));
    console.log(user2Balance6);
    await araTokenContract
      .connect(user2)
      .approve(nftFactoryContract.address, 2 ** 52);
    await expect(
      nftFactoryContract.connect(user2).bidAuction(nft0.value, 25601)
    ).to.be.reverted;
    console.log(
      "Bid: user2 try to bid 25601 but failed because less than minimum bid"
    );
    await nftFactoryContract.connect(user2).bidAuction(nft0.value, 28160);
    console.log("Bid: user2 bid 28160");
    const user2Balance7 = +(await araTokenContract.balanceOf(user2.address));
    console.log(
      "Balance: user2 (beforeBid, afterBid)",
      user2Balance6,
      user2Balance7,
      user2Balance7 - user2Balance6
    );
    const user1Balance8 = +(await araTokenContract.balanceOf(user1.address));
    expect(user1Balance8).to.equal(user1Balance6);
    console.log("Balance: user1 pass bid should be revert, ", user1Balance8);
    expect(
      +(await araTokenContract.balanceOf(nftFactoryContract.address))
    ).to.equal(28160);
    console.log("Test: nft0 balance should be 28160");
    await nftFactoryContract.connect(user2).bidAuction(nft0.value, 31000);
    const user2Balance8 = +(await araTokenContract.balanceOf(user2.address));
    console.log("Bid: user2 increase bid to 31000");
    console.log(
      "Balance: user2 balance (beforeBid, afterBid)",
      user2Balance6,
      user2Balance8,
      user2Balance8 - user2Balance6
    );
    const user4Balance6 = +(await araTokenContract.balanceOf(user4.address));
    await araTokenContract
      .connect(user4)
      .approve(nftFactoryContract.address, 2 ** 52);
    await nftFactoryContract.connect(user4).bidAuction(nft0.value, 34500);
    console.log("Bid: user4 bid 34500");
    const user4Balance7 = +(await araTokenContract.balanceOf(user4.address));
    console.log(
      "Balance user 4 (beforeBid, afterBid), ",
      user4Balance6,
      user4Balance7,
      user4Balance7 - user4Balance6
    );
    const user2Balance9 = +(await araTokenContract.balanceOf(user2.address));
    expect(user2Balance9).to.equal(user2Balance6);
    console.log(
      "Test: user2 balance should be revert to beforeBid ",
      user2Balance6
    );

    console.log("\n**** Process Auction");
    expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
      nftFactoryContract.address
    );
    const bidValue10 = 34500;
    const auctionData0 = await nftFactoryContract.getNFTAuction(nft0.value);
    expect(auctionData0.owner).to.equal(user2.address);
    console.log("Test: before process owner of nft is smartcontract");
    const referralBuyer = await memberContract.getReferral(user4.address);
    const referralSeller = await memberContract.getReferral(user2.address);
    expect(referralSeller).to.equal(root.address);
    const referralSeller10Balance = +(await araTokenContract.balanceOf(
      referralSeller
    ));
    const referralBuyer10Balance = +(await araTokenContract.balanceOf(
      referralBuyer
    ));
    const custodian10Balance = +(await araTokenContract.balanceOf(
      custodian0.address
    ));
    const founder10Balance = +(await araTokenContract.balanceOf(user1.address));
    const managementFund10Balance = +(await araTokenContract.balanceOf(
      await governanceContract.getManagementFundContract()
    ));

    await ethers.provider.send("evm_increaseTime", [432000]);
    await nftFactoryContract.processAuction(nft0.value);
    console.log("Process: Auction");

    const referralBuyer11Balance = +(await araTokenContract.balanceOf(
      referralBuyer
    ));
    const referralSeller11Balance = +(await araTokenContract.balanceOf(
      referralSeller
    ));
    const custodian11Balance = +(await araTokenContract.balanceOf(
      custodian0.address
    ));
    const founder11Balance = +(await araTokenContract.balanceOf(user1.address));
    const managementFund11Balance = +(await araTokenContract.balanceOf(
      await governanceContract.getManagementFundContract()
    ));
    console.log(
      "Balance: referral seller ",
      referralSeller10Balance,
      referralSeller11Balance,
      referralSeller11Balance - referralSeller10Balance
    );
    expect(referralSeller11Balance - referralSeller10Balance).to.equal(
      Math.floor((bidValue10 * 2000) / 1000000)
    );
    console.log(
      "Balance: referral buyer ",
      referralBuyer10Balance,
      referralBuyer11Balance,
      referralBuyer11Balance - referralBuyer10Balance
    );
    expect(referralBuyer11Balance - referralBuyer10Balance).to.equal(
      Math.floor((bidValue10 * 2500) / 1000000)
    );
    console.log(
      "Balance: custodian ",
      custodian10Balance,
      custodian11Balance,
      custodian11Balance - custodian10Balance
    );
    expect(custodian11Balance - custodian10Balance).to.equal(
      Math.floor((bidValue10 * 25000) / 1000000)
    );
    console.log(
      "Balance: founder ",
      founder10Balance,
      founder11Balance,
      founder11Balance - founder10Balance
    );
    expect(founder11Balance - founder10Balance).to.equal(
      (bidValue10 * 100000) / 1000000
    );
    console.log(
      "Balance: ManagementFund ",
      managementFund10Balance,
      managementFund11Balance,
      managementFund11Balance - managementFund10Balance
    );
    expect(managementFund11Balance - managementFund10Balance).to.equal(
      Math.floor((bidValue10 * 22500) / 1000000)
    );
    expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
      user4.address
    );
    console.log("Transfer: new owner of nft0 is user4");

    console.log("Test: Open auction with no bid");
    const user4Balance12 = +(await araTokenContract.balanceOf(user4.address));
    await nftFactoryContract
      .connect(user4)
      .openAuction(nft0.value, 432000, 56000, 1000000, 100000);
    const user4Balance13 = +(await araTokenContract.balanceOf(user4.address));
    expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
      nftFactoryContract.address
    );
    await ethers.provider.send("evm_increaseTime", [432000]);
    await nftFactoryContract.connect(user4).processAuction(nft0.value);
    expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
      user4.address
    );
    const user4Balance14 = +(await araTokenContract.balanceOf(user4.address));
    console.log(
      "Balance: user4 ",
      user4Balance12,
      user4Balance13,
      user4Balance14
    );

    console.log("Test: Buy it now");
    const user4Balance15 = +(await araTokenContract.balanceOf(user4.address));
    await nftFactoryContract.connect(user4).openBuyItNow(nft0.value, 40000);
    console.log("Open: buy it now with value 30000");
    const user4Balance16 = +(await araTokenContract.balanceOf(user4.address));
    console.log(
      "Balance: ",
      user4Balance15,
      user4Balance16,
      user4Balance16 - user4Balance15
    );
    const buyer16 = user2;
    const seller16 = user4;
    await araTokenContract
      .connect(buyer16)
      .approve(nftFactoryContract.address, 2 ** 52);
    const referralSeller16 = await memberContract.members(seller16.address);
    const referralBuyer16 = await memberContract.members(buyer16.address);
    const referralBuyerBalance16 = +(await araTokenContract.balanceOf(
      referralBuyer16
    ));
    const referralSellerBalance16 = +(await araTokenContract.balanceOf(
      referralSeller16
    ));
    const sellerBalance16 = +(await araTokenContract.balanceOf(
      seller16.address
    ));
    const buyerBalance16 = +(await araTokenContract.balanceOf(buyer16.address));
    const founderBalance16 = +(await araTokenContract.balanceOf(user1.address));
    const platformBalance16 = +(await araTokenContract.balanceOf(
      managementFundContract.address
    ));

    await nftFactoryContract.connect(buyer16).buyFromBuyItNow(nft0.value);
    expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
      buyer16.address
    );
    console.log("Buy: user1 buy nft0");
    const referralBuyerBalance17 = +(await araTokenContract.balanceOf(
      referralBuyer16
    ));
    const referralSellerBalance17 = +(await araTokenContract.balanceOf(
      referralSeller16
    ));
    const sellerBalance17 = +(await araTokenContract.balanceOf(
      seller16.address
    ));
    const buyerBalance17 = +(await araTokenContract.balanceOf(buyer16.address));
    const founderBalance17 = +(await araTokenContract.balanceOf(user1.address));
    const platformBalance17 = +(await araTokenContract.balanceOf(
      managementFundContract.address
    ));
    expect(sellerBalance17 - sellerBalance16).to.equal(33920);
    console.log(
      "Balance: seller ",
      sellerBalance16,
      sellerBalance17,
      sellerBalance17 - sellerBalance16
    );
    expect(platformBalance17 - platformBalance16).to.equal(
      (40000 * 22500) / 1000000
    );
    console.log(
      "Balance: platform ",
      platformBalance16,
      platformBalance17,
      platformBalance17 - platformBalance16
    );
    expect(buyerBalance17 - buyerBalance16).to.equal(-40000);
    console.log(
      "Balance: buyer ",
      buyerBalance16,
      buyerBalance17,
      buyerBalance17 - buyerBalance16
    );
    expect(founderBalance17 - founderBalance16).to.equal(
      (40000 * 100000) / 1000000
    );
    console.log(
      "Balance: founder ",
      founderBalance16,
      founderBalance17,
      founderBalance17 - founderBalance16
    );
    expect(referralBuyerBalance17 - referralBuyerBalance16).to.equal(
      (40000 * 2500) / 1000000
    );
    console.log(
      "Balance: referral buyer ",
      referralBuyerBalance16,
      referralBuyerBalance17,
      referralBuyerBalance17 - referralBuyerBalance16
    );
    expect(referralSellerBalance17 - referralSellerBalance16).to.equal(
      (40000 * 2000) / 1000000
    );
    console.log(
      "Balance: referral seller ",
      referralSellerBalance16,
      referralSellerBalance17,
      referralSellerBalance17 - referralSellerBalance16
    );

    console.log("\n**** Test open buy it now and close");
    expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
      user2.address
    );
    await nftFactoryContract.connect(user2).openBuyItNow(nft0.value, 50000);
    console.log("Process: open buy it now price 50000");
    await nftFactoryContract
      .connect(user2)
      .changeBuyItNowPrice(nft0.value, 45000);
    expect(
      (await nftFactoryContract.connect(user2).nfts(nft0.value)).buyItNow.value
    ).to.equal(45000);
    console.log("Change: price to 45000");
    expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
      nftFactoryContract.address
    );
    await nftFactoryContract.connect(user2).closeBuyItNow(nft0.value);
    expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
      user2.address
    );
    console.log("Close: buy it now");
    console.log(
      "Get: tokenURI ",
      await nftFactoryContract.tokenURI(nft0.value)
    );

    // await ARATokenContract.connect(user1)._mint(user1.address, 100);
  });
});
