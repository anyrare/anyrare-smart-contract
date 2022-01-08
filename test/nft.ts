import { expect } from "chai";

export const testMintNFT = async (
  nftFactoryContract: any,
  araTokenContract: any,
  auditor: any,
  custodian: any,
  user1: any,
  user2: any
) => {
  console.log("\n*** NFT Factory");
  const nft = await nftFactoryContract
    .connect(auditor)
    .mint(
      user1.address,
      custodian.address,
      "https://example/metadata.json",
      1000000,
      100000,
      300000,
      3500,
      1000
    );
  console.log("Process: Mint nft");

  await araTokenContract
    .connect(user1)
    .approve(nftFactoryContract.address, 2 ** 52);
  expect(await nftFactoryContract.ownerOf(nft.value)).to.equal(
    nftFactoryContract.address
  );
  expect(await nftFactoryContract.tokenURI(nft.value)).to.equal(
    "https://example/metadata.json"
  );
  console.log("mint: lock nft in smart contract, tokenId: ", +nft.value);

  await nftFactoryContract
    .connect(custodian)
    .custodianSign(nft.value, 25000, 130430);
  console.log("sign: custodian sign");

  await araTokenContract
    .connect(user1)
    .approve(nftFactoryContract.address, 2 ** 52);
  await nftFactoryContract.connect(user1).payFeeAndClaimToken(nft.value);
  console.log("User1 pay fee and claim token");

  expect(await nftFactoryContract.ownerOf(nft.value)).to.equal(user1.address);
  console.log("Now user1 is owner of token0");

  await expect(nftFactoryContract.connect(user1).payFeeAndClaimToken(nft.value))
    .to.be.reverted;
  console.log("Test: user1 try to claim token again but failed");

  await nftFactoryContract
    .connect(user1)
    .transferFrom(user1.address, user2.address, nft.value);
  console.log("Transfer: user1 transfer nft token to user2");

  expect(await nftFactoryContract.ownerOf(nft.value)).to.equal(user2.address);
  console.log("Test: owner of token0 is user2");

  return nft;
};

