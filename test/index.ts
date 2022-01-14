import { expect } from "chai";
import { deployContract } from "./deploy";
import { ethers } from "hardhat";
import { initGovernancePolicies } from "./governance";
import { initMember } from "./member";
import { testBancorFormulaForARA } from "./bancorFormula";
import {
  testMintARA,
  testTransferARA,
  testWithdrawARA,
  testBurnARA,
  distributeARAFromRootToUser,
  testNoArbitrageMintAndWithdraw,
} from "./araToken";
import {
  testAdjustManagementList,
  testOpenPolicyWithNotEnoughtValidVote1,
  testOpenPolicyWithNotEnoughtValidVote2,
  testOpentPolicyWithSuccessVote,
  testAdjustAuditor,
  testAdjustCustodian,
} from "./proposal";
import {
  testAuctionNFT,
  testMintNFT,
  testAuctionNFTWithNoBid,
  testAuctionNFTWithBidButNotMeetReservePrice,
  testNFTBuyItNow,
  testNFTOffer,
} from "./nft";
import { testNFTTransfer } from "./nft";
import { testNFTRedeem } from "./nft";
import { testCreateCollection } from "./collection";

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
      manager1,
      operation0,
      operation1,
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

    const {
      memberContract,
      governanceContract,
      bancorFormulaContract,
      collateralTokenContract,
      araTokenContract,
      proposalContract,
      nftFactoryContract,
      nftUtilsContract,
      collectionFactoryContract,
      collectionUtilsContract,
      managementFundContract,
    } = await deployContract(ethers, root);

    await initGovernancePolicies(
      governanceContract,
      manager0,
      operation0,
      auditor0,
      custodian0
    );

    await initMember(
      memberContract,
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
      manager1,
      operation0,
      operation1
    );

    await testBancorFormulaForARA(
      araTokenContract,
      bancorFormulaContract,
      collateralTokenContract,
      root,
      user1,
      user2
    );

    await testMintARA(
      araTokenContract,
      collateralTokenContract,
      managementFundContract,
      user1,
      user3
    );
    await testTransferARA(araTokenContract, user1, user2, user3);
    await testWithdrawARA(
      araTokenContract,
      collateralTokenContract,
      managementFundContract,
      user1
    );
    await testBurnARA(
      araTokenContract,
      collateralTokenContract,
      bancorFormulaContract,
      user1
    );
    await distributeARAFromRootToUser(
      araTokenContract,
      root,
      user1,
      user2,
      user3,
      user4
    );
    await testNoArbitrageMintAndWithdraw(
      araTokenContract,
      collateralTokenContract,
      user1
    );
    await testOpentPolicyWithSuccessVote(
      ethers,
      proposalContract,
      araTokenContract,
      governanceContract,
      user1,
      user2,
      user3,
      user4
    );
    await testOpenPolicyWithNotEnoughtValidVote1(
      ethers,
      proposalContract,
      governanceContract,
      user1
    );
    await testOpenPolicyWithNotEnoughtValidVote2(
      ethers,
      proposalContract,
      governanceContract,
      user1,
      user2,
      user3
    );
    await testAdjustManagementList(
      ethers,
      proposalContract,
      governanceContract,
      araTokenContract,
      user1,
      user2,
      user3
    );
    await testAdjustAuditor(
      ethers,
      proposalContract,
      governanceContract,
      araTokenContract,
      auditor1,
      user1,
      user2,
      user3
    );
    await testAdjustCustodian(
      ethers,
      proposalContract,
      governanceContract,
      araTokenContract,
      custodian1,
      user1,
      user2,
      user3
    );
    await testMintNFT(
      nftFactoryContract,
      araTokenContract,
      auditor0,
      custodian0,
      user4,
      user2
    );
    await testAuctionNFT(
      ethers,
      nftFactoryContract,
      araTokenContract,
      memberContract,
      governanceContract,
      user1,
      user2,
      user3,
      +(await nftFactoryContract.getCurrentTokenId())
    );
    await testAuctionNFTWithNoBid(
      ethers,
      nftFactoryContract,
      araTokenContract,
      auditor0,
      custodian0,
      user1
    );
    await testAuctionNFTWithBidButNotMeetReservePrice(
      ethers,
      nftFactoryContract,
      araTokenContract,
      auditor0,
      custodian0,
      user1,
      user2
    );
    await testNFTBuyItNow(
      ethers,
      nftFactoryContract,
      araTokenContract,
      governanceContract,
      memberContract,
      auditor0,
      custodian0,
      user1,
      user2
    );
    await testNFTOffer(
      ethers,
      nftFactoryContract,
      araTokenContract,
      governanceContract,
      memberContract,
      auditor0,
      custodian0,
      user1,
      user2,
      user3
    );
    await testNFTTransfer(
      ethers,
      nftFactoryContract,
      araTokenContract,
      governanceContract,
      memberContract,
      auditor0,
      custodian0,
      user1,
      user2,
      user4
    );
    await testNFTRedeem(
      ethers,
      nftFactoryContract,
      araTokenContract,
      governanceContract,
      memberContract,
      auditor0,
      custodian0,
      user1,
      user4
    );
    await testCreateCollection(
      ethers,
      nftFactoryContract,
      collectionFactoryContract,
      araTokenContract,
      memberContract,
      governanceContract,
      user1,
      user2,
      user3,
      user4,
      auditor0,
      custodian0
    );
  });
});
