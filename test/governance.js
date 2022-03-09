const { deployContract } = require("../scripts/deploy.js");

const { expect } = require("chai");
// const { policies } = require("./initialPolicy.js");

describe("Test Governance Contract", async () => {
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

  // it("should test function initPolicy", async () => {
  //   const tx = await contract.governanceFacet.connect(root).initPolicy(
  //     1,
  //     [{ addr: founder.address, controlWeight: 10 ** 6 }],
  //     manager.address,
  //     operation.address,
  //     auditor.address,
  //     custodian.address,
  //     policies.length,
  //     policies
  //   );
  //   const receipt = await tx.wait();
  //   expect(receipt.status).equal(1);
  // });

  // it("should test reject function setCustodianByProposal", async () => {
  //   await expect(
  //     contract.governanceFacet.setCustodianByProposal(root.address, true, "")
  //   ).to.be.reverted;
  // });

  it("should test function getFounder", async () => {
    const result0 = await contract.dataFacet.getFounder(0);
    expect(result0.addr).to.equal(founder.address);
    expect(await contract.dataFacet.getTotalFounder()).to.equal(1);
  });
});
