import * as assert from "assert";
import * as anchor from "@project-serum/anchor";
import * as serumCmn from "@project-serum/common";
import { TOKEN_PROGRAM_ID, Token, MintLayout, ASSOCIATED_TOKEN_PROGRAM_ID } from "@solana/spl-token";
import { PublicKey, SystemProgram, sendAndConfirmTransaction } from "@solana/web3.js";
import {
   Connection, Account, programs } from '@metaplex/js';
const { metaplex: { Store, AuctionManager }, metadata: { Metadata }, auction: { Auction }, vault: { Vault } } = programs;



describe("Token", () => {
  const provider = anchor.Provider.env();
  anchor.setProvider(provider);
  const connection = new anchor.web3.Connection(
    anchor.web3.clusterApiUrl('devnet'),
    'confirmed'
  );

  it("Test 1", async () => {
    const FEE_PAYER = anchor.web3.Keypair.fromSecretKey(
      new Uint8Array([63,225,194,54,125,230,26,89,204,84,245,177,30,95,156,208,137,11,106,33,14,225,159,78,189,250,250,133,223,166,93,31,139,233,247,216,10,249,105,21,158,127,231,186,89,173,121,168,100,85,96,69,124,150,255,139,243,148,192,180,166,130,94,136])
    );
    const mint = anchor.web3.Keypair.generate();
    const owner = anchor.web3.Keypair.generate();
    console.log('FEE_PAYER', FEE_PAYER.publicKey.toString());
    console.log('mint', mint.publicKey.toString());
    console.log('owner', owner.publicKey.toString());

    const metadataPDA = await Metadata.getPDA(mint.publicKey);
    const editionPDA = await programs.metadata.MasterEdition.getPDA(mint.publicKey);
    const mintRent = await connection.getMinimumBalanceForRentExemption(MintLayout.span);

    const createMintTx = new programs.CreateMint(
      { feePayer: FEE_PAYER.publicKey },
      {
        newAccountPubkey: mint.publicKey,
        lamports: mintRent,
        decimals: 0,
        owner: FEE_PAYER.publicKey,
        freezeAuthority: FEE_PAYER.publicKey,
      }
    );
    const metadataData = new programs.metadata.MetadataDataData({
      name: 'Test',
      symbol: 'T112',
      uri: 'https://oieckdm2fptw3xzl6fiynca7wkxuineqx6nfzafqvfzbrynipljq.arweave.net/cgglDZor523fK_FRhogfsq9ENJC_mlyAsKlyGOGoetM/',
      sellerFeeBasisPoints: 300,
      creators: null,
    });
    const tx = new programs.metadata.CreateMetadata(
      { feePayer: FEE_PAYER.publicKey },
      {
        metadata: metadataPDA,
        metadataData,
        updateAuthority: owner.publicKey,
        mint: mint.publicKey,
        mintAuthority: FEE_PAYER.publicKey
      }
    );
    const txs = programs.Transaction.fromCombined([createMintTx, tx]);
    
    const resultMint = await sendAndConfirmTransaction(connection, txs, [FEE_PAYER, mint, owner], {
      commitment: 'confirmed'
    });
    console.log('resultMint', resultMint);

    const [recipient] = await anchor.web3.PublicKey.findProgramAddress(
      [FEE_PAYER.publicKey.toBuffer(), TOKEN_PROGRAM_ID.toBuffer(), mint.publicKey.toBuffer()],
      ASSOCIATED_TOKEN_PROGRAM_ID
    );
    console.log('recipient', recipient.toString());

    const createAssociatedTokenAccountTx = new programs.CreateAssociatedTokenAccount(
      { feePayer: FEE_PAYER.publicKey },
      {
        associatedTokenAddress: recipient,
        splTokenMintAddress: mint.publicKey,
      },
    );

    const mintToTx = new programs.MintTo(
      { feePayer: FEE_PAYER.publicKey },
      {
        mint: mint.publicKey,
        dest: recipient,
        amount: 1,
      }
    );

    const tx2 = new programs.metadata.CreateMasterEdition(
      { feePayer: FEE_PAYER.publicKey },
      {
        edition: editionPDA,
        metadata: metadataPDA,
        updateAuthority: owner.publicKey,
        mint: mint.publicKey,
        mintAuthority: FEE_PAYER.publicKey,
        maxSupply: new anchor.BN(1),
      }
    );

    const tx3 = new anchor.web3.Transaction();
    tx3.add(Token.createSetAuthorityInstruction(
      TOKEN_PROGRAM_ID,
      mint.publicKey,
      null,
      'MintTokens',
      owner.publicKey,
      []
    ))
    console.log('tx3', tx3)

    const txs2 = programs.Transaction.fromCombined([createAssociatedTokenAccountTx, mintToTx, tx2, tx3 ]);
    const resultMint2 = await sendAndConfirmTransaction(connection, txs2, [FEE_PAYER, owner], {
      commitment: 'confirmed'
    });
    console.log('resultMint2', resultMint2)
  })
})

