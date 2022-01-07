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
import { testOpentPolicyWithSuccessVote } from "./proposal";

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
      nftUtilsContract,
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
