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

  const tokenId = +(await nftFactoryContract
    .connect(user1)
    .getCurrentTokenId());
  console.log("Current Token Id:", tokenId);

  await araTokenContract
    .connect(user1)
    .approve(nftFactoryContract.address, 2 ** 52);
  await araTokenContract
    .connect(user2)
    .approve(nftFactoryContract.address, 2 ** 52);

  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(
    nftFactoryContract.address
  );
  expect(await nftFactoryContract.tokenURI(tokenId)).to.equal(
    "https://example/metadata.json"
  );
  console.log("mint: lock nft in smart contract, tokenId: ", +tokenId);

  await nftFactoryContract
    .connect(custodian)
    .custodianSign(tokenId, 25000, 130430, 25000);
  console.log("sign: custodian sign");

  await araTokenContract
    .connect(user1)
    .approve(nftFactoryContract.address, 2 ** 52);
  await nftFactoryContract.connect(user1).payFeeAndClaimToken(tokenId);
  console.log("User1 pay fee and claim token");

  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(user1.address);
  console.log("Now user1 is owner of token0");

  await expect(nftFactoryContract.connect(user1).payFeeAndClaimToken(tokenId))
    .to.be.reverted;
  console.log("Test: user1 try to claim token again but failed");

  await nftFactoryContract
    .connect(user1)
    .transferFrom(user1.address, user2.address, tokenId);
  console.log("Transfer: user1 transfer nft token to user2");

  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(user2.address);
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
  tokenId: any
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
      .openAuction(tokenId, 432000, 25600, 40000, 1000000, 100000)
  ).to.be.reverted;
  console.log("Test: user3 try to open auction without owner permission.");

  const managementFundBalance0 = +(await araTokenContract.balanceOf(
    await governanceContract.getManagementFundContract()
  ));

  await nftFactoryContract
    .connect(user2)
    .openAuction(tokenId, 432000, 25600, 40000, 1000000, 100000);
  console.log("Process: Open nft0 auction");

  const managementFundBalance1 = +(await araTokenContract.balanceOf(
    await governanceContract.getManagementFundContract()
  ));
  expect(managementFundBalance1 - managementFundBalance0).to.equal(90000);
  console.log("Test: management fund should receive open fee.");
  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(
    nftFactoryContract.address
  );
  console.log("Test: nft move to escrow.");

  const user1Balance0 = +(await araTokenContract.balanceOf(user1.address));
  await nftFactoryContract.connect(user1).bidAuction(tokenId, 25600, 25700);
  const user1Balance1 = +(await araTokenContract.balanceOf(user1.address));
  expect(user1Balance0).to.equal(user1Balance1);
  console.log(
    "Bid: User1 bid 25600 - 25700 but less than reserve price, so user balance of user1 did not change."
  );
  const nftResult0 = await nftFactoryContract.nfts(tokenId);
  expect(nftResult0.bidId).to.equal(1);
  expect(nftResult0.totalAuction).to.equal(1);
  expect(nftResult0.status.auction).to.equal(true);

  const nftAuction0Result0 = await nftFactoryContract.getAuction(tokenId);
  expect(+nftAuction0Result0.value).to.equal(25700);
  expect(nftAuction0Result0.bidder).to.equal(user1.address);
  expect(nftAuction0Result0.reservePrice).to.equal(0);
  expect(nftAuction0Result0.maxBid).to.equal(0);
  expect(nftAuction0Result0.meetReservePrice).to.equal(false);

  const nftBid0 = await nftFactoryContract.getAuctionBid(tokenId, 0);
  expect(+nftBid0.value).to.equal(25700);
  expect(nftBid0.bidder).to.equal(user1.address);
  expect(nftBid0.meetReservePrice).to.equal(false);
  console.log("Test: check bidId 0");

  await nftFactoryContract.connect(user1).bidAuction(tokenId, 35000, 48000);
  const user1Balance2 = +(await araTokenContract.balanceOf(user1.address));
  expect(user1Balance2 - user1Balance0).to.equal(-48000);

  const nftResult1 = await nftFactoryContract.nfts(tokenId);
  expect(nftResult1.bidId).to.equal(2);
  expect(nftResult1.totalAuction).to.equal(1);
  expect(nftResult1.status.auction).to.equal(true);

  const nftAuction0Result1 = await nftFactoryContract.getAuction(tokenId);
  expect(+nftAuction0Result1.value).to.equal(40000);
  expect(nftAuction0Result1.bidder).to.equal(user1.address);
  expect(nftAuction0Result1.reservePrice).to.equal(40000);
  expect(nftAuction0Result1.maxBid).to.equal(0);
  expect(nftAuction0Result1.meetReservePrice).to.equal(true);
  expect(
    nftAuction0Result1.closeAuctionTimestamp <
    nftAuction0Result0.closeAuctionTimestamp
  ).to.equal(true);

  const nftBid1 = await nftFactoryContract.getAuctionBid(tokenId, 1);
  expect(+nftBid1.value).to.equal(40000);
  expect(nftBid1.bidder).to.equal(user1.address);
  expect(nftBid1.meetReservePrice).to.equal(true);
  console.log("Test: check bidId 1, user1 bid: 35000 - 40000");

  const user3Balance0 = +(await araTokenContract.balanceOf(user3.address));
  console.log(user3Balance0);
  await expect(
    nftFactoryContract.connect(user3).bidAuction(tokenId, 30000, 39000)
  ).to.be.reverted;
  await expect(
    nftFactoryContract.connect(user3).bidAuction(tokenId, 39000, 42000)
  ).to.be.reverted;
  console.log("Test: should revert because bid less than next step bid value.");
  await nftFactoryContract.connect(user3).bidAuction(tokenId, 39000, 47000);

  const user3Balance1 = +(await araTokenContract.balanceOf(user3.address));
  expect(user3Balance1).to.equal(user3Balance0);

  const nftBid2 = await nftFactoryContract.getAuctionBid(tokenId, 2);
  const nftBid3 = await nftFactoryContract.getAuctionBid(tokenId, 3);
  expect(nftBid2.value).to.equal(40000 * 1.1);
  expect(nftBid2.bidder).to.equal(user3.address);
  expect(nftBid2.meetReservePrice).to.equal(true);
  expect(nftBid2.autoRebid).to.equal(false);
  expect(nftBid3.value).to.equal(47000);
  expect(nftBid3.bidder).to.equal(user1.address);
  expect(nftBid3.meetReservePrice).to.equal(true);
  expect(nftBid3.autoRebid).to.equal(true);
  console.log("Test: auto rebid between user1 and user3");

  const nftAuction0Result2 = await nftFactoryContract.getAuction(tokenId);
  expect(nftAuction0Result2.bidder).to.equal(user1.address);
  expect(nftAuction0Result2.value).to.equal(47000);
  expect(nftAuction0Result2.maxBid).to.equal(0);
  expect(nftAuction0Result2.totalBid).to.equal(4);

  console.log("\n***** Bidding Competition");
  await nftFactoryContract.connect(user1).bidAuction(tokenId, 48000, 80000);
  const user1Balance3 = +(await araTokenContract.balanceOf(user1.address));
  expect(user1Balance3 - user1Balance0).to.equal(-80000);
  console.log("Bid: user1 increase max bid to 80000.");

  const nftAuction0Result3 = await nftFactoryContract.getAuction(tokenId);
  expect(nftAuction0Result3.bidder).to.equal(user1.address);
  expect(+nftAuction0Result3.value).to.equal(51700);

  await nftFactoryContract.connect(user2).bidAuction(tokenId, 60000, 60000);
  const nftAuction0Result4 = await nftFactoryContract.getAuction(tokenId);
  expect(nftAuction0Result4.bidder).to.equal(user1.address);
  expect(+nftAuction0Result4.value).to.equal(60000);

  await nftFactoryContract.connect(user3).bidAuction(tokenId, 70000, 75000);
  const nftAuction0Result5 = await nftFactoryContract.getAuction(tokenId);
  expect(nftAuction0Result5.bidder).to.equal(user1.address);
  expect(+nftAuction0Result5.value).to.equal(75000);

  await nftFactoryContract.connect(user3).bidAuction(tokenId, 90000, 100000);
  const nftAuction0Result6 = await nftFactoryContract.getAuction(tokenId);
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
    nftAuction0Result6.closeAuctionTimestamp - 200,
  ]);
  await nftFactoryContract.connect(user1).bidAuction(tokenId, 95000, 200000);
  const blockNumber1 = await ethers.provider.getBlockNumber();
  const block1 = await ethers.provider.getBlock(blockNumber1);
  console.log(
    "Block: current block",
    blockNumber1,
    "timestamp",
    block1.timestamp
  );
  const nftAuction0Result7 = await nftFactoryContract.getAuction(tokenId);
  expect(nftAuction0Result7.bidder).to.equal(user1.address);
  expect(+nftAuction0Result7.value).to.equal(99000);
  const user3Balance3 = +(await araTokenContract.balanceOf(user3.address));
  expect(user3Balance3 - user3Balance0).to.equal(0);
  const user1Balance5 = +(await araTokenContract.balanceOf(user1.address));
  expect(user1Balance5 - user1Balance0).to.equal(-200000);
  expect(nftAuction0Result6.closeAuctionTimestamp - block1.timestamp).to.equal(
    200
  );
  expect(nftAuction0Result7.closeAuctionTimestamp - block1.timestamp).to.equal(
    300
  );

  console.log("Test: remain auction timestamp");

  await expect(nftFactoryContract.processAuction(tokenId)).to.be.reverted;

  console.log("Test: process auction", tokenId);

  await ethers.provider.send("evm_increaseTime", [250]);
  await nftFactoryContract.connect(user2).bidAuction(tokenId, 130000, 150000);
  console.log("Test: bid auction");
  const nftAuction0Result8 = await nftFactoryContract.getAuction(tokenId);
  expect(nftAuction0Result8.bidder).to.equal(user1.address);
  expect(+nftAuction0Result8.value).to.equal(150000);
  console.log(
    "Ending bid competition user1 has won this auction with price 150000, user1 should receive an nft and remain of 50000"
  );

  await ethers.provider.send("evm_increaseTime", [700]);
  await expect(
    nftFactoryContract.connect(user2).bidAuction(tokenId, 130000, 150000)
  ).to.be.reverted;
  expect((await nftFactoryContract.nfts(tokenId)).bidId).to.equal(13);

  console.log("\n*** Process Auction");
  const nftInfo = await nftFactoryContract.nfts(tokenId);
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
  await nftFactoryContract.processAuction(tokenId);
  const nftAuction0Result9 = await nftFactoryContract.getAuction(tokenId);
  expect(nftAuction0Result9.bidder).to.equal(user1.address);
  expect(nftAuction0Result9.value).to.equal(150000);
  expect(nftAuction0Result9.meetReservePrice).to.equal(true);
  expect(nftAuction0Result9.maxBid).to.equal(200000);
  console.log("Test: check auction result.");

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
  console.log("Test: calculate fee for each parties.");
};

