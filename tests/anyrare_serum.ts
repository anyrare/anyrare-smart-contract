// import * as anchor from "@project-serum/anchor";
// import { TOKEN_PROGRAM_ID, Token } from "@solana/spl-token";
// import { TokenInstructions } from "@project-serum/serum";
// import { assert } from "chai";

// describe("Token Proxy", () => {
//   const provider = anchor.Provider.env();
//   anchor.setProvider(provider);

//   const program = anchor.workspace.TokenProxy;

//   const mint = anchor.web3.Keypair.generate();
//   const account = anchor.web3.Keypair.generate();
//   const authority = anchor.web3.Keypair.generate();
//   const rent = anchor.web3.Keypair.generate();
//   const dest = anchor.web3.Keypair.generate();

//   const sleep = (t: number) => new Promise(s => setTimeout(s, t));

//   // Move to serum/common createMintInstructions
//   const createMint = async ({ provider, authority, mint }) => {
//     const instructions = [
//       anchor.web3.SystemProgram.createAccount({
//         fromPubkey: provider.wallet.publicKey,
//         newAccountPubkey: mint.publicKey,
//         space: 82,
//         lamports: await provider.connection.getMinimumBalanceForRentExemption(82),
//         programId: TOKEN_PROGRAM_ID
//       }),
//       TokenInstructions.initializeMint({
//         mint: mint.publicKey,
//         decimals: 0,
//         mintAuthority: mint.publicKey,
//       }),
//     ];
//     const tx = new anchor.web3.Transaction();
//     tx.add(...instructions);
//     // console.log('tx_createMint', tx)

//     return provider.send(tx, [mint]);
//   }

//   // Move to serum/common
//   const createTokenAccount = async ({ provider, mint, account, owner }) => {
//     const instructions = [
//       anchor.web3.SystemProgram.createAccount({
//         fromPubkey: provider.wallet.publicKey,
//         newAccountPubkey: account.publicKey,
//         space: 165,
//         lamports: await provider.connection.getMinimumBalanceForRentExemption(165),
//         programId: TOKEN_PROGRAM_ID
//       }),
//       // Token.createInitAccountInstruction(
//       //   TOKEN_PROGRAM_ID,
//       //   mint.publicKey,
//       //   account.publicKey,
//       //   account.publicKey,
//       // ),
//       TokenInstructions.initializeAccount({
//         account: account.publicKey,
//         mint: mint.publicKey,
//         owner: owner.publicKey,
//       })
//     ];
//     const tx = new anchor.web3.Transaction();
//     tx.add(...instructions);
//     // console.log('tx_createTokenAccount', tx);

//     return provider.send(tx, [account]);
//   }

//   const createMintTo = async ({mint, destination}) => {
//     const instructions = [
//       TokenInstructions.mintTo({
//         mint: mint.publicKey,
//         destination: destination.publicKey,
//         amount: 1,
//         mintAuthority: mint.publicKey,
//       }),
//       // TokenInstructions.setAuthority({
//       //   target: mint.publicKey,
//       //   currentAuthority: mint.publicKey,
//       //   newAuthority: authority.publicKey,
//       //   authorityType: "AccountOwner"
//       // }),
//     ];
//     const tx = new anchor.web3.Transaction();
//     tx.add(...instructions);
    
//     return provider.send(tx, [mint]);
//   }

//   const createTransfer = async({source, destination, owner}) => {
//     // const instructions = [
//     //   TokenInstructions.transfer({
//     //     source: source.publicKey,
//     //     destination: destination.publicKey,
//     //     owner: owner.publicKey,
//     //     amount: 1,
//     //   }),
//     // ];
//     const instructions = [
//       Token.createTransferInstruction(
//         TOKEN_PROGRAM_ID,
//         source.publicKey,
//         destination.publicKey,
//         owner.publicKey,
//         [],
//         1
//       )
//     ]
//     const tx = new anchor.web3.Transaction();
//     tx.add(...instructions);
//     console.log('tx_createTransfer', instructions[0].keys)
    
//     return provider.send(tx, [owner]);
//   }
//   it("proxyInitializeMint", async () => {
//     // await provider.connection.confirmTransaction(
//     //   await provider.connection.requestAirdrop(authority.publicKey, 2000000000),
//     //   "confirmed"
//     // );

//     const mintToken = await createMint({provider, authority, mint})
//     console.log('mintToken', mintToken)

//     const accountToken = await createTokenAccount({provider, owner: account, mint, account})
//     console.log('accountToken', accountToken)

//     const accountTokenMint = await createMintTo({mint, destination: account})
//     console.log('accountTokenMint', accountTokenMint)

//     // const tokenTransfer = await createTransfer({
//     //   source: mint, 
//     //   destination: dest, 
//     //   owner: authority,
//     // })
//     // console.log('tokenTransfer', tokenTransfer)
    

//   });
// });

