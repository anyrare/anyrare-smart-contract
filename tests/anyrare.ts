import * as anchor from "@project-serum/anchor";
import { TOKEN_PROGRAM_ID, Token, MintLayout, ASSOCIATED_TOKEN_PROGRAM_ID } from "@solana/spl-token";
import { sendAndConfirmTransaction } from "@solana/web3.js";
import {  programs } from '@metaplex/js';
const { metaplex: { Store, AuctionManager }, metadata: { Metadata }, auction: { Auction }, vault: { Vault } } = programs;

describe("Token", () => {
  const provider = anchor.Provider.env();
  anchor.setProvider(provider);
  const connection = new anchor.web3.Connection(
    anchor.web3.clusterApiUrl('devnet'),
    'confirmed'
  );

  it("Test 1", async () => {
    const auditorKeyPair = anchor.web3.Keypair.fromSecretKey(
      new Uint8Array([63,225,194,54,125,230,26,89,204,84,245,177,30,95,156,208,137,11,106,33,14,225,159,78,189,250,250,133,223,166,93,31,139,233,247,216,10,249,105,21,158,127,231,186,89,173,121,168,100,85,96,69,124,150,255,139,243,148,192,180,166,130,94,136])
    );
    const founderKeyPair = anchor.web3.Keypair.fromSecretKey(
      new Uint8Array([98,82,231,165,171,47,42,186,153,215,216,137,44,75,201,132,99,191,185,165,26,173,53,34,86,1,169,184,242,205,160,243,139,233,128,176,91,123,71,210,97,161,63,2,184,149,221,234,193,139,48,55,180,47,201,23,111,63,71,76,23,102,84,235])
    );
    const mintKeyPair = anchor.web3.Keypair.generate();
    const toKeyPair = anchor.web3.Keypair.generate();
    console.log('auditorKeyPair', auditorKeyPair.publicKey.toString());
    console.log('founderKeyPair', founderKeyPair.publicKey.toString());
    console.log('mintKeyPair', mintKeyPair.publicKey.toString());

    const mintRent = await connection.getMinimumBalanceForRentExemption(MintLayout.span);
    const createMintTx = new programs.CreateMint(
      { feePayer: auditorKeyPair.publicKey },
      {
        newAccountPubkey: mintKeyPair.publicKey,
        lamports: mintRent,
        decimals: 0,
        owner: auditorKeyPair.publicKey,
        freezeAuthority: auditorKeyPair.publicKey,
      }
    );
    const metadataPDA = await Metadata.getPDA(mintKeyPair.publicKey);
    console.log('metadataPDA', metadataPDA);
    const editionPDA = await programs.metadata.MasterEdition.getPDA(mintKeyPair.publicKey);
    console.log('editionPDA', editionPDA);

    const metadataData = new programs.metadata.MetadataDataData({
      name: 'Test',
      symbol: 'T112',
      uri: 'https://v726lsvt4qa2icy2kqjwifivu367g6aye3fiehxbxos3bddbefyq.arweave.net/r_XlyrPkAaQLGlQTZBUVpv3zeBgmyoIe4bulsIxhIXE/',
      sellerFeeBasisPoints: null,
      creators: null,
    });
    const metadataTx = new programs.metadata.CreateMetadata(
      { feePayer: auditorKeyPair.publicKey },
      {
        metadata: metadataPDA,
        metadataData,
        updateAuthority: auditorKeyPair.publicKey,
        mint: mintKeyPair.publicKey,
        mintAuthority: auditorKeyPair.publicKey
      }
    );
    console.log('metadataTx', metadataTx)

    const [recipient] = await anchor.web3.PublicKey.findProgramAddress(
      [auditorKeyPair.publicKey.toBuffer(), TOKEN_PROGRAM_ID.toBuffer(), mintKeyPair.publicKey.toBuffer()],
      ASSOCIATED_TOKEN_PROGRAM_ID
    )
    console.log('recipient', recipient.toString())

    const createAssociatedTokenAccountTx = new programs.CreateAssociatedTokenAccount(
      { feePayer: auditorKeyPair.publicKey },
      {
        associatedTokenAddress: recipient,
        splTokenMintAddress: mintKeyPair.publicKey,
      },
    );
    console.log('createAssociatedTokenAccountTx', createAssociatedTokenAccountTx);

    const mintToTx = new programs.MintTo(
      { feePayer: auditorKeyPair.publicKey },
      {
        mint: mintKeyPair.publicKey,
        dest: recipient,
        amount: 1,
      }
    );
    console.log('mintToTx', mintToTx);

    const createMasterEdition = new programs.metadata.CreateMasterEdition(
      { feePayer: auditorKeyPair.publicKey },
      {
        edition: editionPDA,
        metadata: metadataPDA,
        updateAuthority: auditorKeyPair.publicKey,
        mint: mintKeyPair.publicKey,
        mintAuthority: auditorKeyPair.publicKey,
        maxSupply: new anchor.BN(1),
      }
    );
    console.log('createMasterEdition', createMasterEdition);

    const txs = programs.Transaction.fromCombined([
      createMintTx,
      metadataTx,
      createAssociatedTokenAccountTx,
      mintToTx,
      createMasterEdition,
    ]);

    const resultMint = await sendAndConfirmTransaction(connection, txs, [auditorKeyPair, mintKeyPair], {
      commitment: 'confirmed'
    });
    console.log('resultMint', resultMint);

    const myToken = new Token(
      connection,
      mintKeyPair.publicKey,
      TOKEN_PROGRAM_ID,
      auditorKeyPair,
    );
    console.log('myToken', myToken);
    
    const auditorTokenAccount = await myToken.getOrCreateAssociatedAccountInfo(
      auditorKeyPair.publicKey
    );

    console.log('auditorTokenAccount', auditorTokenAccount.address.toString());

    const myWallet = new anchor.web3.PublicKey("BX6bSXyxHiLR1yzKt527bE495DBQpNk98RYf9grQRuCS");
    console.log('myWallet', myWallet);

    const toTokenAccount = await myToken.getOrCreateAssociatedAccountInfo(
      myWallet
    );
    console.log('toTokenAccount', toTokenAccount.address.toString());

    const myTokenTransfer = await myToken.transfer(
      auditorTokenAccount.address,
      toTokenAccount.address,
      auditorKeyPair,
      [],
      1
    );
    console.log('myTokenTransfer', myTokenTransfer);

  })
})