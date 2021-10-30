import * as assert from "assert";
import * as anchor from "@project-serum/anchor";
import * as serumCmn from "@project-serum/common";
import { TOKEN_PROGRAM_ID, Token, MintLayout } from "@solana/spl-token";
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
    const mintRent = await connection.getMinimumBalanceForRentExemption(MintLayout.span);

    const createMintTx = new programs.CreateMint(
      { feePayer: FEE_PAYER.publicKey },
      {
        newAccountPubkey: mint.publicKey,
        lamports: mintRent
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
  })
})

