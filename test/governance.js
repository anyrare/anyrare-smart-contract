const { deployContract } = require("../scripts/deploy.js");

const { expect } = require("chai");
const { policies } = require("./initialPolicy.js");

describe("Test Governance Contract", async () => {
  let contract;
  let user1;
  let user2;
  let founder;
  let manager;
  let auditor;
  let custodian;
  let operation;

  before(async function() {
    [root, founder, manager, user1, user2, auditor, custodian, operation] =
      await ethers.getSigners();

    contract = await deployContract();

    const thumbnail =
      "https://www.icmetl.org/wp-content/uploads/2020/11/user-icon-human-person-sign-vector-10206693.png";

    console.log("founderAddr: ", founder.address);
    await contract.memberFacet
      .connect(founder)
      .createMember(founder.address, root.address, "founder", thumbnail);
    await contract.memberFacet
      .connect(manager)
      .createMember(manager.address, founder.address, "manager", thumbnail);
    await contract.memberFacet
      .connect(user1)
      .createMember(user1.address, founder.address, "user1", thumbnail);
    await contract.memberFacet
      .connect(user2)
      .createMember(user2.address, user1.address, "user2", thumbnail);
    await contract.memberFacet
      .connect(auditor)
      .createMember(auditor.address, user1.address, "auditor", thumbnail);
    await contract.memberFacet
      .connect(custodian)
      .createMember(custodian.address, user2.address, "custodian", thumbnail);
    await contract.memberFacet
      .connect(operation)
      .createMember(operation.address, user2.address, "operation", thumbnail);
  });

  it("should test function initPolicy", async () => {
    const tx = await contract.governanceFacet.connect(root).initPolicy(
      1,
      [{ addr: founder.address, controlWeight: 10 ** 6 }],
      manager.address,
      operation.address,
      auditor.address,
      custodian.address,
      policies.length,
      policies
    );
    const receipt = await tx.wait();
    expect(receipt.status).equal(1);
  });

  it("should test reject function setCustodianByProposal", async () => {
    await expect(contract.governanceFacet.setCustodianByProposal(
      root.address,
      true,
      ""
    )).to.be.reverted;
  });

  it("should test function getFounder", async () => {
    const result0 = await contract.governanceFacet.getFounder(0);
    expect(result0.addr).to.equal(founder.address);
    expect(await contract.governanceFacet.getTotalFounder()).to.equal(1);
  });
});