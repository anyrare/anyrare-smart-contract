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
      3000000,
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
  console.log(
    await nftFactoryContract.connect(user1).payFeeAndClaimToken(nft.value)
  );
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
