const { deployContract } = require("../scripts/deploy.js");

const { expect } = require("chai");

describe("Test ARAToken Contract", async () => {
  let contract;
  let root, user1;
  const transactionId = "0xc7133b728e0fc150285e716afccd063dd3c67c18603e8bfeb00414c79dfde0e8";

  before(async function() {
    [root, user1] = await ethers.getSigners();
    contract = await deployContract();
  });

  it("should test function crossChainDepositCollateral", async () => {
    const tx = await contract.araFacet
      .connect(root)
      .crossChainDepositCollateral(
        user1.address,
        10 ** 6,
        0,
        transactionId,
      );
  });

  it("should test function mint", async () => {
    const tx = await contract.araFacet.connect(user1).mint(0, transactionId);
  });


});