export const testAuctionNFTWithNoBid = async (
  ethers: any,
  nftFactoryContract: any,
  araTokenContract: any,
  auditor: any,
  custodian: any,
  user1: any
) => {
  console.log("\n*** Test auction with no bid");

  await araTokenContract
    .connect(user1)
    .approve(nftFactoryContract.address, 2 ** 52);

  await nftFactoryContract
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
  const tokenId = +(await nftFactoryContract.getCurrentTokenId());
  console.log("TokenId:", tokenId);
  await nftFactoryContract
    .connect(custodian)
    .custodianSign(tokenId, 25000, 130430, 25000);

  await nftFactoryContract.connect(user1).payFeeAndClaimToken(tokenId);
  console.log("Mint: nft");

  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(user1.address);
  await nftFactoryContract
    .connect(user1)
    .openAuction(tokenId, 864000, 100000, 0, 1000000, 100000);
  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(
    nftFactoryContract.address
  );

  await ethers.provider.send("evm_increaseTime", [865000]);
  await nftFactoryContract.processAuction(tokenId);
  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(user1.address);
  console.log(
    "Auction: open auction with now bid, nft should be revert to owner"
  );
};

export const testAuctionNFTWithBidButNotMeetReservePrice = async (
  ethers: any,
  nftFactoryContract: any,
  araTokenContract: any,
  auditor: any,
  custodian: any,
  user1: any,
  user2: any
) => {
  console.log("\n*** Test auction with bid but not meet reserve price");

  await araTokenContract
    .connect(user1)
    .approve(nftFactoryContract.address, 2 ** 52);

  await nftFactoryContract
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
  const tokenId = +(await nftFactoryContract.getCurrentTokenId());
  console.log("TokenId:", tokenId);
  await nftFactoryContract
    .connect(custodian)
    .custodianSign(tokenId, 25000, 130430, 25000);

  await nftFactoryContract.connect(user1).payFeeAndClaimToken(tokenId);
  console.log("Mint: nft");

  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(user1.address);
  await nftFactoryContract
    .connect(user1)
    .openAuction(tokenId, 864000, 100000, 300000, 1000000, 100000);
  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(
    nftFactoryContract.address
  );

  await expect(
    nftFactoryContract.connect(user2).bidAuction(tokenId, 80000, 80000)
  ).to.be.reverted;

  expect(
    await nftFactoryContract.connect(user2).bidAuction(tokenId, 80000, 150000)
  );

  await ethers.provider.send("evm_increaseTime", [865000]);
  await nftFactoryContract.processAuction(tokenId);
  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(user1.address);
  console.log(
    "Auction: open auction with now bid, nft should be revert to owner"
  );
};

