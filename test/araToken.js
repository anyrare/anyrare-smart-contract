const { deployContract } = require("../scripts/deploy.js");

const { expect } = require("chai");

describe("Test ARAToken Contract", async () => {
  let contract;
  let user1;

  before(async function() {
    [root, user1] = await ethers.getSigners();

    contract = await deployContract();
  });

  it("should test function collateralTokenMint", async () => {
    await contract.collateralTokenFacet
      .connect(root)
      .collateralTokenMint(root.address, 10000);
  });

  it("should test function collateralTokenTransfer", async () => {
    await contract.collateralTokenFacet
      .connect(root)
      .collateralTokenTransfer(user1.address, 1000);
    const user1Balance = await contract.collateralTokenFacet
      .connect(user1)
      .collateralTokenBalanceOf(user1.address);
    expect(+user1Balance).equal(1000);
  });
});
