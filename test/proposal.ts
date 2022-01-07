import { expect } from "chai";

export const testOpenDuplicatePolicyWithOpenVote = async (
  proposalContract: any,
  user: any,
  policyName: any
) => {
  await expect(
    proposalContract
      .connect(user)
      .openPolicyProposal(
        policyName,
        80000,
        1000000,
        432000,
        100000,
        510000,
        750000,
        0,
        0
      )
  ).to.be.reverted;
  console.log("Test: attemp to open duplicate policy with open vote");
};

export const testOpenPolicyWithNotEnoughToken = async (
  proposalContract: any,
  user: any
) => {
  await expect(
    proposalContract
      .connect(user)
      .openPolicyProposal(
        "DIVIDEND_WEIGHT",
        80000,
        1000000,
        432000,
        100000,
        510000,
        750000,
        0,
        0
      )
  ).to.be.reverted;
  await expect(
    proposalContract
      .connect(user)
      .openPolicyProposal(
        "ARA_COLLATERAL_WEIGHT",
        80000,
        1000000,
        432000,
        100000,
        510000,
        750000,
        0,
        0
      )
  ).to.be.reverted;
  console.log("Test: attemp to open new policy proposal but not enough token");
};

export const testOpentPolicyWithSuccessVote = async (
  ethers: any,
  proposalContract: any,
  araTokenContract: any,
  governanceContract: any,
  user1: any,
  user2: any,
  user3: any,
  user4: any
) => {
  console.log("\n*** Proposal");
  console.log("\n**** Adjust Buyback Weight with success vote");

  const user1Balance = +(await araTokenContract.balanceOf(user1.address));
  const user2Balance = +(await araTokenContract.balanceOf(user2.address));
  const user3Balance = +(await araTokenContract.balanceOf(user3.address));

  console.log(
    "ARA Balance (user1, user2, user3): ",
    user1Balance,
    user2Balance,
    user3Balance
  );

  const policyName = "BUYBACK_WEIGHT";
  const buybackPolicy0 = await governanceContract.getPolicy(policyName);

  await proposalContract
    .connect(user1)
    .openPolicyProposal(
      policyName,
      80000,
      1000000,
      432000,
      100000,
      510000,
      750000,
      0,
      0
    );
  const policyProposal = await proposalContract.getCurrentPolicyProposal(
    policyName
  );
  expect(policyProposal.policyWeight).to.equal(80000);
  expect(policyProposal.minWeightApproveVote).to.equal(750000);
  console.log("Test: Open policy proposal");

  testOpenDuplicatePolicyWithOpenVote(proposalContract, user1, policyName);
  testOpenPolicyWithNotEnoughToken(proposalContract, user4);

  await proposalContract.connect(user1).votePolicyProposal(policyName, true);
  console.log("Vote: user1 vote approve");

  await proposalContract.connect(user2).votePolicyProposal(policyName, true);
  console.log("Vote: user2 vote approve");

  await proposalContract.connect(user3).votePolicyProposal(policyName, true);
  console.log("Vote: user3 vote reject");

  await proposalContract.connect(user4).votePolicyProposal(policyName, false);
  console.log("Vote: user4 vote approve");

  await expect(proposalContract.countVotePolicyProposal(policyName)).to.be
    .reverted;
  console.log("Test: Try to count vote result but failed because not ending");

  await ethers.provider.send("evm_increaseTime", [432000]);
  console.log("Increase block timestamp");

  await proposalContract.countVotePolicyProposal(policyName);
  console.log("Process: vote result");

  const voteResult = await proposalContract.getCurrentPolicyProposal(
    policyName
  );
  expect(voteResult.totalApproveToken).to.equal(
    user1Balance + user2Balance + user3Balance
  );

  expect(voteResult.voteResult).to.equal(true);
  expect(voteResult.policyWeight).to.equal(80000);
  console.log("Test: vote result in policy proposal would be success.");

  const buybackPolicy1 = await governanceContract.getPolicy(policyName);
  expect(buybackPolicy0.policyWeight).to.equal(buybackPolicy1.policyWeight);
  expect(buybackPolicy1.policyWeight).to.equal(50000);
  console.log(
    "Test: policy in governance still not change, waiting for effective duration."
  );

  await expect(proposalContract.countVotePolicyProposal(policyName)).to.be
    .reverted;
  console.log("Test: avoid duplicate process result");

  await expect(
    proposalContract.connect(user3).votePolicyProposal(policyName, true)
  ).to.be.reverted;
  console.log("Test: Try to vote close proposal should be reverted");

  await expect(proposalContract.applyPolicyProposal(policyName)).to.be.reverted;
  console.log(
    "Test: Try to apply new policy to goverance but failed because not meet effective duration."
  );

  await ethers.provider.send("evm_increaseTime", [432000]);
  console.log("Increase block timestamp");

  await proposalContract.applyPolicyProposal(policyName);
  console.log("Apply policy after effective duration.");

  const buybackPolicy2 = await governanceContract.getPolicy(policyName);
  expect(buybackPolicy2.policyWeight).to.equal(80000);
  console.log("Test: New policy should be apply to governance.");
};
