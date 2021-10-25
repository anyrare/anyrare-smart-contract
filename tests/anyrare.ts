import * as anchor from "@project-serum/anchor";
import {
	PublicKey,
	SystemProgram,
  Transaction,
} from '@solana/web3.js';
import { TOKEN_PROGRAM_ID, Token } from "@solana/spl-token";
import { assert } from "chai";

describe("anyrare", () => {
  const provider = anchor.Provider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.Anyrare;

  const assetAccount = anchor.web3.Keypair.generate();
  const founderAccount = anchor.web3.Keypair.generate();
  const custodianAccount = anchor.web3.Keypair.generate();
  const auditorAccount = anchor.web3.Keypair.generate();

  it("Initialize asset", async () => {
    const result0 = await provider.connection.confirmTransaction(
      await provider.connection.requestAirdrop(founderAccount.publicKey, 2000000000),
      "confirmed"
    );

    console.log('founderAccount', founderAccount);
    console.log('provider.wallet', provider.wallet);
    const data = {
      accounts: {
        asset: founderAccount.publicKey,
        user: founderAccount.publicKey,
        systemProgram: SystemProgram.programId,
      },
      signers: [founderAccount],
    };
    console.log(data);

    const result1 = await program.rpc.initializeAsset(
      "พระนางพญา พิษณุโลก พ.ศ. 2401 หลวงปู่มั่น",
      "QmR8Leqyv5iThoMyEyksxsaPqk27jJ3UCzAfeRyVoZ5DpT",
      custodianAccount.publicKey,
      auditorAccount.publicKey,
      25,
      3,
      data,
    );
    console.log('result1', result1);

    const result2 = await program.account.asset.fetch(founderAccount.publicKey)
    console.log(result2)
    console.log(result2.founderAccount)
  });

});