export const testAuctionNFT = async (
  ethers: any,
  nftFactoryContract: any,
  araTokenContract: any,
  memberContract: any,
  governanceContract: any,
  root: any,
  user1: any,
  user2: any,
  user3: any,
  custodian: any,
  nft: any
) => {
  console.log("\n**** NFT Auction");
  console.log(await memberContract.isMember(user2.address));
  console.log(user2.address);

  await araTokenContract
    .connect(user2)
    .approve(nftFactoryContract.address, 2 ** 52);
  await araTokenContract
    .connect(user3)
    .approve(nftFactoryContract.address, 2 ** 52);
  console.log("Allowance: user2, user3 to nftContract");

  await expect(
    nftFactoryContract
      .connect(user3)
      .openAuction(nft.value, 432000, 25600, 40000, 1000000, 100000)
  ).to.be.reverted;
  console.log("Test: user3 try to open auction without owner permission.");

  const managementFundBalance0 = +(await araTokenContract.balanceOf(
    await governanceContract.getManagementFundContract()
  ));

  await nftFactoryContract
    .connect(user2)
    .openAuction(nft.value, 432000, 25600, 40000, 1000000, 100000);
  console.log("Process: Open nft0 auction");

  const managementFundBalance1 = +(await araTokenContract.balanceOf(
    await governanceContract.getManagementFundContract()
  ));
  expect(managementFundBalance1 - managementFundBalance0).to.equal(90000);
  console.log("Test: management fund should receive open fee.");
  expect(await nftFactoryContract.ownerOf(nft.value)).to.equal(
    nftFactoryContract.address
  );
  console.log("Test: nft move to escrow.");

  const user1Balance0 = +(await araTokenContract.balanceOf(user1.address));
  await nftFactoryContract.connect(user1).bidAuction(nft.value, 25600, 25700);
  const user1Balance1 = +(await araTokenContract.balanceOf(user1.address));
  expect(user1Balance0).to.equal(user1Balance1);
  console.log(
    "Bid: User1 bid 25600 - 25700 but less than reserve price, so user balance of user1 did not change."
  );
  const nftResult0 = await nftFactoryContract.nfts(nft.value);
  expect(nftResult0.bidId).to.equal(1);
  expect(nftResult0.totalAuction).to.equal(1);
  expect(nftResult0.status.auction).to.equal(true);

  const nftAuction0Result0 = await nftFactoryContract.getAuction(nft.value);
  expect(+nftAuction0Result0.value).to.equal(25700);
  expect(nftAuction0Result0.bidder).to.equal(user1.address);
  expect(nftAuction0Result0.reservePrice).to.equal(0);
  expect(nftAuction0Result0.maxBid).to.equal(0);
  expect(nftAuction0Result0.meetReservePrice).to.equal(false);

  const nftBid0 = await nftFactoryContract.getAuctionBid(nft.value, 0);
  expect(+nftBid0.value).to.equal(25700);
  expect(nftBid0.bidder).to.equal(user1.address);
  expect(nftBid0.meetReservePrice).to.equal(false);
  console.log("Test: check bidId 0");

  await nftFactoryContract.connect(user1).bidAuction(nft.value, 35000, 48000);
  const user1Balance2 = +(await araTokenContract.balanceOf(user1.address));
  expect(user1Balance2 - user1Balance0).to.equal(-48000);

  const nftResult1 = await nftFactoryContract.nfts(nft.value);
  expect(nftResult1.bidId).to.equal(2);
  expect(nftResult1.totalAuction).to.equal(1);
  expect(nftResult1.status.auction).to.equal(true);

  const nftAuction0Result1 = await nftFactoryContract.getAuction(nft.value);
  expect(+nftAuction0Result1.value).to.equal(40000);
  expect(nftAuction0Result1.bidder).to.equal(user1.address);
  expect(nftAuction0Result1.reservePrice).to.equal(40000);
  expect(nftAuction0Result1.maxBid).to.equal(0);
  expect(nftAuction0Result1.meetReservePrice).to.equal(true);
  expect(
    nftAuction0Result1.closeAuctionTimestamp <
    nftAuction0Result0.closeAuctionTimestamp
  ).to.equal(true);

  const nftBid1 = await nftFactoryContract.getAuctionBid(nft.value, 1);
  expect(+nftBid1.value).to.equal(40000);
  expect(nftBid1.bidder).to.equal(user1.address);
  expect(nftBid1.meetReservePrice).to.equal(true);
  console.log("Test: check bidId 1, user1 bid: 35000 - 40000");

  const user3Balance0 = +(await araTokenContract.balanceOf(user3.address));
  console.log(user3Balance0);
  await expect(
    nftFactoryContract.connect(user3).bidAuction(nft.value, 30000, 39000)
  ).to.be.reverted;
  await nftFactoryContract.connect(user3).bidAuction(nft.value, 39000, 47000);

  const user3Balance1 = +(await araTokenContract.balanceOf(user3.address));
  expect(user1Balance0).to.equal(user1Balance1);

  // const user2Balance0 = +(await araTokenContract
  // expect((await nftFactoryContract.getAuction(nft.value)).bidder).to.equal(
  //   ethers.utils.getAddress(0x0)
  // );
  // console.log(nftResult0.auctions[0]);
  // expect(nftResult0.auctions[0].bidder).to.equal(0x0);

  // const nftBalance6 = +(await araTokenContract.balanceOf(
  //   nftFactoryContract.address
  // ));
  // console.log("Balance: nft ARA balance ", nftBalance6);
  // const user2Balance6 = +(await araTokenContract.balanceOf(user2.address));
  // console.log(user2Balance6);
  // await araTokenContract
  //   .connect(user2)
  //   .approve(nftFactoryContract.address, 2 ** 52);
  // await expect(nftFactoryContract.connect(user2).bidAuction(nft.value, 25601))
  //   .to.be.reverted;
  // console.log(
  //   "Bid: user2 try to bid 25601 but failed because less than minimum bid"
  // );
  // await nftFactoryContract.connect(user2).bidAuction(nft.value, 28160);
  // console.log("Bid: user2 bid 28160");
  // const user2Balance7 = +(await araTokenContract.balanceOf(user2.address));
  // console.log(
  //   "Balance: user2 (beforeBid, afterBid)",
  //   user2Balance6,
  //   user2Balance7,
  //   user2Balance7 - user2Balance6
  // );
  // const user1Balance8 = +(await araTokenContract.balanceOf(user1.address));
  // expect(user1Balance8).to.equal(user1Balance6);
  // console.log("Balance: user1 pass bid should be revert, ", user1Balance8);
  // expect(
  //   +(await araTokenContract.balanceOf(nftFactoryContract.address))
  // ).to.equal(28160);
  // console.log("Test: nft0 balance should be 28160");
  // await nftFactoryContract.connect(user2).bidAuction(nft.value, 31000);
  // const user2Balance8 = +(await araTokenContract.balanceOf(user2.address));
  // console.log("Bid: user2 increase bid to 31000");
  // console.log(
  //   "Balance: user2 balance (beforeBid, afterBid)",
  //   user2Balance6,
  //   user2Balance8,
  //   user2Balance8 - user2Balance6
  // );
  // const user4Balance6 = +(await araTokenContract.balanceOf(user3.address));
  // await araTokenContract
  //   .connect(user3)
  //   .approve(nftFactoryContract.address, 2 ** 52);
  // await nftFactoryContract.connect(user3).bidAuction(nft.value, 34500);
  // console.log("Bid: user4 bid 34500");
  // const user4Balance7 = +(await araTokenContract.balanceOf(user3.address));
  // console.log(
  //   "Balance user 4 (beforeBid, afterBid), ",
  //   user4Balance6,
  //   user4Balance7,
  //   user4Balance7 - user4Balance6
  // );
  // const user2Balance9 = +(await araTokenContract.balanceOf(user2.address));
  // expect(user2Balance9).to.equal(user2Balance6);
  // console.log(
  //   "Test: user2 balance should be revert to beforeBid ",
  //   user2Balance6
  // );

  // console.log("\n**** Process Auction");
  // expect(await nftFactoryContract.ownerOf(nft.value)).to.equal(
  //   nftFactoryContract.address
  // );
  // const bidValue10 = 34500;
  // const auctionData0 = await nftFactoryContract.getNFTAuction(nft.value);
  // expect(auctionData0.owner).to.equal(user2.address);
  // console.log("Test: before process owner of nft is smartcontract");
  // const referralBuyer = await memberContract.getReferral(user3.address);
  // const referralSeller = await memberContract.getReferral(user2.address);
  // expect(referralSeller).to.equal(root.address);
  // const referralSeller10Balance = +(await araTokenContract.balanceOf(
  //   referralSeller
  // ));
  // const referralBuyer10Balance = +(await araTokenContract.balanceOf(
  //   referralBuyer
  // ));
  // const custodian10Balance = +(await araTokenContract.balanceOf(
  //   custodian.address
  // ));
  // const founder10Balance = +(await araTokenContract.balanceOf(user1.address));
  // const managementFund10Balance = +(await araTokenContract.balanceOf(
  //   await governanceContract.getManagementFundContract()
  // ));

  // await ethers.provider.send("evm_increaseTime", [432000]);
  // await nftFactoryContract.processAuction(nft.value);
  // console.log("Process: Auction");

  // const referralBuyer11Balance = +(await araTokenContract.balanceOf(
  //   referralBuyer
  // ));
  // const referralSeller11Balance = +(await araTokenContract.balanceOf(
  //   referralSeller
  // ));
  // const custodian11Balance = +(await araTokenContract.balanceOf(
  //   custodian.address
  // ));
  // const founder11Balance = +(await araTokenContract.balanceOf(user1.address));
  // const managementFund11Balance = +(await araTokenContract.balanceOf(
  //   await governanceContract.getManagementFundContract()
  // ));
  // console.log(
  //   "Balance: referral seller ",
  //   referralSeller10Balance,
  //   referralSeller11Balance,
  //   referralSeller11Balance - referralSeller10Balance
  // );
  // expect(referralSeller11Balance - referralSeller10Balance).to.equal(
  //   Math.floor((bidValue10 * 2000) / 1000000)
  // );
  // console.log(
  //   "Balance: referral buyer ",
  //   referralBuyer10Balance,
  //   referralBuyer11Balance,
  //   referralBuyer11Balance - referralBuyer10Balance
  // );
  // expect(referralBuyer11Balance - referralBuyer10Balance).to.equal(
  //   Math.floor((bidValue10 * 2500) / 1000000)
  // );
  // console.log(
  //   "Balance: custodian ",
  //   custodian10Balance,
  //   custodian11Balance,
  //   custodian11Balance - custodian10Balance
  // );
  // expect(custodian11Balance - custodian10Balance).to.equal(
  //   Math.floor((bidValue10 * 25000) / 1000000)
  // );
  // console.log(
  //   "Balance: founder ",
  //   founder10Balance,
  //   founder11Balance,
  //   founder11Balance - founder10Balance
  // );
  // expect(founder11Balance - founder10Balance).to.equal(
  //   (bidValue10 * 100000) / 1000000
  // );
  // console.log(
  //   "Balance: ManagementFund ",
  //   managementFund10Balance,
  //   managementFund11Balance,
  //   managementFund11Balance - managementFund10Balance
  // );
  // expect(managementFund11Balance - managementFund10Balance).to.equal(
  //   Math.floor((bidValue10 * 22500) / 1000000)
  // );
  // expect(await nftFactoryContract.ownerOf(nft.value)).to.equal(user3.address);
  // console.log("Transfer: new owner of nft0 is user4");
};
