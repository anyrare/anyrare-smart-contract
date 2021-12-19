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
    const ARATokenContract = await ethers.getContractFactory("ARA");
    const CollateralToken = await ethers.getContractFactory("CollateralToken");

    const memberContract = await MemberContract.deploy(root.address);
    const governanceContract = await GovernanceContract.deploy();
    const bancorFormulaContract = await BancorFormulaContract.deploy();
    const collateralTokenContract = await CollateralToken.deploy(
      root.address,
      "wDAI",
      "wDAI"
    );
    const araTokenContract = await ARATokenContract.deploy(
      governanceContract.address,
      bancorFormulaContract.address,
      "ARA",
      "ARA",
      collateralTokenContract.address
    );

    // Governance
    await governanceContract.setMemberContract(memberContract.address);
    expect(await governanceContract.getMemberContract()).to.equal(
      memberContract.address
    );

    // Member
    await memberContract.setMember(user1.address, root.address);
    await memberContract.setMember(user2.address, user1.address);
    await expect(memberContract.setMember(user3.address, user3.address)).to.be
      .reverted;

    expect(await memberContract.members(root.address)).to.equal(root.address);
    expect(await memberContract.members(user1.address)).to.equal(root.address);
    expect(await memberContract.members(user2.address)).to.equal(user1.address);
    expect(+(await memberContract.members(user3.address))).to.equal(0x0);
    expect(await memberContract.isValidMember(user2.address)).to.equal(true);
    expect(await memberContract.isValidMember(user3.address)).to.equal(false);

    // BancorFormula
    expect(
      +(await bancorFormulaContract.purchaseTargetAmount(
        10033333,
        104442323322300,
        10333,
        3283333332444444
      ))
    ).to.equal(367276);

    // CollateralToken
    await collateralTokenContract.mint(300000);
    expect(+(await collateralTokenContract.balanceOf(root.address))).to.equal(
      300000
    );
    await collateralTokenContract.mint(500000);
    expect(+(await collateralTokenContract.balanceOf(root.address))).to.equal(
      800000
    );
    expect(+(await collateralTokenContract.totalSupply())).to.equal(800000);
    await collateralTokenContract.transfer(user1.address, 15000);
    expect(+(await collateralTokenContract.balanceOf(root.address))).to.equal(
      785000
    );
    await collateralTokenContract.connect(user1).transfer(user2.address, 500);
    expect(+(await collateralTokenContract.balanceOf(user1.address))).to.equal(
      14500
    );
    expect(+(await collateralTokenContract.balanceOf(user2.address))).to.equal(
      500
    );
    await expect(collateralTokenContract.connect(user1).mint(1000)).to.be
      .reverted;

    // ARAToken
    await expect(araTokenContract.connect(user3).mint(300)).to.be.reverted;

    await collateralTokenContract
      .connect(user1)
      .approve(araTokenContract.address, 9999999);
    expect(
      await collateralTokenContract
        .connect(user1)
        .allowance(user1.address, araTokenContract.address)
    ).to.equal(9999999);
    await araTokenContract.connect(user1).mint(100);
    expect(
      await collateralTokenContract.balanceOf(araTokenContract.address)
    ).to.equal(100);
    expect(await araTokenContract.balanceOf(user1.address)).to.equal(100);

    await collateralTokenContract
      .connect(user2)
      .approve(araTokenContract.address, 9999999);
    await araTokenContract.connect(user2).mint(300);
    expect(
      await collateralTokenContract.balanceOf(araTokenContract.address)
    ).to.equal(400);
  });
});
