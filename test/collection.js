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

  it("should test function mintAssets", async () => {
    const tx0 = await contract.assetFactoryFacet.connect(auditor).mintAsset({
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
    await tx0.wait();

    const tx1 = await contract.assetFactoryFacet.connect(auditor).mintAsset({
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
    await tx1.wait();

    const tx2 = await contract.assetFactoryFacet.connect(auditor).mintAsset({
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
    await tx2.wait();

    await contract.assetFactoryFacet.connect(custodian).custodianSign(0);
    await contract.assetFactoryFacet.connect(custodian).custodianSign(1);
    await contract.assetFactoryFacet.connect(custodian).custodianSign(2);

    await contract.araFacet
      .connect(user1)
      .approve(contract.anyrareDiamond.address, 2 ** 52);
    await contract.assetFactoryFacet.connect(user1).payFeeAndClaimToken(0);
    await contract.assetFactoryFacet.connect(user1).payFeeAndClaimToken(1);
    await contract.assetFactoryFacet.connect(user1).payFeeAndClaimToken(2);

    const totalAsset = await contract.assetFacet.totalAsset();
    expect(totalAsset).equal(3);

    expect(await contract.assetFacet.ownerOf(0)).equal(user1.address);
    expect(await contract.assetFacet.ownerOf(1)).equal(user1.address);
    expect(await contract.assetFacet.ownerOf(2)).equal(user1.address);
  });

  it("should test function mint collection", async () => {
    await contract.collectionFactoryFacet.connect(user1).mintCollection({
      name: "Collection1",
      symbol: "CL1",
      tokenURI: "https://ipfs/demo.json",
      decimal: 5,
      precision: 3,
      totalSupply: 10000,
      maxWeight: 100000,
      collectorFeeWeight: 2500,
      totalAsset: 3,
      assets: [0, 1, 2]
    });

    const result = await contract.dataFacet.getCollectionByIndex(0);
    expect(result.symbol).equal("CL1");

  });
});
