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
    [root, user1, user2, manager, operation, auditor, custodian, founder] =
      await ethers.getSigners();
    contract = await deployContract();
  });

  it("should test function mintAsset", async () => {
    const tx = await contract.assetFactoryFacet.connect(auditor).mintAsset({
      founder: founder.address,
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
    expect(result.status).equal(1);

    const totalAsset = await contract.assetFacet.totalAsset();
    console.log(totalAsset);
  });
});
