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

  const totalSupply = +(await araTokenContract.totalFreeFloatSupply());
  const user1Balance = +(await araTokenContract.balanceOf(user1.address));
  const user2Balance = +(await araTokenContract.balanceOf(user2.address));
  const user3Balance = +(await araTokenContract.balanceOf(user3.address));

  console.log(
    "ARA Balance (user1, user2, user3, totalSupply): ",
    user1Balance,
    user2Balance,
    user3Balance,
    totalSupply
  );

  const policyName = "BUYBACK_WEIGHT";
  const buybackPolicy0 = await governanceContract.getPolicy(policyName);

  console.log("User1 Share:", user1Balance / totalSupply);

  await proposalContract
    .connect(user1)
    .openPolicyProposal(
      policyName,
      80000,
      1000000,
      432000,
      86000,
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

  console.log("Start vote token");

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

  console.log("Vote Result:", +voteResult.totalApproveToken);
  console.log("Vote Result:", user1Balance + user2Balance + user3Balance);
  expect(+voteResult.totalApproveToken).to.equal(
    user1Balance + user2Balance + user3Balance
  );
  console.log("Test: vote total approve token");

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

export const testOpenPolicyWithNotEnoughtValidVote1 = async (
  ethers: any,
  proposalContract: any,
  governanceContract: any,
  user1: any
) => {
  console.log(
    "\n**** Adjust ARA Collateral Weight with failed vote because not enough token to valid vote"
  );
  const policyName = "ARA_COLLATERAL_WEIGHT";
  await proposalContract
    .connect(user1)
    .openPolicyProposal(
      policyName,
      300000,
      1000000,
      432000,
      86000,
      100000,
      510000,
      750000,
      0,
      0
    );
  await proposalContract.getCurrentPolicyProposal(policyName);
  expect(
    (await governanceContract.getPolicy(policyName)).policyWeight
  ).to.equal(400000);
  await proposalContract.connect(user1).votePolicyProposal(policyName, true);
  console.log("Vote: user1 vote approve");

  await ethers.provider.send("evm_increaseTime", [432000]);
  await proposalContract.countVotePolicyProposal(policyName);

  await ethers.provider.send("evm_increaseTime", [432000]);
  await proposalContract.applyPolicyProposal(policyName);

  const voteResult = await proposalContract.getCurrentPolicyProposal(
    policyName
  );
  expect(voteResult.voteResult).to.equal(false);
  expect(
    (await governanceContract.getPolicy(policyName)).policyWeight
  ).to.equal(400000);
  console.log("Process: vote result equal false, nothing happend");

  console.log(
    "\n**** Adjust ARA Collateral Weight with failed vote because not enough token to valid vote"
  );
};

export const testOpenPolicyWithNotEnoughtValidVote2 = async (
  ethers: any,
  proposalContract: any,
  governanceContract: any,
  user1: any,
  user2: any,
  user3: any
) => {
  const policyName = "ARA_COLLATERAL_WEIGHT";
  await proposalContract
    .connect(user1)
    .openPolicyProposal(
      policyName,
      100000,
      1000000,
      432000,
      86000,
      100000,
      510000,
      750000,
      0,
      0
    );
  await proposalContract.getCurrentPolicyProposal(policyName);
  expect(
    (await governanceContract.getPolicy(policyName)).policyWeight
  ).to.equal(400000);
  await proposalContract.connect(user1).votePolicyProposal(policyName, true);
  await proposalContract.connect(user2).votePolicyProposal(policyName, true);
  await proposalContract.connect(user3).votePolicyProposal(policyName, false);
  console.log("Vote: user1 vote approve");
  console.log("Vote: user2 vote approve");
  console.log("Vote: user3 vote reject");

  await ethers.provider.send("evm_increaseTime", [432000]);
  await proposalContract.countVotePolicyProposal(policyName);

  await ethers.provider.send("evm_increaseTime", [432000]);
  await proposalContract.applyPolicyProposal(policyName);

  const voteResult = await proposalContract.getCurrentPolicyProposal(
    policyName
  );
  expect(voteResult.voteResult).to.equal(false);
  expect(
    (await governanceContract.getPolicy(policyName)).policyWeight
  ).to.equal(400000);
  console.log("Process: vote result equal false, nothing happend");
};

// TODO: revise manager proposal
// TODO: exclude lockup supply from totalsupply when open vote
export const testAdjustManagementList = async (
  ethers: any,
  proposalContract: any,
  governanceContract: any,
  araTokenContract: any,
  user1: any,
  user2: any,
  user3: any
) => {
  console.log("\n**** Adjust management list");
  await proposalContract.connect(user1).openListProposal(
    "MANAGERS_LIST",
    1000000,
    [
      {
        addr: user1.address,
        controlWeight: 400000,
        dataURI: "https://example.net/json1.json",
      },
      {
        addr: user2.address,
        controlWeight: 300000,
        dataURI: "https://example.net/json2.json",
      },
      {
        addr: user3.address,
        controlWeight: 30000,
        dataURI: "https://example.net/json3.json",
      },
    ],
    3
  );

  const proposalId = +(await proposalContract
    .connect(user1)
    .getCurrentListProposalId());
  console.log("ProposalId", proposalId);

  console.log("Set: open manager proposal");
  await proposalContract.connect(user1).voteListProposal(proposalId, true);
  await proposalContract.connect(user2).voteListProposal(proposalId, true);
  await proposalContract.connect(user3).voteListProposal(proposalId, true);
  console.log("Vote: user 1, 2, 3 vote approve");

  await ethers.provider.send("evm_increaseTime", [432000]);
  await proposalContract.countVoteListProposal(proposalId);
  console.log("Process: vote result to be accept");

  const proposalResult = await proposalContract
    .connect(user1)
    .listProposals(proposalId);

  const totalSupply = +(await araTokenContract.totalSupply());
  const totalFreeFloatSupply = +(await araTokenContract.totalFreeFloatSupply());
  console.log(
    "Supply: (totalSupply, freeFloatSupply, freeFloatRatio)",
    totalSupply,
    totalFreeFloatSupply,
    totalFreeFloatSupply / totalSupply
  );
  const user1Balance = +(await araTokenContract.balanceOf(user1.address));
  const user2Balance = +(await araTokenContract.balanceOf(user2.address));
  const user3Balance = +(await araTokenContract.balanceOf(user3.address));
  console.log(
    "Balance: (user1, user2, user3, total, totalRatio)",
    user1Balance,
    user2Balance,
    user3Balance,
    user1Balance + user2Balance + user3Balance,
    (user1Balance + user2Balance + user3Balance) / totalFreeFloatSupply
  );

  expect(+proposalResult.info.totalVoteToken).to.equal(
    user1Balance + user2Balance + user3Balance
  );
  expect(+proposalResult.info.totalApproveToken).to.equal(
    user1Balance + user2Balance + user3Balance
  );
  expect(+proposalResult.info.totalSupplyToken).to.equal(totalFreeFloatSupply);
  expect(+proposalResult.info.totalVoter).to.equal(3);

  await expect(proposalContract.applyListProposal(proposalId)).to.be.reverted;
  expect(await governanceContract.getTotalManager()).to.equal(1);
  console.log(
    "Test: Total manager = 1, not change after meet effective duration."
  );

  await ethers.provider.send("evm_increaseTime", [432000]);
  await proposalContract.applyListProposal(proposalId);
  console.log("Process: apply policy after effective duration.");

  const newManager1 = await governanceContract.getManager(0);
  const newManager2 = await governanceContract.getManager(1);
  const newManager3 = await governanceContract.getManager(2);

  expect({
    addr: newManager1.addr,
    controlWeight: +newManager1.controlWeight,
  }).to.eql({
    addr: user1.address,
    controlWeight: 400000,
  });
  expect({
    addr: newManager2.addr,
    controlWeight: +newManager2.controlWeight,
  }).to.eql({
    addr: user2.address,
    controlWeight: 300000,
  });
  expect({
    addr: newManager3.addr,
    controlWeight: +newManager2.controlWeight,
  }).to.eql({
    addr: user3.address,
    controlWeight: 300000,
  });

  expect(await governanceContract.isManager(user1.address)).to.equal(true);
  expect(await governanceContract.isManager(user2.address)).to.equal(true);
  expect(await governanceContract.isManager(user3.address)).to.equal(true);
  console.log("Test: New managers list should be set");
};

export const testAdjustAuditor = async (
  ethers: any,
  proposalContract: any,
  governanceContract: any,
  araTokenContract: any,
  auditor: any,
  user1: any,
  user2: any,
  user3: any
) => {
  console.log("\n*** Open auditor proposal");
  expect(await governanceContract.isAuditor(auditor.address)).to.equal(false);
  console.log("Test: auditor1 is not an auditor");

  await expect(
    proposalContract.openListProposal(
      "AUDITORS_LIST",
      1000000,
      [
        {
          addr: auditor.address,
          controlWeight: 1000000,
          dataURI: "https://example.net/json.json",
        },
      ],
      1
    )
  ).to.be.reverted;
  console.log(
    "Test: root cannot open auditor proposal because is not a manager"
  );

  await proposalContract.connect(user1).openListProposal(
    "AUDITORS_LIST",
    1000000,
    [
      {
        addr: auditor.address,
        controlWeight: 1000000,
        dataURI: "https://example.net/json.json",
      },
    ],
    1
  );
  console.log("Test: open proposal");

  const proposalId = +(await proposalContract
    .connect(user1)
    .getCurrentListProposalId());
  console.log("ProposalId", proposalId);

  await expect(proposalContract.voteListProposal(true)).to.be.reverted;
  console.log("Test: root cannot vote auditor because is not a manager");

  await proposalContract.connect(user1).voteListProposal(proposalId, true);
  await proposalContract.connect(user2).voteListProposal(proposalId, true);
  await proposalContract.connect(user3).voteListProposal(proposalId, true);
  console.log("Vote: manager 1, 2, 3 vote approve");

  await ethers.provider.send("evm_increaseTime", [432000]);
  await proposalContract.countVoteListProposal(proposalId);
  console.log("Proccess: vote result");

  await ethers.provider.send("evm_increaseTime", [432000]);
  await proposalContract.applyListProposal(proposalId);
  console.log("Process: apply policy after effective duration.");

  expect(await governanceContract.isAuditor(auditor.address)).to.equal(true);
  console.log("Result: auditor1 is an auditor");
};

export const testAdjustCustodian = async (
  ethers: any,
  proposalContract: any,
  governanceContract: any,
  araTokenContract: any,
  custodian: any,
  user1: any,
  user2: any,
  user3: any
) => {
  console.log("\n*** Open custodian proposal");
  expect(await governanceContract.isCustodian(custodian.address)).to.equal(
    false
  );
  console.log("Test: custodian1 is not a custodian");
  await expect(
    proposalContract.openListProposal(
      "CUSTODIANS_LIST",
      1000000,
      [
        {
          addr: custodian.address,
          controlWeight: 1000000,
          dataURI: "https://example.net/json.json",
        },
      ],
      1
    )
  ).to.be.reverted;
  console.log(
    "Test: root cannot open custodian proposal because is not a manager"
  );
  await proposalContract.connect(user1).openListProposal(
    "CUSTODIANS_LIST",
    1000000,
    [
      {
        addr: custodian.address,
        controlWeight: 1000000,
        dataURI: "https://example.net/json.json",
      },
    ],
    1
  );

  const proposalId = +(await proposalContract
    .connect(user1)
    .getCurrentListProposalId());
  console.log("ProposalId", proposalId);

  await expect(proposalContract.voteListProposal(proposalId, true)).to.be
    .reverted;
  console.log("Test: root cannot vote custodian because is not a manager");

  await proposalContract.connect(user1).voteListProposal(proposalId, true);
  await proposalContract.connect(user2).voteListProposal(proposalId, true);
  await proposalContract.connect(user3).voteListProposal(proposalId, true);
  console.log("Vote: manager 1, 2, 3 vote approve");

  await ethers.provider.send("evm_increaseTime", [432000]);
  await proposalContract.countVoteListProposal(proposalId);
  console.log("Count Vote: custodian");

  await ethers.provider.send("evm_increaseTime", [432000]);
  await proposalContract.applyListProposal(proposalId);
  console.log("Process: apply policy after effective duration.");

  console.log("Proccess: vote result");
  expect(await governanceContract.isCustodian(custodian.address)).to.equal(
    true
  );
};

export const testOpenNewVoteWithinEffectiveDuration = () => { };
