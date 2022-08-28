const { deployContract } = require("../scripts/deploy.js");

const { expect } = require("chai");

describe("Test Asset Contract", async () => {
  let contract,
    root,
    user1,
    user2,
    manager,
    operation,
    auditor,
    custodian,
    founder;

  before(async () => {
    [root, user1, user2, manager, operation, auditor, custodian] =
      await ethers.getSigners();
    contract = await deployContract();

    await contract.araFacet.connect(root).transfer(user1.address, 500000);
  });

  it("should test function mintAsset", async () => {
    const tx = await contract.assetFactoryFacet.connect(auditor).mintAsset({
      founder: user1.address,
      custodian: custodian.address,
      tokenURI: "ipfs://metadata/123",
      maxWeight: 1000000,
      founderWeight: 100000,
      founderRedeemWeight: 300000,
      founderGeneralFee: 10000000,
      auditFee: 10000,
      custodianWeight: 10000,
      custodianRedeemWeight: 30000,
      custodianGeneralFee: 30000000,
    });
    const result = await tx.wait();

    const totalAsset = await contract.assetFacet.totalAsset();
    expect(totalAsset).equal(1);

    const owner = await contract.assetFacet.ownerOf(0);
    expect(owner).equal(auditor.address);
  });

  it("should test function custodianSign", async () => {
    await contract.assetFactoryFacet.connect(custodian).custodianSign(0);
  });

  it("should test function payFeeAndClaimToken", async () => {
    const balance0 = await contract.araFacet.balanceOf(user1.address);
    await contract.araFacet
      .connect(user1)
      .approve(contract.anyrareDiamond.address, 2 ** 52);
    await contract.assetFactoryFacet.connect(user1).payFeeAndClaimToken(0);

    const ownerOfToken = await contract.assetFacet.ownerOf(0);
    expect(ownerOfToken).equal(user1.address);
    const balance1 = await contract.araFacet.balanceOf(user1.address);
    expect(+balance1 < +balance0).equal(true);
  });

  it("should test function openAuction", async () => {
    await contract.assetFactoryFacet.connect(user1).openAuction(
      0,
      1000,
      10,
      300,
      1000000,
      10000
    );

    const owner = await contract.assetFacet.ownerOf(0);
    expect(owner).equal(contract.anyrareDiamond.address);
  });

  // TODO: Test bid auction
});
