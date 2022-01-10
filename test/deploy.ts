import { expect } from "chai";

export const deployContract = async (ethers: any, root: any) => {
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
  const NFTTransferFeeContract = await ethers.getContractFactory(
    "NFTTransferFee"
  );
  const CollectionFactoryContract = await ethers.getContractFactory(
    "CollectionFactory"
  );
  const ManagementFundContract = await ethers.getContractFactory(
    "ManagementFund"
  );

  const memberContract = await MemberContract.deploy(root.address);
  const governanceContract = await GovernanceContract.deploy();
  const bancorFormulaContract = await BancorFormulaContract.deploy();
  await bancorFormulaContract.init();

  const collateralTokenContract = await CollateralTokenContract.deploy(
    root.address,
    "wDAI",
    "wDAI",
    1000000
  );
  const araTokenContract = await ARATokenContract.deploy(
    governanceContract.address,
    bancorFormulaContract.address,
    "ARA",
    "ARA",
    collateralTokenContract.address,
    2 ** 32
  );
  const proposalContract = await ProposalContract.deploy(
    governanceContract.address
  );
  const nftFactoryContract = await NFTFactoryContract.deploy(
    governanceContract.address,
    "AnyRare NFT Factory",
    "AnyRare NFT Factory"
  );
  const nftTransferFeeContract = await NFTTransferFeeContract.deploy(
    governanceContract.address
  );
  const collectionFactoryContract = await CollectionFactoryContract.deploy(
    governanceContract.address
  );
  const managementFundContract = await ManagementFundContract.deploy(
    governanceContract.address
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
  console.log("NFTUtilsContract Addr: ", nftTransferFeeContract.address);
  console.log(
    "CollectionFactory Contract Addr: ",
    collectionFactoryContract.address
  );
  console.log("ManagementFundContract Addr: ", managementFundContract.address);

  console.log("\n*** Governance Contract");
  console.log("**** Init contract address");
  await governanceContract.initContractAddress(
    memberContract.address,
    araTokenContract.address,
    bancorFormulaContract.address,
    proposalContract.address,
    nftFactoryContract.address,
    nftTransferFeeContract.address,
    collectionFactoryContract.address,
    managementFundContract.address
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
  expect(await governanceContract.getBancorFormulaContract()).to.equal(
    bancorFormulaContract.address
  );
  expect(await governanceContract.getNFTTransferFeeContract()).to.equal(
    nftTransferFeeContract.address
  );
  expect(await governanceContract.getCollectionFactoryContract()).to.equal(
    collectionFactoryContract.address
  );
  expect(await governanceContract.getManagementFundContract()).to.equal(
    managementFundContract.address
  );

  console.log("Test: Get MemberContract Pass!");
  console.log("Test: Get ARATokenContract Pass!");
  console.log("Test: Get ProposalContract Pass!");
  console.log("Test: Get NFTFactoryContract Pass!");
  console.log("Test: Get NFTTransferFeeContract Pass!");
  console.log("Test: Get CollectionFactoryContract Pass!");
  console.log("Test: Get BancorFormulaContract Pass!");
  console.log("Test: Get ManagementFundContract Pass!");

  return {
    memberContract,
    governanceContract,
    bancorFormulaContract,
    collateralTokenContract,
    araTokenContract,
    proposalContract,
    nftFactoryContract,
    nftTransferFeeContract,
    collectionFactoryContract,
    managementFundContract,
  };
};
