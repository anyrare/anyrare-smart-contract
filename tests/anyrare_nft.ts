import * as anchor from "@project-serum/anchor";
import * as serumCmn from "@project-serum/common";
import { TOKEN_PROGRAM_ID } from "@solana/spl-token";
import { assert } from "chai";

describe("cahiers-check", () => {
  const provider = anchor.Provider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.CashiersCheck;

  let mint = null;
  let god = null;
  let receiver = null;

  it("Sets up initial test state", async () => {
    const [_mint, _god] = await serumCmn.createMintAndVault(
      program.provider,
      new anchor.BN(1),
      program.provider.wallet.publicKey,
      0
    );
    mint = _mint;
    god = _god;
    console.log(_mint, _god)

    receiver = await serumCmn.createTokenAccount(
      program.provider,
      mint,
      program.provider.wallet.publicKey
    );
    console.log('receiver', receiver)
  });

  const check = anchor.web3.Keypair.generate();
  const vault = anchor.web3.Keypair.generate();

  let checkSigner = null;

  
});
