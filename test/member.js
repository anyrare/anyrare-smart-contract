const { deployContract } = require("../scripts/deploy.js");

const { expect } = require("chai");

describe("Test Member Contract", async () => {
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

  // it("should test function createMember", async () => {
  //   const tx = await contract.memberFacet
  //     .connect(user1)
  //     .createMember(
  //       user1.address,
  //       root.address,
  //       "user1",
  //       "https://www.icmetl.org/wp-content/uploads/2020/11/user-icon-human-person-sign-vector-10206693.png"
  //     );
  //   const receipt = await tx.wait();
  //   expect(receipt.status).equal(1);
  // });

  it("should test function isMember", async () => {
    const result = await contract.dataFacet.isMember(user1.address);
    expect(result).equal(true);
  });

  it("should test function getReferral", async () => {
    const result = await contract.dataFacet.getReferral(user1.address);
    expect(result).equal(root.address);
  });

  it("should test function getAddressByUsername", async () => {
    const result = await contract.dataFacet.getAddressByUsername("user1");
    expect(result).equal(user1.address);
  });

  it("should test function getMember", async () => {
    const result = await contract.dataFacet.getMember(user1.address);
    expect(result.addr).equal(user1.address);
    expect(result.referral).equal(root.address);
    expect(result.username).equal("user1");
  });

  it("should test function updateMember", async () => {
    const thumbnail =
      "https://www.pngitem.com/pimgs/m/264-2647677_avatar-icon-human-user-avatar-svg-hd-png.png";
    const tx = await contract.memberFacet
      .connect(user1)
      .updateMember(user1.address, "user1", thumbnail);
    const receipt = await tx.wait();
    expect(receipt.status).equal(1);

    const result = await contract.dataFacet.getMember(user1.address);
    expect(result.thumbnail).equal(thumbnail);
  });
});
