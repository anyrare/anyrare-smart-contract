import * as web3 from "@solana/web3.js";
import * as splToken from "@solana/spl-token";

describe("Token", async () => {
  const connection = new web3.Connection(
    web3.clusterApiUrl('devnet'),
    'confirmed'
  );

  const fromWallet = web3.Keypair.generate();
  const toWallet = web3.Keypair.generate();
  await connection.confirmTransaction(
    await connection.requestAirdrop(
      fromWallet.publicKey,
      web3.LAMPORTS_PER_SOL
    )
  );

  const mint = await splToken.Token.createMint(
    connection,
    fromWallet,
    fromWallet.publicKey,
    null,
    0,
    splToken.TOKEN_PROGRAM_ID
  );

  const fromTokenAccount = await mint.getOrCreateAssociatedAccountInfo(
    fromWallet.publicKey,
  );
  const toTokenAccount = await mint.getOrCreateAssociatedAccountInfo(
    toWallet.publicKey,
  );

  await mint.mintTo(
    fromTokenAccount.address,
    fromWallet.publicKey,
    [],
    100
  );

  const transaction = new web3.Transaction().add(
    splToken.Token.createTransferInstruction(
      splToken.TOKEN_PROGRAM_ID,
      fromTokenAccount.address,
      toTokenAccount.address,
      fromWallet.publicKey,
      [],
      1
    )
  );
  const signature = await web3.sendAndConfirmTransaction(
    connection,
    transaction,
    [fromWallet],
    { commitment: 'confirmed' }
  );

  const setAuthorityResult = await mint.setAuthority(
    fromTokenAccount.address,
    new web3.PublicKey(0),
    'AccountOwner',
    fromWallet.publicKey,
    []
  );

  console.log('fromWallet', fromWallet.publicKey);
  console.log('toWallet', toWallet.publicKey);
  console.log('fromTokenAccount', fromTokenAccount.address);
  console.log('toTokenAccount', toTokenAccount.address);
  console.log('mint', mint.publicKey);
})