export const testNFTBuyItNow = async (
  ethers: any,
  nftFactoryContract: any,
  araTokenContract: any,
  governanceContract: any,
  memberContract: any,
  auditor: any,
  custodian: any,
  user1: any,
  user2: any
) => {
  console.log("\n*** Test buy it now nft");

  await araTokenContract
    .connect(user1)
    .approve(nftFactoryContract.address, 2 ** 52);

  await nftFactoryContract
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
  const tokenId = +(await nftFactoryContract.getCurrentTokenId());
  console.log("TokenId:", tokenId);
  await nftFactoryContract
    .connect(custodian)
    .custodianSign(tokenId, 25000, 130430, 25000);

  await nftFactoryContract.connect(user1).payFeeAndClaimToken(tokenId);
  console.log("Mint: nft");

  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(user1.address);
  const user1Balance0 = +(await araTokenContract.balanceOf(user1.address));
  const platformBalance0 = +(await araTokenContract.balanceOf(
    await governanceContract.getManagementFundContract()
  ));
  const referralBuyerBalance0 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user2.address)
  ));
  const referralSellerBalance0 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user1.address)
  ));
  const custodianBalance0 = +(await araTokenContract.balanceOf(
    custodian.address
  ));
  console.log("Balance: user1", user1Balance0);
  await nftFactoryContract.connect(user1).openBuyItNow(tokenId, 30000);
  console.log("Open buy it now");
  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(
    nftFactoryContract.address
  );
  expect((await nftFactoryContract.nfts(tokenId)).buyItNow.value).to.equal(
    30000
  );
  expect((await nftFactoryContract.nfts(tokenId)).buyItNow.owner).to.equal(
    user1.address
  );
  expect((await nftFactoryContract.nfts(tokenId)).status.buyItNow).to.equal(
    true
  );
  const user1Balance1 = +(await araTokenContract.balanceOf(user1.address));
  const platformBalance1 = +(await araTokenContract.balanceOf(
    await governanceContract.getManagementFundContract()
  ));
  const referralBuyerBalance1 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user2.address)
  ));
  const referralSellerBalance1 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user1.address)
  ));
  const custodianBalance1 = +(await araTokenContract.balanceOf(
    custodian.address
  ));
  expect(user1Balance1 - user1Balance0).to.equal(-11000);
  expect(referralSellerBalance1 - referralSellerBalance0).to.equal(1000);
  expect(platformBalance1 - platformBalance0).to.equal(10000);
  console.log("Test: open buy it now fee.");

  await nftFactoryContract.connect(user1).changeBuyItNowPrice(tokenId, 35000);
  expect((await nftFactoryContract.nfts(tokenId)).buyItNow.value).to.equal(
    35000
  );
  console.log("Test: change buy it now price to 35000.");

  const user2Balance1 = +(await araTokenContract.balanceOf(user2.address));
  await nftFactoryContract.connect(user2).buyFromBuyItNow(tokenId);
  console.log("Buy: buy from buy it now.");
  const user2Balance2 = +(await araTokenContract.balanceOf(user2.address));
  const user1Balance2 = +(await araTokenContract.balanceOf(user1.address));
  const platformBalance2 = +(await araTokenContract.balanceOf(
    await governanceContract.getManagementFundContract()
  ));
  const referralBuyerBalance2 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user2.address)
  ));
  const referralSellerBalance2 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user1.address)
  ));
  const custodianBalance2 = +(await araTokenContract.balanceOf(
    custodian.address
  ));
  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(user2.address);
  expect((await nftFactoryContract.nfts(tokenId)).status.buyItNow).to.equal(
    false
  );
  expect(user2Balance2 - user2Balance1).to.equal(-35000);
  expect(platformBalance2 - platformBalance1).to.equal(
    Math.floor(35000 * 0.0225)
  );
  expect(referralBuyerBalance2 - referralBuyerBalance1).to.equal(
    Math.floor(35000 * 0.0025)
  );
  expect(referralSellerBalance2 - referralSellerBalance1).to.equal(
    Math.floor(35000 * 0.002)
  );
  expect(custodianBalance2 - custodianBalance1).to.equal(
    Math.floor(35000 * 0.025)
  );
  expect(user1Balance2 - user1Balance1).to.equal(33181);
  console.log("Test: check fee");

  await nftFactoryContract.connect(user2).openBuyItNow(tokenId, 40000);
  await nftFactoryContract.connect(user2).closeBuyItNow(tokenId);
  console.log("Test: close buy it now.");
};

