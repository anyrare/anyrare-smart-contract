import { expect } from "chai";
import { ethers } from "hardhat";

describe("Member", async () => {
    it("Initialize", async () => {
        const [root, user1, user2] = await ethers.getSigners();

        const Member = await ethers.getContractFactory("Member");
        const member = await Member.deploy(root.address);

        console.log("memberContract", member.address);

        console.log("root", root.address);
        console.log("user1", user1.address);
        console.log("user2", user2.address);
        await member.setMember(user1.address, root.address);
        await member.setMember(user2.address, user1.address);

        console.log("getMember Root", await member.members(root.address));
        console.log("getMember User1", await member.members(user1.address));
        console.log("getMember User2", await member.members(user2.address));
    })
})
