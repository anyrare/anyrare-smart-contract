const { deployContract } = require("../scripts/deploy.js");

const { expect } = require("chai");

describe("Test ARAToken Contract", async () => {
  let contract;
  let root, user1, user2;
  const transactionId =
    "0xc7133b728e0fc150285e716afccd063dd3c67c18603e8bfeb00414c79dfde0e8";

  before(async function() {
    [root, user1, user2] = await ethers.getSigners();
    contract = await deployContract();
  });

  it("should test function crossChainDepositCollateral", async () => {
    const tx = await contract.araFacet
      .connect(root)
      .crossChainDepositCollateral(user1.address, 10 ** 6, 0, transactionId);
  });

  it("should test function mint", async () => {
    const balance0 = await contract.araFacet.balanceOf(user1.address);
    await contract.araFacet.connect(user1).mint(0, transactionId);
    await expect(contract.araFacet.connect(user1).mint(0, transactionId)).to.be
      .reverted;

    const balance1 = await contract.araFacet.balanceOf(user1.address);
    console.log(balance0, balance1);
    expect(+balance1 > +balance0).equal(true);
  });

  it("should test function transfer", async () => {
    const user1Balance0 = await contract.araFacet.balanceOf(user1.address);
    const user2Balance0 = await contract.araFacet.balanceOf(user2.address);
    await contract.araFacet.connect(user1).transfer(user2.address, 1000);
    const user1Balance1 = await contract.araFacet.balanceOf(user1.address);
    const user2Balance1 = await contract.araFacet.balanceOf(user2.address);
    expect(user2Balance1 - user2Balance0).equal(1000);
    expect(user1Balance1 - user1Balance0).equal(-1000);
  });
});