export const testNFTOffer = async (
  ethers: any,
  nftFactoryContract: any,
  araTokenContract: any,
  governanceContract: any,
  memberContract: any,
  auditor: any,
  custodian: any,
  user1: any,
  user2: any,
  user3: any
) => {
  console.log("\n*** Test nft offer price");

  await araTokenContract
    .connect(user1)
    .approve(nftFactoryContract.address, 2 ** 52);

  await nftFactoryContract
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
  const tokenId = +(await nftFactoryContract.getCurrentTokenId());
  console.log("TokenId:", tokenId);
  await nftFactoryContract
    .connect(custodian)
    .custodianSign(tokenId, 25000, 130430, 25000);

  await nftFactoryContract.connect(user1).payFeeAndClaimToken(tokenId);
  console.log("Mint: nft");

  const user1Balance0 = +(await araTokenContract.balanceOf(user1.address));
  const user2Balance0 = +(await araTokenContract.balanceOf(user2.address));
  expect((await nftFactoryContract.nfts(tokenId)).status.offer).to.equal(false);

  await nftFactoryContract.connect(user2).openOffer(30000, tokenId);
  console.log("Test: user2 open offer 30000");
  const user2Balance1 = +(await araTokenContract.balanceOf(user2.address));
  expect(user2Balance1 - user2Balance0).to.equal(-30000);
  const nftOffer0 = (await nftFactoryContract.nfts(tokenId)).offer;
  expect(nftOffer0.bidder).to.equal(user2.address);
  expect(nftOffer0.value).to.equal(30000);
  expect((await nftFactoryContract.nfts(tokenId)).status.offer).to.equal(true);

  const user3Balance0 = +(await araTokenContract.balanceOf(user3.address));
  await nftFactoryContract.connect(user3).openOffer(40000, tokenId);
  console.log("Test: user3 open offer 40000");
  const user3Balance1 = +(await araTokenContract.balanceOf(user3.address));
  const user2Balance2 = +(await araTokenContract.balanceOf(user2.address));
  expect(user3Balance1 - user3Balance0).to.equal(-40000);
  const nftOffer1 = (await nftFactoryContract.nfts(tokenId)).offer;
  expect(nftOffer1.bidder).to.equal(user3.address);
  expect(nftOffer1.value).to.equal(40000);
  console.log("Check: balance user2");
  console.log(user2Balance2, user2Balance0, user2Balance2 - user2Balance0);
  expect(Math.floor(user2Balance2 - user2Balance0)).to.equal(0);
  console.log("Pass: check balance equal 0");

  expect((await nftFactoryContract.nfts(tokenId)).status.offer).to.equal(true);
  await nftFactoryContract.connect(user3).revertOffer(tokenId);
  expect((await nftFactoryContract.nfts(tokenId)).status.offer).to.equal(false);
  const user3Balance2 = +(await araTokenContract.balanceOf(user3.address));
  console.log("Check: balance user3");
  console.log(user3Balance2, user3Balance0, user3Balance2 - user3Balance0);
  expect(Math.floor(user3Balance2 - user3Balance0)).to.equal(0);
  console.log("Test: revert offer by bidder.");

  await nftFactoryContract.connect(user3).openOffer(40000, tokenId);
  console.log("Offer: user3 open an offer.");
  await nftFactoryContract.connect(user1).revertOffer(tokenId);
  expect((await nftFactoryContract.nfts(tokenId)).status.offer).to.equal(false);
  console.log("Test: revert offer by owner.");

  await nftFactoryContract.connect(user3).openOffer(40000, tokenId);
  await ethers.provider.send("evm_increaseTime", [86500000]);
  await nftFactoryContract.connect(user2).revertOffer(tokenId);
  expect((await nftFactoryContract.nfts(tokenId)).status.offer).to.equal(false);
  console.log("Test: revert offer by public after expired.");

  const user1Balance3 = +(await araTokenContract.balanceOf(user1.address));
  const user3Balance3 = +(await araTokenContract.balanceOf(user3.address));
  const platformBalance3 = +(await araTokenContract.balanceOf(
    await governanceContract.getManagementFundContract()
  ));
  const referralBuyerBalance3 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user3.address)
  ));
  const referralSellerBalance3 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user1.address)
  ));
  const custodianBalance3 = +(await araTokenContract.balanceOf(
    custodian.address
  ));

  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(user1.address);
  await nftFactoryContract.connect(user3).openOffer(40000, tokenId);
  await nftFactoryContract.connect(user1).acceptOffer(tokenId);
  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(user3.address);
  expect((await nftFactoryContract.nfts(tokenId)).status.offer).to.equal(false);
  console.log("Test: user 3 offer 40000, owner accept.");

  const user1Balance4 = +(await araTokenContract.balanceOf(user1.address));
  const user3Balance4 = +(await araTokenContract.balanceOf(user3.address));
  const platformBalance4 = +(await araTokenContract.balanceOf(
    await governanceContract.getManagementFundContract()
  ));
  const referralBuyerBalance4 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user3.address)
  ));
  const referralSellerBalance4 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user1.address)
  ));
  const custodianBalance4 = +(await araTokenContract.balanceOf(
    custodian.address
  ));

  expect(user3Balance4 - user3Balance0).to.equal(-40000);
  expect(platformBalance4 - platformBalance3).to.equal(40000 * 0.0225);
  expect(referralBuyerBalance4 - referralBuyerBalance3).to.equal(
    40000 * 0.0025
  );
  expect(referralSellerBalance4 - referralSellerBalance3).to.equal(
    40000 * 0.002
  );
  expect(custodianBalance4 - custodianBalance3).to.equal(40000 * 0.025);
  expect(user1Balance4 - user1Balance3).to.equal(37920);
  console.log("Test: calculate fees.");
};

