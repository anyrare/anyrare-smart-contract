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
  const NFTUtilsContract = await ethers.getContractFactory("NFTUtils");
  const ManagementFundContract = await ethers.getContractFactory(
    "ManagementFund"
  );
  const UtilsContract = await ethers.getContractFactory("Utils");

  const memberContract = await MemberContract.deploy(root.address);
  const governanceContract = await GovernanceContract.deploy();
  const bancorFormulaContract = await BancorFormulaContract.deploy();
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
  const nftUtilsContract = await NFTUtilsContract.deploy(
    governanceContract.address
  );
  const managementFundContract = await ManagementFundContract.deploy(
    governanceContract.address
  );
  const utilsContract = await UtilsContract.deploy(governanceContract.address);

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
  console.log("NFTUtilsContract Addr: ", nftUtilsContract.address);
  console.log("ManagementFundContract Addr: ", managementFundContract.address);
  console.log("UtilsContract Addr: ", utilsContract.address);

  console.log("\n*** Governance Contract");
  console.log("**** Init contract address");
  await governanceContract.initContractAddress(
    memberContract.address,
    araTokenContract.address,
    bancorFormulaContract.address,
    proposalContract.address,
    nftFactoryContract.address,
    nftUtilsContract.address,
    managementFundContract.address,
    utilsContract.address
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
  expect(await governanceContract.getUtilsContract()).to.equal(
    utilsContract.address
  );
  expect(await governanceContract.getNFTUtilsContract()).to.equal(
    nftUtilsContract.address
  );
  expect(await governanceContract.getManagementFundContract()).to.equal(
    managementFundContract.address
  );

  console.log("Test: GetMemberContract Pass!");
  console.log("Test: GetARATokenContract Pass!");
  console.log("Test: GetProposalContract Pass!");
  console.log("Test: GetNFTFactoryContract Pass!");
  console.log("Test: GetBancorFormulaContract Pass!");
  console.log("Test: GetUtilsContract Pass!");
  console.log("Test: GetManagementFundContract Pass!");

  return {
    memberContract,
    governanceContract,
    bancorFormulaContract,
    collateralTokenContract,
    araTokenContract,
    proposalContract,
    nftFactoryContract,
    nftUtilsContract,
    managementFundContract,
    utilsContract,
  };
};
