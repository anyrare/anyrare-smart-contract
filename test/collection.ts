import { expect } from "chai";

export const testInitialCollection = async (
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
  }

  console.log("\n Mint: 4 nfts");

  await collectionTokenContract.connect(user1);
};
