const { deployContract } = require("../scripts/deploy.js");

const { expect } = require("chai");

describe("Test ARAToken Contract", async () => {
  let contract;
  let user1;

  before(async function() {
    [root, user1] = await ethers.getSigners();

    contract = await deployContract();

    const tx = await contract.memberFacet
      .connect(user1)
      .createMember(
        user1.address,
        root.address,
        "user1",
        "https://www.icmetl.org/wp-content/uploads/2020/11/user-icon-human-person-sign-vector-10206693.png"
      );
  });

  it("should test function collateralTokenMint", async () => {
    const result0 = await contract.collateralTokenFacet
      .connect(root)
      .collateralTokenMint(root.address, 10000);
    expect(result0).to.be.ok;

    await expect(contract.collateralTokenFacet
      .connect(user1)
      .collateralTokenMint(user1.address, 10000)).to.be.reverted;
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

  it("should test function araTokenMint", async () => {
    const result = await contract.araTokenFacet.connect(root).araTokenMint(1250);
    console.log(result);
  });

});
