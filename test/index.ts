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
} from "./araToken";
import {
  testAdjustManagementList,
  testOpenPolicyWithNotEnoughtValidVote1,
  testOpenPolicyWithNotEnoughtValidVote2,
  testOpentPolicyWithSuccessVote,
  testAdjustAuditor,
  testAdjustCustodian,
} from "./proposal";
import { testAuctionNFT, testMintNFT, testAuctionNFTWithNoBid } from "./nft";

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

    const {
      memberContract,
      governanceContract,
      bancorFormulaContract,
      collateralTokenContract,
      araTokenContract,
      proposalContract,
      nftFactoryContract,
      nftTransferFeeContract,
      managementFundContract,
      utilsContract,
    } = await deployContract(ethers, root);

    await initGovernancePolicies(
      governanceContract,
      manager0,
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
      auditor1,
      custodian1
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
      user1,
      user2,
      user3
    );
    await testAdjustAuditor(
      ethers,
      proposalContract,
      governanceContract,
      auditor1,
      user1,
      user2,
      user3
    );
    await testAdjustCustodian(
      ethers,
      proposalContract,
      governanceContract,
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

    // console.log("Test: Open auction with no bid");
    // const user4Balance12 = +(await araTokenContract.balanceOf(user4.address));
    // await nftFactoryContract
    //   .connect(user4)
    //   .openAuction(nft0.value, 432000, 56000, 1000000, 100000);
    // const user4Balance13 = +(await araTokenContract.balanceOf(user4.address));
    // expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
    //   nftFactoryContract.address
    // );
    // await ethers.provider.send("evm_increaseTime", [432000]);
    // await nftFactoryContract.connect(user4).processAuction(nft0.value);
    // expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
    //   user4.address
    // );
    // const user4Balance14 = +(await araTokenContract.balanceOf(user4.address));
    // console.log(
    //   "Balance: user4 ",
    //   user4Balance12,
    //   user4Balance13,
    //   user4Balance14
    // );

    // console.log("Test: Buy it now");
    // const user4Balance15 = +(await araTokenContract.balanceOf(user4.address));
    // await nftFactoryContract.connect(user4).openBuyItNow(nft0.value, 40000);
    // console.log("Open: buy it now with value 30000");
    // const user4Balance16 = +(await araTokenContract.balanceOf(user4.address));
    // console.log(
    //   "Balance: ",
    //   user4Balance15,
    //   user4Balance16,
    //   user4Balance16 - user4Balance15
    // );
    // const buyer16 = user2;
    // const seller16 = user4;
    // await araTokenContract
    //   .connect(buyer16)
    //   .approve(nftFactoryContract.address, 2 ** 52);
    // const referralSeller16 = await memberContract.members(seller16.address);
    // const referralBuyer16 = await memberContract.members(buyer16.address);
    // const referralBuyerBalance16 = +(await araTokenContract.balanceOf(
    //   referralBuyer16
    // ));
    // const referralSellerBalance16 = +(await araTokenContract.balanceOf(
    //   referralSeller16
    // ));
    // const sellerBalance16 = +(await araTokenContract.balanceOf(
    //   seller16.address
    // ));
    // const buyerBalance16 = +(await araTokenContract.balanceOf(buyer16.address));
    // const founderBalance16 = +(await araTokenContract.balanceOf(user1.address));
    // const platformBalance16 = +(await araTokenContract.balanceOf(
    //   managementFundContract.address
    // ));

    // await nftFactoryContract.connect(buyer16).buyFromBuyItNow(nft0.value);
    // expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
    //   buyer16.address
    // );
    // console.log("Buy: user1 buy nft0");
    // const referralBuyerBalance17 = +(await araTokenContract.balanceOf(
    //   referralBuyer16
    // ));
    // const referralSellerBalance17 = +(await araTokenContract.balanceOf(
    //   referralSeller16
    // ));
    // const sellerBalance17 = +(await araTokenContract.balanceOf(
    //   seller16.address
    // ));
    // const buyerBalance17 = +(await araTokenContract.balanceOf(buyer16.address));
    // const founderBalance17 = +(await araTokenContract.balanceOf(user1.address));
    // const platformBalance17 = +(await araTokenContract.balanceOf(
    //   managementFundContract.address
    // ));
    // expect(sellerBalance17 - sellerBalance16).to.equal(33920);
    // console.log(
    //   "Balance: seller ",
    //   sellerBalance16,
    //   sellerBalance17,
    //   sellerBalance17 - sellerBalance16
    // );
    // expect(platformBalance17 - platformBalance16).to.equal(
    //   (40000 * 22500) / 1000000
    // );
    // console.log(
    //   "Balance: platform ",
    //   platformBalance16,
    //   platformBalance17,
    //   platformBalance17 - platformBalance16
    // );
    // expect(buyerBalance17 - buyerBalance16).to.equal(-40000);
    // console.log(
    //   "Balance: buyer ",
    //   buyerBalance16,
    //   buyerBalance17,
    //   buyerBalance17 - buyerBalance16
    // );
    // expect(founderBalance17 - founderBalance16).to.equal(
    //   (40000 * 100000) / 1000000
    // );
    // console.log(
    //   "Balance: founder ",
    //   founderBalance16,
    //   founderBalance17,
    //   founderBalance17 - founderBalance16
    // );
    // expect(referralBuyerBalance17 - referralBuyerBalance16).to.equal(
    //   (40000 * 2500) / 1000000
    // );
    // console.log(
    //   "Balance: referral buyer ",
    //   referralBuyerBalance16,
    //   referralBuyerBalance17,
    //   referralBuyerBalance17 - referralBuyerBalance16
    // );
    // expect(referralSellerBalance17 - referralSellerBalance16).to.equal(
    //   (40000 * 2000) / 1000000
    // );
    // console.log(
    //   "Balance: referral seller ",
    //   referralSellerBalance16,
    //   referralSellerBalance17,
    //   referralSellerBalance17 - referralSellerBalance16
    // );

    // console.log("\n**** Test open buy it now and close");
    // expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
    //   user2.address
    // );
    // await nftFactoryContract.connect(user2).openBuyItNow(nft0.value, 50000);
    // console.log("Process: open buy it now price 50000");
    // await nftFactoryContract
    //   .connect(user2)
    //   .changeBuyItNowPrice(nft0.value, 45000);
    // expect(
    //   (await nftFactoryContract.connect(user2).nfts(nft0.value)).buyItNow.value
    // ).to.equal(45000);
    // console.log("Change: price to 45000");
    // expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
    //   nftFactoryContract.address
    // );
    // await nftFactoryContract.connect(user2).closeBuyItNow(nft0.value);
    // expect(await nftFactoryContract.ownerOf(nft0.value)).to.equal(
    //   user2.address
    // );
    // console.log("Close: buy it now");
    // console.log(
    //   "Get: tokenURI ",
    //   await nftFactoryContract.tokenURI(nft0.value)
    // );

    // await ARATokenContract.connect(user1)._mint(user1.address, 100);
  });
});
