const anchor = require('@project-serum/anchor');

describe('anchor-0', () => {

  // Configure the client to use the local cluster.
  anchor.setProvider(anchor.Provider.env());

  it('Is initialized!', async () => {
    // Add your test here.
    const program = anchor.workspace.Anchor0;
    const tx = await program.rpc.initialize();
    console.log("Your transaction signature", tx);
  });
});
