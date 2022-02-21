const { ethers } = require("hardhat");
const { getSelectors, FacetCutAction } = require("./libraries/diamond.js");

const deployContract = async () => {
  const [root, user1, user2, manager, operation, auditor, custodian, founder] =
    await ethers.getSigners();
  const contractOwner = root;

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

  const DiamondLoupeFacet = await ethers.getContractFactory("DiamondLoupeFacet");
  const OwnershipFacet = await ethers.getContractFactory("OwnershipFacet");
  const MemberFacet = await ethers.getContractFactory("MemberFacet");
  const GovernanceFacet = await ethers.getContractFactory("GovernanceFacet");
  const ARATokenFacet = await ethers.getContractFactory("ARATokenFacet");
  const CollateralTokenFacet = await ethers.getContractFactory(
    "CollateralTokenFacet"
  );

  const diamondLoupeFacet = await DiamondLoupeFacet.deploy();
  const ownershipFacet = await OwnershipFacet.deploy();
  const memberFacet = await MemberFacet.deploy(root.address);

  await diamondLoupeFacet.deployed();
  await ownershipFacet.deployed();
  await memberFacet.deployed();

  //add facet cut
  const cuts = [];
  cuts.push(
    {
      facetAddress: diamondLoupeFacet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(diamondLoupeFacet),
    },
    {
      facetAddress: ownershipFacet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(ownershipFacet),
    },
    {
      facetAddress: memberFacet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(memberFacet),
    }
  );

  const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address);
  const functionCall = diamondInit.interface.encodeFunctionData('init');
  const tx = await diamondCut.diamondCut(cuts, diamondInit.address, functionCall);
  await tx.wait();

  return diamond.address;
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