export const testNFTTransfer = async (
  ethers: any,
  nftFactoryContract: any,
  araTokenContract: any,
  governanceContract: any,
  memberContract: any,
  auditor: any,
  custodian: any,
  user1: any,
  user2: any,
  user3: any
) => {
  console.log("\n**** Test transfer nft");

  await araTokenContract
    .connect(user1)
    .approve(nftFactoryContract.address, 2 ** 52);

  await nftFactoryContract
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
  const tokenId = +(await nftFactoryContract.getCurrentTokenId());
  console.log("TokenId:", tokenId);
  await nftFactoryContract
    .connect(custodian)
    .custodianSign(tokenId, 25000, 1430, 25000);

  await nftFactoryContract.connect(user1).payFeeAndClaimToken(tokenId);
  console.log("Mint: nft");

  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(user1.address);
  const user1Balance0 = +(await araTokenContract.balanceOf(user1.address));
  const platformBalance0 = +(await araTokenContract.balanceOf(
    await governanceContract.getManagementFundContract()
  ));
  const referralReceiverBalance0 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user2.address)
  ));
  const referralSenderBalance0 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user1.address)
  ));
  const custodianBalance0 = +(await araTokenContract.balanceOf(
    custodian.address
  ));

  await nftFactoryContract
    .connect(user1)
    .transferFrom(user1.address, user2.address, tokenId);
  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(user2.address);
  console.log("Transfer: user1 to user2");

  const user1Balance1 = +(await araTokenContract.balanceOf(user1.address));
  const platformBalance1 = +(await araTokenContract.balanceOf(
    await governanceContract.getManagementFundContract()
  ));
  const referralReceiverBalance1 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user2.address)
  ));
  const referralSenderBalance1 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user1.address)
  ));
  const custodianBalance1 = +(await araTokenContract.balanceOf(
    custodian.address
  ));
  expect(platformBalance1 - platformBalance0).to.equal(1000);
  console.log("Test: platform fee");
  expect(referralReceiverBalance1 - referralReceiverBalance0).to.equal(1000);
  console.log("Test: referral receiver fee");
  expect(referralSenderBalance1 - referralSenderBalance0).to.equal(1000);
  console.log("Test: referral sender fee");
  expect(custodianBalance1 - custodianBalance0).to.equal(1430);
  console.log("Test: custodian fee");

  await nftFactoryContract.connect(user2).openBuyItNow(tokenId, 1000000);
  await nftFactoryContract.connect(user3).buyFromBuyItNow(tokenId);
  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(user3.address);
  console.log("Buy: set new current price by buy it now.");

  const user3Balance2 = +(await araTokenContract.balanceOf(user3.address));
  const platformBalance2 = +(await araTokenContract.balanceOf(
    await governanceContract.getManagementFundContract()
  ));
  const referralReceiverBalance2 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user2.address)
  ));
  const referralSenderBalance2 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user3.address)
  ));
  const custodianBalance2 = +(await araTokenContract.balanceOf(
    custodian.address
  ));
  await nftFactoryContract
    .connect(user3)
    .transferFrom(user3.address, user2.address, tokenId);
  console.log("Transfer: user 3 to user2");
  const user3Balance3 = +(await araTokenContract.balanceOf(user3.address));
  const platformBalance3 = +(await araTokenContract.balanceOf(
    await governanceContract.getManagementFundContract()
  ));
  const referralReceiverBalance3 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user2.address)
  ));
  const referralSenderBalance3 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user3.address)
  ));
  const custodianBalance3 = +(await araTokenContract.balanceOf(
    custodian.address
  ));
  expect(platformBalance3 - platformBalance2).to.equal(1000000 * 0.0225);
  console.log("Test: platform fee");
  expect(referralReceiverBalance3 - referralReceiverBalance2).to.equal(
    1000000 * 0.0025
  );
  console.log("Test: referral receiver fee");
  expect(referralSenderBalance3 - referralSenderBalance2).to.equal(
    1000000 * 0.002
  );
  console.log("Test: referral sender fee");
  expect(custodianBalance3 - custodianBalance2).to.equal(1000000 * 0.025);
  console.log("Test: custodian fee");
};

