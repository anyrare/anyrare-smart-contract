/* global describe it before ethers */

const {
  getSelectors,
  FacetCutAction,
  removeSelectors,
  findAddressPositionInFacets,
} = require("../scripts/libraries/diamond.js");

const { deployContract } = require("../scripts/deploy.js");

const { expect } = require("chai");

describe("Test Member Contract", async () => {
  let diamondAddress;
  let diamondCutFacet;
  let diamondLoupeFacet;
  let ownershipFacet;
  let memberFacet;
  let user1;
  let user2;
  let manager;
  let operation;
  let auditor;
  let custodian;
  let founder;

  before(async function() {
    [root, user1, user2, manager, operation, auditor, custodian, founder] = await ethers.getSigners();

    diamondAddress = await deployContract();
    diamondCutFacet = await ethers.getContractAt(
      "DiamondCutFacet",
      diamondAddress
    );
    diamondLoupeFacet = await ethers.getContractAt(
      "DiamondLoupeFacet",
      diamondAddress
    );
    ownershipFacet = await ethers.getContractAt(
      "OwnershipFacet",
      diamondAddress
    );
    memberFacet = await ethers.getContractAt("MemberFacet", diamondAddress);
  });

  it("should test function createMember", async () => {
    const tx = await memberFacet.connect(user1).createMember(
      user1.address,
      root.address,
      "user1",
      "https://www.icmetl.org/wp-content/uploads/2020/11/user-icon-human-person-sign-vector-10206693.png"
    );
    const receipt = await tx.wait();
    expect(receipt.status).equal(1);
  });

  it("should test function isMember", async () => {
    const result = await memberFacet.isMember(user1.address);
    expect(result).equal(true);
  });

  it("should test function getReferral", async () => {
    const result = await memberFacet.getReferral(user1.address);
    expect(result).equal(root.address);
  });

  it("should test function getAddressByUsername", async () => {
    const result = await memberFacet.getAddressByUsername("user1");
    expect(result).equal(user1.address);
  });

  it("should test function getMember", async () => {
    const result = await memberFacet.getMember(user1.address);
    expect(result.memberAddress).equal(user1.address);
    expect(result.referral).equal(root.address);
    expect(result.username).equal("user1");
  });
});
