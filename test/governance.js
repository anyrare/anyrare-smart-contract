const { deployContract } = require("../scripts/deploy.js");

const { expect } = require("chai");

describe("Test Governance Contract", async () => {
  let contract,
    root,
    user1,
    user2,
    manager1,
    manager2,
    custodian1,
    custodian2,
    auditor1,
    auditor2;

  before(async () => {
    [
      root,
      user1,
      user2,
      manager1,
      manager2,
      custodian1,
      custodian2,
      auditor1,
      auditor2,
    ] = await ethers.getSigners();

    contract = await deployContract();
  });

  it("should test function getManager", async () => {
    const result0 = await contract.dataFacet.getManager(0);
    expect(result0.addr).to.equal(manager1.address);
    expect(await contract.dataFacet.getTotalManager()).to.equal(1);

    const result1 = await contract.dataFacet.isManager(manager1.address);
    expect(result1).to.equal(true);
  });

  it("should test function isCustodian and isAuditor", async () => {
    const result0 = await contract.dataFacet.isCustodian(custodian1.address);
    const result1 = await contract.dataFacet.isAuditor(auditor1.address);
    expect(result0).to.equal(true);
    expect(result1).to.equal(true);
  });
});
