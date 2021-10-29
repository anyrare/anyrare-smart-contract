import * as assert from "assert";
import * as anchor from "@project-serum/anchor";

const { SystemProgram } = anchor.web3;

describe("Token", () => {
  const provider = anchor.Provider.env();
  anchor.setProvider(provider);

  it("Test 1", async () => {
    const idl = JSON.parse(require('fs').readFileSync('./target/idl/token_proxy.json', 'utf8'));
    const programId = new anchor.web3.PublicKey('6rjgvbtaPZLSiaiH7pUSsriRxg9it7YtUzdkvKXDTDLH')
    const program = new anchor.Program(idl, programId);

    const founderKeyPair = anchor.web3.Keypair.fromSecretKey(
      new Uint8Array([51,190,244,181,179,97,228,73,4,91,162,143,62,103,167,123,7,8,114,51,251,135,244,87,139,155,192,138,139,186,231,106,139,233,247,171,221,86,20,22,171,6,68,55,86,159,4,245,84,117,178,171,69,171,110,179,133,181,110,220,151,90,3,53])
    );
    const auditorKeyPair = anchor.web3.Keypair.fromSecretKey(
      new Uint8Array([63,225,194,54,125,230,26,89,204,84,245,177,30,95,156,208,137,11,106,33,14,225,159,78,189,250,250,133,223,166,93,31,139,233,247,216,10,249,105,21,158,127,231,186,89,173,121,168,100,85,96,69,124,150,255,139,243,148,192,180,166,130,94,136])
    );
    const custodianKeyPair = anchor.web3.Keypair.fromSecretKey(
      new Uint8Array([185,99,56,231,152,246,197,130,6,179,53,142,152,98,165,74,43,65,147,25,203,21,149,83,218,80,44,28,102,153,113,145,139,233,250,51,211,95,117,251,117,25,93,3,131,204,190,94,43,53,68,144,56,53,241,203,68,60,75,54,110,161,207,109])
    )
    const tokenKeyPair = anchor.web3.Keypair.generate();
    const programKeyPair = anchor.web3.Keypair.generate();

    console.log('founderKeyPair', founderKeyPair.publicKey.toString())
    console.log('programKeyPair', programKeyPair.publicKey.toString())
    console.log('providerWallet', provider.wallet.publicKey.toString())

    try {
      await program.rpc.create(
        founderKeyPair.publicKey,
        custodianKeyPair.publicKey,
        auditorKeyPair.publicKey,
        tokenKeyPair.publicKey,
        {
          accounts: {
            contract: programKeyPair.publicKey,
            user: provider.wallet.publicKey,
            systemProgram: SystemProgram.programId,
          },
          signers: [programKeyPair]
        }
      ) 
    } catch (e) { console.error(e); }

    const result0 = await program.account.contract.fetch(programKeyPair.publicKey);
    console.log('result0', result0);

    try {
      await program.rpc.auditorSign(
        {
          accounts: {
            contract: programKeyPair.publicKey,
            auditor: auditorKeyPair.publicKey,
          },
          signers: [auditorKeyPair]
        }
      )
    } catch (e) { console.error('auditorSign', e); }

    const result1 = await program.account.contract.fetch(programKeyPair.publicKey);
    console.log('result1', result1);

    try {
      await program.rpc.custodianSign(
        {
          accounts: {
            contract: programKeyPair.publicKey,
            custodian: custodianKeyPair.publicKey,
          },
          signers: [custodianKeyPair]
        }
      )
    } catch (e) { console.error('custodianSign', e); }

    const result2 = await program.account.contract.fetch(programKeyPair.publicKey);
    console.log('result1', result2);
  })
})