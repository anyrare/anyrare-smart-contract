import * as assert from "assert";
import * as anchor from "@project-serum/anchor";
import * as serumCmn from "@project-serum/common";
import { TOKEN_PROGRAM_ID, Token } from "@solana/spl-token";
import { PublicKey } from "@solana/web3.js";
import {
  deserializeUnchecked, BinaryReader, BinaryWriter, serialize,
} from 'borsh';

const { SystemProgram } = anchor.web3;

const createMetadata = async (data, updateAuthority, mintKey: PublicKey, mintAuthorityKey, instructions, payer) => {
  const metadataProgramId = new anchor.web3.PublicKey(
    'GCUQ7oWCzgtRKnHnuJGxpr5XVeEkxYUXwTKYcqGtxLv4'
  )

  const metadataAccount = (
    await anchor.web3.PublicKey.findProgramAddress(
      [
        Buffer.from('metadata'),
        metadataProgramId.toBuffer(),
        mintKey.toBuffer(),
      ],
      metadataProgramId
    )
  )[0];

  console.log('createMetadata.metadataAccount', metadataAccount.toString());
  
  // TODO: Failed this line
  const value = new CreateMetadataArgs({ data: new Test({name: 'bin'}) })
  console.log('createMetadata.value', value)

  
  console.log('createMetadata.METADATA_SCHEMA', METADATA_SCHEMA);
  console.log('createMetadata.serialize', serialize(METADATA_SCHEMA, value));

  const txnData = Buffer.from(serialize(METADATA_SCHEMA, value));
  console.log('createMetadata.txnData', txnData);
}


describe("Token", () => {
  const provider = anchor.Provider.env();
  anchor.setProvider(provider);
  const connection = new anchor.web3.Connection(
    anchor.web3.clusterApiUrl('devnet'),
    'confirmed'
  );

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
    const mintKeyPair = anchor.web3.Keypair.generate();
    const programKeyPair = anchor.web3.Keypair.generate();

    console.log('founderKeyPair', founderKeyPair.publicKey.toString())
    console.log('programKeyPair', programKeyPair.publicKey.toString())
    console.log('auditorKeyPair', auditorKeyPair.publicKey.toString())
    console.log('providerWallet', provider.wallet.publicKey.toString())

    try {
      await program.rpc.create(
        founderKeyPair.publicKey,
        custodianKeyPair.publicKey,
        auditorKeyPair.publicKey,
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

    // const result0 = await program.account.contract.fetch(programKeyPair.publicKey);
    // console.log('result0', result0);


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

    // const result2 = await program.account.contract.fetch(programKeyPair.publicKey);
    // console.log('result2', result2);

    await connection.confirmTransaction(
      await connection.requestAirdrop(
        auditorKeyPair.publicKey,
        anchor.web3.LAMPORTS_PER_SOL
      )
    );
    const mint = await Token.createMint(
      connection,
      auditorKeyPair,
      auditorKeyPair.publicKey,
      null,
      0,
      TOKEN_PROGRAM_ID
    )
    console.log('mint', mint.publicKey.toString());

    const auditorTokenAccount = await mint.getOrCreateAssociatedAccountInfo(
      auditorKeyPair.publicKey
    )
    const founderTokenAccount = await mint.getOrCreateAssociatedAccountInfo(
      founderKeyPair.publicKey
    )
    await mint.mintTo(
      auditorTokenAccount.address,
      auditorKeyPair.publicKey,
      [],
      1
    )

    const metadataAccount = await createMetadata(
      new Data({
        symbol: "T123",
        name: "LP. TO Close Eye",
        uri: ' '.repeat(64),
        sellerFeeBasisPoints: 100,
        creators: {
          address: founderKeyPair.publicKey,
          verified: 1,
          share: 100
        }
      }),
      auditorKeyPair.publicKey,
      mint.publicKey,
      auditorKeyPair.publicKey,
      null,
      auditorKeyPair.publicKey
    )

    await mint.setAuthority(
      mint.publicKey,
      null,
      'MintTokens',
      auditorKeyPair.publicKey,
      []
    )

    await mint.transfer(
      auditorTokenAccount.address,
      founderTokenAccount.address,
      auditorKeyPair,
      [],
      1
    )


    // try {
    //   await program.rpc.auditorSign(
    //     {
    //       accounts: {
    //         contract: programKeyPair.publicKey,
    //         auditor: auditorKeyPair.publicKey,
    //         mint: mint.publicKey,
    //       },
    //       signers: [auditorKeyPair]
    //     }
    //   )
    // } catch (e) { console.error('auditorSign', e); }

    // const result1 = await program.account.contract.fetch(programKeyPair.publicKey);
    // console.log('result1', result1);


  })
})

class CreateMetadataArgs {
  data: Test;
  instruction: number;
  isMutable: boolean;
  constructor(args) {
    this.data = args.data;
    this.isMutable = args.isMutable;
    this.instruction = 0;
  }
}

class Creator {
  address: any;
  verified: number;
  share: number;
  constructor(args) {
    this.address = args.address;
    this.verified = args.verified;
    this.share = args.share;
  }
}
class Data {
  name: string;
  symbol: string;
  uri: string;
  sellerFeeBasisPoints: string;
  creators?: Creator;
  constructor(args) {
    this.name = args.name;
    this.symbol = args.symbol;
    this.uri = args.uri;
    this.sellerFeeBasisPoints = args.sellerFeeBasisPoints;
    this.creators = args.creators;
  }
}

class Test {
  name: string;
  constructor(args) {
    this.name = args.name;
  }
}

export const METADATA_SCHEMA = new Map([
  [
    CreateMetadataArgs,
    {
      kind: 'struct',
      fields: [
        ['instruction', 'u8'],
        ['data', Test],
        ['isMutable', 'u8'],
      ],
    },
  ],
]);
