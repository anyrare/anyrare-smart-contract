const { ethers } = require("hardhat");
const { getSelectors, FacetCutAction } = require("./libraries/diamond.js");

const deployContract = async () => {
  const [root, user1, user2, manager, operation, auditor, custodian, founder] =
    await ethers.getSigners();

  // deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
  const diamondCutFacet = await DiamondCutFacet.deploy();
  await diamondCutFacet.deployed();
  console.log("DiamondCutFacet deployed:", diamondCutFacet.address);

  // deploy Diamond
  const Diamond = await ethers.getContractFactory("Diamond");
  const diamond = await Diamond.deploy(root.address, diamondCutFacet.address);
  await diamond.deployed();
  console.log("Diamond deployed:", diamond.address);

  // deploy DiamondInit
  const DiamondInit = await ethers.getContractFactory("DiamondInit");
  const diamondInit = await DiamondInit.deploy();
  await diamondInit.deployed();
  console.log("DiamondInit deployed:", diamondInit.address);

  // deploy facets
  console.log("\nDeploying facets");

  const LibBancorFormula = await ethers.getContractFactory("LibBancorFormula");
  const libBancorFormula = await LibBancorFormula.deploy();
  await libBancorFormula.deployed();

  const DiamondLoupeFacet = await ethers.getContractFactory(
    "DiamondLoupeFacet"
  );
  const OwnershipFacet = await ethers.getContractFactory("OwnershipFacet");
  const MemberFacet = await ethers.getContractFactory("MemberFacet");
  const GovernanceFacet = await ethers.getContractFactory("GovernanceFacet");
  const ARATokenFacet = await ethers.getContractFactory("ARATokenFacet", {
    libraries: {
      LibBancorFormula: libBancorFormula.address,
    },
  });
  const CollateralTokenFacet = await ethers.getContractFactory(
    "CollateralTokenFacet"
  );

  const _diamondLoupeFacet = await DiamondLoupeFacet.deploy();
  const _ownershipFacet = await OwnershipFacet.deploy();
  const _memberFacet = await MemberFacet.deploy();
  const _governanceFacet = await GovernanceFacet.deploy();
  const _collateralTokenFacet = await CollateralTokenFacet.deploy();
  const _araTokenFacet = await ARATokenFacet.deploy("ARA", "ARA");

  //add facet cut
  const facets = [
    _diamondLoupeFacet,
    _ownershipFacet,
    _memberFacet,
    _governanceFacet,
    _collateralTokenFacet,
    _araTokenFacet
  ];

  const cuts = facets.map((r) => ({
    facetAddress: r.address,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(r),
  }));

  const diamondCut = await ethers.getContractAt("IDiamondCut", diamond.address);
  const functionCall = diamondInit.interface.encodeFunctionData("init");

  const tx = await diamondCut.diamondCut(
    cuts,
    diamondInit.address,
    functionCall
  );
  await tx.wait();

  const diamondLoupeFacet = await ethers.getContractAt(
    "DiamondLoupeFacet",
    diamond.address
  );
  const ownershipFacet = await ethers.getContractAt(
    "OwnershipFacet",
    diamond.address
  );
  const memberFacet = await ethers.getContractAt(
    "MemberFacet",
    diamond.address
  );
  const governanceFacet = await ethers.getContractAt(
    "GovernanceFacet",
    diamond.address
  );
  const collateralTokenFacet = await ethers.getContractAt(
    "CollateralTokenFacet",
    diamond.address
  );
  const araTokenFacet = await ethers.getContractAt(
    "ARATokenFacet",
    diamond.address
  );

  // await memberFacet.initMember();
  await collateralTokenFacet.collateralTokenSetOwner(root.address);
  await collateralTokenFacet.collateralTokenMint(
    root.address,
    ethers.BigNumber.from("1" + "0".repeat(26))
  );
  await araTokenFacet.araTokenInitialize(
    collateralTokenFacet.address,
    ethers.BigNumber.from("1" + "0".repeat(26))
  );
  await memberFacet.initMember();

  const b1 = await collateralTokenFacet.collateralTokenTotalSupply();
  const b2 = await _collateralTokenFacet.totalSupply();
  console.log(b1);
  console.log(b2);

  return {
    diamondAddress: diamond.address,
    diamondLoupeFacet,
    ownershipFacet,
    memberFacet,
    governanceFacet,
    collateralTokenFacet,
    araTokenFacet,
  };
};

if (require.main === module) {
  deployContract()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

exports.deployContract = deployContract;
