import { expect } from "chai";
import { ethers } from "hardhat";

describe("Smart Contracts", async () => {
  it("Test Contracts", async () => {
    const [root, user1, user2, user3, user4, collateral] =
      await ethers.getSigners();

    const MemberContract = await ethers.getContractFactory("Member");
    const GovernanceContract = await ethers.getContractFactory("Governance");
    const BancorFormulaContract = await ethers.getContractFactory(
      "BancorFormula"
    );
    const ARAContract = await ethers.getContractFactory("ARA");

    const memberContract = await MemberContract.deploy(root.address);
    const governanceContract = await GovernanceContract.deploy();
    const bancorFormulaContract = await BancorFormulaContract.deploy();
    const araContract = await ARAContract.deploy(
      governanceContract.address,
      bancorFormulaContract.address,
      "ARA",
      "ARA",
      collateral.address
    );

    // Test: Member
    await memberContract.setMember(user1.address, root.address);
    await memberContract.setMember(user2.address, user1.address);
    // await memberContract.setMember(user3.address, user3.address);

    expect(await memberContract.members(root.address)).to.equal(root.address);
    expect(await memberContract.members(user1.address)).to.equal(root.address);
    expect(await memberContract.members(user2.address)).to.equal(user1.address);
    expect(+(await memberContract.members(user3.address))).to.equal(0x0);
    expect(await memberContract.isValidMember(user2.address)).to.equal(true);
    expect(await memberContract.isValidMember(user3.address)).to.equal(false);
  });

  // await memberContract.setMember(user1.address, root.address);
  //await memberContract.setMember(user2.address, user1.address);
  // await memberContract.setMember(user3.address, user3.address);
  //const Member = await ethers.getContractFactory("Member");
  // const member = await Member.deploy(root.address);

  // await member.setMember(user1.address, root.address);
  // await member.setMember(user2.address, user1.address);
  // await member.setMember(user3.address, user3.address);

  // expect(await member.members(root.address)).to.equal(root.address);
  // expect(await member.members(user1.address)).to.equal(root.address);
  // expect(await member.members(user2.address)).to.equal(user1.address);
  // expect(+(await member.members(user3.address))).to.equal(0x0);

  // expect(await member.isValidMember(user2.address)).to.equal(true);
  // expect(await member.isValidMember(user3.address)).to.equal(false);

  // const ARA = await ethers.getContractFactory("ARA");
  // const ARAToken = await ARA.deploy(member.address);

  // console.log(await ARAToken.getMember(user3.address));
});
