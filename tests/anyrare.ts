// import * as anchor from "@project-serum/anchor";
// import * as serumCmn from "@project-serum/common";
// import { TOKEN_PROGRAM_ID } from "@solana/spl-token";
// import { assert } from "chai";

// describe("cahiers-check", () => {
//   const provider = anchor.Provider.env();
//   anchor.setProvider(provider);

//   const program = anchor.workspace.CashiersCheck;

//   let mint = null;
//   let god = null;
//   let receiver = null;

//   it("Sets up initial test state", async () => {
//     const [_mint, _god] = await serumCmn.createMintAndVault(
//       program.provider,
//       new anchor.BN(148930)
//     );
//     mint = _mint;
//     god = _god;
//     console.log(_mint, _god)

//     receiver = await serumCmn.createTokenAccount(
//       program.provider,
//       mint,
//       program.provider.wallet.publicKey
//     );
//     console.log('receiver', receiver)
//   });

//   const check = anchor.web3.Keypair.generate();
//   const vault = anchor.web3.Keypair.generate();

//   let checkSigner = null;

//   it("Creates a check!", async () => {
//     let [_checkSigner, nonce] = await anchor.web3.PublicKey.findProgramAddress(
//       [check.publicKey.toBuffer()],
//       program.programId
//     );
//     checkSigner = _checkSigner;

//     await program.rpc.createCheck(new anchor.BN(100), "Hello world", nonce, {
//       accounts: {
//         check: check.publicKey,
//         vault: vault.publicKey,
//         checkSigner,
//         from: god,
//         to: receiver,
//         owner: program.provider.wallet.publicKey,
//         tokenProgram: TOKEN_PROGRAM_ID,
//         rent: anchor.web3.SYSVAR_RENT_PUBKEY,
//       },
//       signers: [check, vault],
//       instructions: [
//         await program.account.check.createInstruction(check, 300),
//         ...(await serumCmn.createTokenAccountInstrs(
//           program.provider,
//           vault.publicKey,
//           mint,
//           checkSigner
//         )),
//       ],
//     });

//     const checkAccount = await program.account.check.fetch(check.publicKey);
//     console.log('checkAccount', checkAccount);

//     assert.ok(checkAccount.from.equals(god));
//     assert.ok(checkAccount.to.equals(receiver));
//     assert.ok(checkAccount.amount.eq(new anchor.BN(100)));
//     assert.ok(checkAccount.memo === "Hello world");
//     assert.ok(checkAccount.vault.equals(vault.publicKey));
//     assert.ok(checkAccount.nonce === nonce);
//     assert.ok(checkAccount.burned === false);

//     let vaultAccount = await serumCmn.getTokenAccount(
//       program.provider,
//       checkAccount.vault
//     );
//     assert.ok(vaultAccount.amount.eq(new anchor.BN(100)));
//   }) ;

//   it("Cashes a check", async () => {
//     await program.rpc.cashCheck({
//       accounts: {
//         check: check.publicKey,
//         vault: vault.publicKey,
//         checkSigner: checkSigner,
//         to: receiver,
//         owner: program.provider.wallet.publicKey,
//         tokenProgram: TOKEN_PROGRAM_ID,
//       }
//     });

//     const checkAccount = await program.account.check.fetch(check.publicKey);
//     assert.ok(checkAccount.burned === true);

//     let vaultAccount = await serumCmn.getTokenAccount(
//       program.provider,
//       checkAccount.vault
//     );
//     assert.ok(vaultAccount.amount.eq(new anchor.BN(0)));

//     let receiverAccount = await serumCmn.getTokenAccount(
//       program.provider,
//       receiver
//     );
//     assert.ok(receiverAccount.amount.eq(new anchor.BN(100)));
//   });
// });
