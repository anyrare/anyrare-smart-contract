const { deployContract } = require("../scripts/deploy.js");

const { expect } = require("chai");

describe("Test ARAToken Contract", async () => {
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

  before(async function() {
    [root, user1, user2] = await ethers.getSigners();
    contract = await deployContract();
  });

  it("should test function getBalance", async () => {
    const result0 = await contract.araFacet.connect(root).totalSupply();
    expect(result0).equal("1" + "0".repeat(25));

    const result1 = await contract.araFacet
      .connect(root)
      .balanceOf(root.address);
    expect(result1).equal("1" + "0".repeat(25));
  });

  it("should test function transfer", async () => {
    await contract.araFacet.connect(root).transfer(user1.address, 10000);
    const user1Balance0 = await contract.araFacet.balanceOf(user1.address);
    const user2Balance0 = await contract.araFacet.balanceOf(user2.address);
    await contract.araFacet.connect(user1).transfer(user2.address, 1000);
    const user1Balance1 = await contract.araFacet.balanceOf(user1.address);
    const user2Balance1 = await contract.araFacet.balanceOf(user2.address);
    expect(user2Balance1 - user2Balance0).equal(1000);
    expect(user1Balance1 - user1Balance0 >= -1000).equal(true);
  });
});