export const testNFTRedeem = async (
  ethers: any,
  nftFactoryContract: any,
  araTokenContract: any,
  governanceContract: any,
  memberContract: any,
  auditor: any,
  custodian: any,
  user1: any,
  user2: any
) => {
  console.log("\n**** Test redeem nft");

  await araTokenContract
    .connect(user1)
    .approve(nftFactoryContract.address, 2 ** 52);

  await nftFactoryContract
    .connect(auditor)
    .mint(
      user2.address,
      custodian.address,
      "https://example/metadata.json",
      1000000,
      100000,
      300000,
      3500,
      1000
    );
  const tokenId = +(await nftFactoryContract.getCurrentTokenId());
  console.log("TokenId:", tokenId);
  await nftFactoryContract
    .connect(custodian)
    .custodianSign(tokenId, 25000, 1430, 25000);

  await nftFactoryContract.connect(user2).payFeeAndClaimToken(tokenId);
  console.log("Mint: nft");

  await nftFactoryContract
    .connect(user2)
    .transferFrom(user2.address, user1.address, tokenId);

  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(user1.address);

  const founderBalance0 = +(await araTokenContract.balanceOf(user2.address));
  const platformBalance0 = +(await araTokenContract.balanceOf(
    await governanceContract.getManagementFundContract()
  ));
  const referralBalance0 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user1.address)
  ));
  const custodianBalance0 = +(await araTokenContract.balanceOf(
    custodian.address
  ));

  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(user1.address);

  const user1Balance0 = +(await araTokenContract.balanceOf(user1.address));
  await nftFactoryContract.connect(user1).redeem(tokenId);
  expect((await nftFactoryContract.nfts(tokenId)).status.redeem).to.equal(true);
  expect((await nftFactoryContract.nfts(tokenId)).addr.owner).to.equal(
    user1.address
  );
  expect(
    +(await araTokenContract.balanceOf(nftFactoryContract.address))
  ).to.equal(6930);
  console.log("Test: redeem");

  const user1Balance1 = +(await araTokenContract.balanceOf(user1.address));
  expect(user1Balance1 < user1Balance0).to.equal(true);

  await ethers.provider.send("evm_increaseTime", [60480000]);
  await nftFactoryContract.connect(user1).revertRedeem(tokenId);
  const user1Balance2 = +(await araTokenContract.balanceOf(user1.address));

  expect(user1Balance2).to.equal(user1Balance0);
  console.log("Test: redeem");

  console.log("Redeem again");
  await nftFactoryContract.connect(user1).redeem(tokenId);
  console.log("Custodian: sign redeem");
  await nftFactoryContract.connect(custodian).redeemCustodianSign(tokenId);
  console.log("Freeze token");
  const nftResult0 = await nftFactoryContract.nfts(tokenId);
  expect(nftResult0.status.freeze).to.equal(true);

  const founderBalance1 = +(await araTokenContract.balanceOf(user2.address));
  const platformBalance1 = +(await araTokenContract.balanceOf(
    await governanceContract.getManagementFundContract()
  ));
  const referralBalance1 = +(await araTokenContract.balanceOf(
    await memberContract.getReferral(user1.address)
  ));
  const custodianBalance1 = +(await araTokenContract.balanceOf(
    custodian.address
  ));

  expect(await nftFactoryContract.ownerOf(tokenId)).to.equal(
    nftFactoryContract.address
  );

  expect(founderBalance1 - founderBalance0).to.equal(3500);
  expect(platformBalance1 - platformBalance0).to.equal(1000);
  expect(referralBalance1 - referralBalance0).to.equal(1000);
  expect(custodianBalance1 - custodianBalance0).to.equal(1430);

  await expect(
    nftFactoryContract
      .connect(user1)
      .transferFrom(user1.address, user2.address, tokenId)
  ).to.be.reverted;

  await expect(
    nftFactoryContract
      .connect(user1)
      .openAuction(tokenId, 86400, 10000, 20000, 1000000, 10000)
  ).to.be.reverted;

  await expect(nftFactoryContract.connect(user1).openBuyItNow(tokenId, 10000))
    .to.be.reverted;

  await expect(nftFactoryContract.connect(user2).openOffer(10000, tokenId)).to
    .be.reverted;
};
