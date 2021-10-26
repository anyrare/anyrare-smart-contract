import * as anchor from "@project-serum/anchor";
import { TOKEN_PROGRAM_ID } from "@solana/spl-token";
import { assert } from "chai";

describe("Token Proxy", () => {
  const provider = anchor.Provider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.TokenProxy;

  const mint = anchor.web3.Keypair.generate();
  const account = anchor.web3.Keypair.generate();
  const authority = anchor.web3.Keypair.generate();
  const rent = anchor.web3.Keypair.generate();

  it("proxyInitializeMint", async () => {
    await provider.connection.confirmTransaction(
      await provider.connection.requestAirdrop(authority.publicKey, 2000000000),
      "confirmed"
    );
    const sleep = t => new Promise(s => setTimeout(s, t));
    await sleep(10000);
    await provider.connection.confirmTransaction(
      await provider.connection.requestAirdrop(rent.publicKey, 2000000000),
      "confirmed"
    );

    const result = await program.rpc.proxyInitializeMint(
      0,
      authority.publicKey,
      {
        accounts: {
          authority: authority.publicKey,
          account: account.publicKey,
          mint: mint.publicKey,
          rent: rent.publicKey,
          tokenProgram: TOKEN_PROGRAM_ID
        },
        signers: [authority],
      }
    );

    console.log(result);

  });
});
