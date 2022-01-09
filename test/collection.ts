import { expect } from "chai";

export const testCreateCollection = async (
  ethers: any,
  nftFactoryContract: any,
  collectionFactoryContract: any,
  araTokenContract: any,
  memberContract: any,
  governanceContract: any,
  user1: any,
  user2: any,
  user3: any,
  user4: any,
  auditor: any,
  custodian: any
) => {
  console.log("\n*** Collection");

  const nfts = [];

  for (let i = 0; i < 4; i++) {
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

    const tokenId = +(await nftFactoryContract
      .connect(user1)
      .getCurrentTokenId());
    nfts.push(tokenId);
    await nftFactoryContract
      .connect(custodian)
      .custodianSign(tokenId, 25000, 130430, 25000);

    await nftFactoryContract.connect(user1).payFeeAndClaimToken(tokenId);
    // await nftFactoryContract
    // .connect(user1)
    // .approve(collectionFactoryContract.address, tokenId);
  }

  console.log("Mint: 4 nfts", nfts);

  await nftFactoryContract
    .connect(user1)
    .setApprovalForAll(collectionFactoryContract.address, true);

  await collectionFactoryContract
    .connect(user1)
    .mint("LP Collection 001", "cARA1", 100000, 4, nfts);
  console.log("Mint: Collection0");

  const collection0 = await collectionFactoryContract.collections(0);
  console.log(collection0);
  expect(await nftFactoryContract.ownerOf(nfts[0])).to.equal(collection0);
  expect(await nftFactoryContract.ownerOf(nfts[1])).to.equal(collection0);
  expect(await nftFactoryContract.ownerOf(nfts[2])).to.equal(collection0);
  expect(await nftFactoryContract.ownerOf(nfts[3])).to.equal(collection0);
  console.log("Test: owner of 4 nfts is collection0");

  const collection0Contract = await collectionFactoryContract.t(collection0);

  console.log(collection0Contract);
};
