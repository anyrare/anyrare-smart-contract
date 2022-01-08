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
  await araTokenContract
    .connect(user2)
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
  user1: any,
  user2: any,
  user3: any,
  nft: any
) => {
  console.log("\n**** NFT Auction");
  console.log(await memberContract.isMember(user2.address));
  console.log(user2.address);

  await araTokenContract
    .connect(user1)
    .approve(nftFactoryContract.address, 2 ** 52);
  await araTokenContract
    .connect(user2)
    .approve(nftFactoryContract.address, 2 ** 52);
  await araTokenContract
    .connect(user3)
    .approve(nftFactoryContract.address, 2 ** 52);
  console.log("Allowance: user1, user2, user3 to nftContract");

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
  await expect(
    nftFactoryContract.connect(user3).bidAuction(nft.value, 39000, 42000)
  ).to.be.reverted;
  console.log("Test: should revert because bid less than next step bid value.");
  await nftFactoryContract.connect(user3).bidAuction(nft.value, 39000, 47000);

  const user3Balance1 = +(await araTokenContract.balanceOf(user3.address));
  expect(user3Balance1).to.equal(user3Balance0);

  const nftBid2 = await nftFactoryContract.getAuctionBid(nft.value, 2);
  const nftBid3 = await nftFactoryContract.getAuctionBid(nft.value, 3);
  expect(nftBid2.value).to.equal(40000 * 1.1);
  expect(nftBid2.bidder).to.equal(user3.address);
  expect(nftBid2.meetReservePrice).to.equal(true);
  expect(nftBid2.autoRebid).to.equal(false);
  expect(nftBid3.value).to.equal(47000);
  expect(nftBid3.bidder).to.equal(user1.address);
  expect(nftBid3.meetReservePrice).to.equal(true);
  expect(nftBid3.autoRebid).to.equal(true);
  console.log("Test: auto rebid between user1 and user3");

  const nftAuction0Result2 = await nftFactoryContract.getAuction(nft.value);
  expect(nftAuction0Result2.bidder).to.equal(user1.address);
  expect(nftAuction0Result2.value).to.equal(47000);
  expect(nftAuction0Result2.maxBid).to.equal(0);
  expect(nftAuction0Result2.totalBid).to.equal(4);

  console.log("\n***** Bidding Competition");
  await nftFactoryContract.connect(user1).bidAuction(nft.value, 48000, 80000);
  const user1Balance3 = +(await araTokenContract.balanceOf(user1.address));
  expect(user1Balance3 - user1Balance0).to.equal(-80000);
  console.log("Bid: user1 increase max bid to 80000.");

  const nftAuction0Result3 = await nftFactoryContract.getAuction(nft.value);
  expect(nftAuction0Result3.bidder).to.equal(user1.address);
  expect(+nftAuction0Result3.value).to.equal(51700);

  await nftFactoryContract.connect(user2).bidAuction(nft.value, 60000, 60000);
  const nftAuction0Result4 = await nftFactoryContract.getAuction(nft.value);
  expect(nftAuction0Result4.bidder).to.equal(user1.address);
  expect(+nftAuction0Result4.value).to.equal(60000);

  await nftFactoryContract.connect(user3).bidAuction(nft.value, 70000, 75000);
  const nftAuction0Result5 = await nftFactoryContract.getAuction(nft.value);
  expect(nftAuction0Result5.bidder).to.equal(user1.address);
  expect(+nftAuction0Result5.value).to.equal(75000);

  await nftFactoryContract.connect(user3).bidAuction(nft.value, 90000, 100000);
  const nftAuction0Result6 = await nftFactoryContract.getAuction(nft.value);
  expect(nftAuction0Result6.bidder).to.equal(user3.address);
  expect(+nftAuction0Result6.value).to.equal(90000);
  const user3Balance2 = +(await araTokenContract.balanceOf(user3.address));
  expect(user3Balance2 - user3Balance0).to.equal(-100000);
  const user1Balance4 = +(await araTokenContract.balanceOf(user1.address));
  expect(user1Balance4).to.equal(user1Balance0);

  const blockNumber0 = await ethers.provider.getBlockNumber();
  const block0 = await ethers.provider.getBlock(blockNumber0);
  console.log(
    "Block: current block",
    blockNumber0,
    "timestamp",
    block0.timestamp
  );
  console.log(
    "Time: auction time left ",
    nftAuction0Result6.closeAuctionTimestamp - block0.timestamp
  );
  expect(nftAuction0Result6.closeAuctionTimestamp).to.equal(
    nftAuction0Result5.closeAuctionTimestamp
  );

  await ethers.provider.send("evm_setNextBlockTimestamp", [
    nftAuction0Result6.closeAuctionTimestamp - 500,
  ]);
  await nftFactoryContract.connect(user1).bidAuction(nft.value, 95000, 200000);
  const blockNumber1 = await ethers.provider.getBlockNumber();
  const block1 = await ethers.provider.getBlock(blockNumber1);
  console.log(
    "Block: current block",
    blockNumber1,
    "timestamp",
    block1.timestamp
  );
  const nftAuction0Result7 = await nftFactoryContract.getAuction(nft.value);
  expect(nftAuction0Result7.bidder).to.equal(user1.address);
  expect(+nftAuction0Result7.value).to.equal(99000);
  const user3Balance3 = +(await araTokenContract.balanceOf(user3.address));
  expect(user3Balance3 - user3Balance0).to.equal(0);
  const user1Balance5 = +(await araTokenContract.balanceOf(user1.address));
  expect(user1Balance5 - user1Balance0).to.equal(-200000);
  expect(nftAuction0Result6.closeAuctionTimestamp - block1.timestamp).to.equal(
    500
  );
  expect(nftAuction0Result7.closeAuctionTimestamp - block1.timestamp).to.equal(
    600
  );

  await expect(nftFactoryContract.processAuction(nft.value)).to.be.reverted;

  await ethers.provider.send("evm_increaseTime", [550]);
  await nftFactoryContract.connect(user2).bidAuction(nft.value, 130000, 150000);
  const nftAuction0Result8 = await nftFactoryContract.getAuction(nft.value);
  expect(nftAuction0Result8.bidder).to.equal(user1.address);
  expect(+nftAuction0Result8.value).to.equal(150000);
  console.log(
    "Ending bid competition user1 has won this auction with price 150000, user1 should receive an nft and remain of 50000"
  );

  await ethers.provider.send("evm_increaseTime", [700]);
  await expect(
    nftFactoryContract.connect(user2).bidAuction(nft.value, 130000, 150000)
  ).to.be.reverted;
  expect((await nftFactoryContract.nfts(nft.value)).bidId).to.equal(13);

  console.log("\n*** Process Auction");
  const nftInfo = await nftFactoryContract.nfts(nft.value);
  const founderBalance0 = +(await araTokenContract.balanceOf(
    nftInfo.addr.founder
  ));
  const platformBalance0 = +(await araTokenContract.balanceOf(
    governanceContract.getManagementFundContract()
  ));
  const referralSellerBalance0 = +(await araTokenContract.balanceOf(
    memberContract.getReferral(nftAuction0Result8.owner)
  ));
  const referralBuyerBalance0 = +(await araTokenContract.balanceOf(
    memberContract.getReferral(user1.address)
  ));
  const ownerBalance0 = +(await araTokenContract.balanceOf(
    nftAuction0Result8.owner
  ));
  const custodianBalance0 = +(await araTokenContract.balanceOf(
    nftInfo.addr.custodian
  ));

  expect(
    +(await araTokenContract.balanceOf(nftFactoryContract.address))
  ).to.equal(200000);
  await nftFactoryContract.processAuction(nft.value);
  const nftAuction0Result9 = await nftFactoryContract.getAuction(nft.value);
  expect(nftAuction0Result9.bidder).to.equal(user1.address);
  expect(nftAuction0Result9.value).to.equal(150000);
  expect(nftAuction0Result9.meetReservePrice).to.equal(true);
  expect(nftAuction0Result9.maxBid).to.equal(200000);
  expect(
    +(await araTokenContract.balanceOf(nftFactoryContract.address))
  ).to.equal(0);
  const user1Balance6 = +(await araTokenContract.balanceOf(user1.address));
  expect(user1Balance6 - user1Balance0).to.equal(-150000);

  const founderBalance1 = +(await araTokenContract.balanceOf(
    nftInfo.addr.founder
  ));
  const platformBalance1 = +(await araTokenContract.balanceOf(
    governanceContract.getManagementFundContract()
  ));
  const referralSellerBalance1 = +(await araTokenContract.balanceOf(
    memberContract.getReferral(nftAuction0Result8.owner)
  ));
  const referralBuyerBalance1 = +(await araTokenContract.balanceOf(
    memberContract.getReferral(user1.address)
  ));
  const ownerBalance1 = +(await araTokenContract.balanceOf(
    nftAuction0Result8.owner
  ));
  const custodianBalance1 = +(await araTokenContract.balanceOf(
    nftInfo.addr.custodian
  ));

  expect(founderBalance1 - founderBalance0).to.equal(150000 * 0.1);
  expect(platformBalance1 - platformBalance0).to.equal(150000 * 0.0225);
  expect(referralBuyerBalance1 - referralBuyerBalance0).to.equal(
    150000 * 0.0025
  );
  expect(referralSellerBalance1 - referralSellerBalance0).to.equal(
    150000 * 0.002
  );
  expect(custodianBalance1 - custodianBalance0).to.equal(150000 * 0.025);
  expect(ownerBalance1 - ownerBalance0).to.equal(127200);
};
