import { expect } from "chai";
import { ethers } from "hardhat";

describe("AnyRare Smart Contracts", async () => {
  it("Long Pipeline Testing", async () => {
    console.log("*** Initialize wallet address");

    const [root, user1, user2, user3, user4] = await ethers.getSigners();

    console.log("root wallet: ", root.address);
    console.log("user1 wallet: ", user1.address);
    console.log("user2 wallet: ", user2.address);
    console.log("user3 wallet: ", user3.address);
    console.log("user4 wallet: ", user4.address);

    console.log("\n*** Deploy Contract");

    const MemberContract = await ethers.getContractFactory("Member");
    const GovernanceContract = await ethers.getContractFactory("Governance");
    const BancorFormulaContract = await ethers.getContractFactory(
      "BancorFormula"
    );
    const ARATokenContract = await ethers.getContractFactory("ARAToken");
    const CollateralTokenContract = await ethers.getContractFactory(
      "CollateralToken"
    );
    const ProposalContract = await ethers.getContractFactory("Proposal");
    const NFTFactoryContract = await ethers.getContractFactory("NFTFactory");

    const memberContract = await MemberContract.deploy(root.address);
    const governanceContract = await GovernanceContract.deploy();
    const bancorFormulaContract = await BancorFormulaContract.deploy();
    const collateralTokenContract = await CollateralTokenContract.deploy(
      root.address,
      "wDAI",
      "wDAI",
      100
    );
    const araTokenContract = await ARATokenContract.deploy(
      governanceContract.address,
      bancorFormulaContract.address,
      "ARA",
      "ARA",
      collateralTokenContract.address,
      2 ** 32
    );
    const proposalContract = await ProposalContract.deploy();
    const nftFactoryContract = await NFTFactoryContract.deploy(
      governanceContract.address,
      "AnyRare NFT Factory",
      "AnyRare NFT Factory"
    );

    console.log("MemberContract Addr: ", memberContract.address);
    console.log("GovernanceContract Addr: ", governanceContract.address);
    console.log("BancorFormulaContract Addr: ", bancorFormulaContract.address);
    console.log(
      "CollateralTokenContract Addr: ",
      collateralTokenContract.address
    );
    console.log("ARATokenContract Addr: ", araTokenContract.address);
    console.log("ProposalContract Addr: ", proposalContract.address);
    console.log("NFTFactoryContract Addr: ", nftFactoryContract.address);

    console.log("\n*** Init Contract Address in Governance Contract");
    await governanceContract.initContractAddress(
      memberContract.address,
      araTokenContract.address,
      proposalContract.address,
      nftFactoryContract.address
    );

    expect(await governanceContract.getMemberContract()).to.equal(
      memberContract.address
    );
    expect(await governanceContract.getARATokenContract()).to.equal(
      araTokenContract.address
    );
    expect(await governanceContract.getProposalContract()).to.equal(
      proposalContract.address
    );
    expect(await governanceContract.getNFTFactoryContract()).to.equal(
      nftFactoryContract.address
    );
    console.log("Test: GetMemberContract Pass!");
    console.log("Test: GetARATokenContract Pass!");
    console.log("Test: GetProposalContract Pass!");
    console.log("Test: GetNFTFactoryContract Pass!");

    console.log("\n*** Member Contract");
    await memberContract.setMember(user1.address, root.address);
    await memberContract.setMember(user2.address, user1.address);
    await expect(memberContract.setMember(user3.address, user3.address)).to.be
      .reverted;
    console.log("Test: Should be revert if referral is self referrence.");

    expect(await memberContract.members(root.address)).to.equal(root.address);
    expect(await memberContract.members(user1.address)).to.equal(root.address);
    expect(await memberContract.members(user2.address)).to.equal(user1.address);
    expect(+(await memberContract.members(user3.address))).to.equal(0x0);
    expect(await memberContract.isMember(user2.address)).to.equal(true);
    expect(await memberContract.isMember(user3.address)).to.equal(false);
    console.log("Test: referral for root is root");
    console.log("Test: referral for user1 is root");
    console.log("Test: referral for user2 is user1");
    console.log("Test: referral for user3 is null");
    console.log("Test: user2 is member");
    console.log("Test: user3 is not member");

    console.log("\n*** Bancor Formula");
    expect(
      +(await bancorFormulaContract.purchaseTargetAmount(200, 100, 400000, 500))
    ).to.equal(209);
    expect(
      +(await bancorFormulaContract.purchaseTargetAmount(409, 600, 400000, 500))
    ).to.equal(112);
    expect(
      +(await bancorFormulaContract.purchaseTargetAmount(
        10033333,
        104442323322300,
        10333,
        3283333332444444
      ))
    ).to.equal(367276);
    expect(
      +(await bancorFormulaContract.saleTargetAmount(200, 100, 400000, 50))
    ).to.equal(51);
    console.log("Test: PurchaseTargetAmount");
    console.log("Test: SaleTargetAmount");

    console.log("\n*** Collateral Token");
    await collateralTokenContract.mint(300000);
    expect(+(await collateralTokenContract.balanceOf(root.address))).to.equal(
      300100
    );
    console.log(
      "Mint: 300,000 wDAI to root, now root wallet have 300,100 wDAI"
    );
    await collateralTokenContract.mint(500000);
    expect(+(await collateralTokenContract.balanceOf(root.address))).to.equal(
      800100
    );
    console.log(
      "Mint: 500,000 wDAI to root, now root wallet have 800,100 wDAI"
    );
    expect(+(await collateralTokenContract.totalSupply())).to.equal(800100);
    console.log("Total Supply for wDAI is 800,100");
    await collateralTokenContract.transfer(user1.address, 15000);
    console.log("Transfer: 15,000 wDAI from root to user1");
    await collateralTokenContract.transfer(araTokenContract.address, 100);
    console.log(
      "Transfer: 100 wDAI from root to ARATokenContract as a seed collateral"
    );
    expect(+(await collateralTokenContract.balanceOf(root.address))).to.equal(
      785000
    );
    console.log("Balance: root wallet is 785,000 wDAI");
    await collateralTokenContract.connect(user1).transfer(user2.address, 500);
    console.log("Transfer: 500 wDai from user1 to user2");
    expect(+(await collateralTokenContract.balanceOf(user1.address))).to.equal(
      14500
    );
    console.log("Balance: wDAI for user1 has remain 14,500 from 15,000");
    expect(+(await collateralTokenContract.balanceOf(user2.address))).to.equal(
      500
    );
    console.log("Balance: user2 has 500 wDAI");
    await expect(collateralTokenContract.connect(user1).mint(1000)).to.be
      .reverted;
    console.log(
      "User1 try to mint new wDAI but failed because of has no permission. Only root wallet can allow to mint new wDAI."
    );

    console.log("\n*** ARATokenContract");
    await expect(araTokenContract.connect(user3).mint(300)).to.be.reverted;
    console.log(
      "User3 try to mint new ARA token but failed because of is not a member."
    );
    await collateralTokenContract
      .connect(user1)
      .approve(araTokenContract.address, 9999999);
    console.log(
      "User1 approve spending limit for ARATokenContract for 9999999 wDAI."
    );
    expect(
      await collateralTokenContract
        .connect(user1)
        .allowance(user1.address, araTokenContract.address)
    ).to.equal(9999999);
    console.log("Test: check spending limit for user1 to ARATokenContract.");
    expect(
      await collateralTokenContract.balanceOf(araTokenContract.address)
    ).to.equal(100);
    console.log(
      "Balance of wDAI for ARATokenContract as a collateral reserve is now 100 wDAI."
    );

    await araTokenContract.connect(user1).mint(100);
    expect(await araTokenContract.balanceOf(user1.address)).to.equal(
      1166434623
    );
    console.log(
      "Mint: user1 send 100 wDAI to ARATokenContract and receive 1166434623 bARA (10^-18 ARA)"
    );

    await collateralTokenContract
      .connect(user2)
      .approve(araTokenContract.address, 9999999);
    await araTokenContract.connect(user2).mint(300);
    expect(
      await collateralTokenContract.balanceOf(araTokenContract.address)
    ).to.equal(500);

    expect(await collateralTokenContract.balanceOf(root.address)).to.equal(
      785000
    );

    expect(await araTokenContract.balanceOf(user2.address)).to.equal(
      2508888085
    );
    expect(await collateralTokenContract.balanceOf(user2.address)).to.equal(
      200
    );
    expect(
      await collateralTokenContract.balanceOf(araTokenContract.address)
    ).to.equal(500);
    expect(await araTokenContract.totalSupply()).to.equal(8176131408);
    const collateralWeight = (
      await governanceContract.getPolicy("COLLATERAL_WEIGHT")
    ).policyWeight;
    console.log("ARA Total Supply: ", await araTokenContract.totalSupply());
    console.log(
      "ARA Collateral: ",
      await collateralTokenContract.balanceOf(araTokenContract.address)
    );
    console.log("Collateral Weight: ", collateralWeight);
    console.log(
      "User2 Collateral: ",
      await collateralTokenContract.balanceOf(user2.address)
    );

    console.log(
      "SaleTarget: ",
      await bancorFormulaContract.saleTargetAmount(
        await araTokenContract.totalSupply(),
        await collateralTokenContract.balanceOf(araTokenContract.address),
        collateralWeight,
        100000000
      )
    );
    await araTokenContract.connect(user2).burn(100000000);
    expect(await araTokenContract.balanceOf(user2.address)).to.equal(
      2408888085
    );
    expect(await araTokenContract.totalSupply()).to.equal(8076131408);
    expect(await collateralTokenContract.balanceOf(user2.address)).to.equal(
      215
    );
  });
});
