import * as web3 from "@solana/web3.js";
import * as splToken from "@solana/spl-token";
import { BinaryReader, BinaryWriter, deserializeUnchecked } from "borsh";
import base58 from "bs58";
import { PublicKey, SystemProgram, SYSVAR_RENT_PUBKEY, TransactionInstruction } from "@solana/web3.js";
import * as anchor from '@project-serum/anchor';
import { serialize } from 'borsh';
import { BN } from '@project-serum/anchor';

const tokenAddress = new web3.PublicKey(
  "2aQDuqziMoPVY6BffAWPQVhcKhDPVfrg2eGs8pLYH8zf"
);

export const METADATA_PROGRAM_ID =
  "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s";
export const METADATA_PREFIX = "metadata";

export const TOKEN_METADATA_PROGRAM_ID = new PublicKey(
  'metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s',
);

export function createMetadataInstruction(
  metadataAccount: PublicKey,
  mint: PublicKey,
  mintAuthority: PublicKey,
  payer: PublicKey,
  updateAuthority: PublicKey,
  txnData: Buffer,
) {
  const keys = [
    {
      pubkey: metadataAccount,
      isSigner: false,
      isWritable: true,
    },
    {
      pubkey: mint,
      isSigner: false,
      isWritable: false,
    },
    {
      pubkey: mintAuthority,
      isSigner: true,
      isWritable: false,
    },
    {
      pubkey: payer,
      isSigner: true,
      isWritable: false,
    },
    {
      pubkey: updateAuthority,
      isSigner: false,
      isWritable: false,
    },
    {
      pubkey: SystemProgram.programId,
      isSigner: false,
      isWritable: false,
    },
    {
      pubkey: SYSVAR_RENT_PUBKEY,
      isSigner: false,
      isWritable: false,
    },
  ];
  return new TransactionInstruction({
    keys,
    programId: TOKEN_METADATA_PROGRAM_ID,
    data: txnData,
  });
}

export const getMetadata = async (
  mint: anchor.web3.PublicKey,
): Promise<anchor.web3.PublicKey> => {
  return (
    await anchor.web3.PublicKey.findProgramAddress(
      [
        Buffer.from('metadata'),
        TOKEN_METADATA_PROGRAM_ID.toBuffer(),
        mint.toBuffer(),
      ],
      TOKEN_METADATA_PROGRAM_ID,
    )
  )[0];
};

type StringPublicKey = string;
export class Creator {
  address: StringPublicKey;
  verified: number;
  share: number;

  constructor(args: {
    address: StringPublicKey;
    verified: number;
    share: number;
  }) {
    this.address = args.address;
    this.verified = args.verified;
    this.share = args.share;
  }
}
export class Data {
  name: string;
  symbol: string;
  uri: string;
  sellerFeeBasisPoints: number;
  creators: Creator[] | null;
  constructor(args: {
    name: string;
    symbol: string;
    uri: string;
    sellerFeeBasisPoints: number;
    creators: Creator[] | null;
  }) {
    this.name = args.name;
    this.symbol = args.symbol;
    this.uri = args.uri;
    this.sellerFeeBasisPoints = args.sellerFeeBasisPoints;
    this.creators = args.creators;
  }
}
export class CreateMetadataArgs {
  instruction: number = 0;
  data: Data;
  isMutable: boolean;

  constructor(args: { data: Data; isMutable: boolean }) {
    this.data = args.data;
    this.isMutable = args.isMutable;
  }
}

export const METADATA_SCHEMA = new Map<any, any>([
  [
    CreateMetadataArgs,
    {
      kind: 'struct',
      fields: [
        ['instruction', 'u8'],
        // ['data', Data],
        ['isMutable', 'u8'], // bool
      ],
    },
  ],
]);

export const createMetadata = async (metadataLink: string) => {
  // Metadata
  let metadata;
  try {
    metadata = {"name":"Chaz","symbol":"","description":"Chaz is on his game!!","seller_fee_basis_points":2000,"image":"Nkechi_AfroFitness_Seshlist_Thumbnail.png","animation_url":"https://www.arweave.net/94Y7wPUI5ME9fXMpVnolMQ2-I8KSTCSJTz0zyt0S8yA?ext=mp4","attributes":[{"trait_type":"Author","value":"Chaz Bruce"}],"external_url":"","properties":{"files":[{"uri":"Nkechi_AfroFitness_Seshlist_Thumbnail.png","type":"image/png"},{"uri":"https://www.arweave.net/94Y7wPUI5ME9fXMpVnolMQ2-I8KSTCSJTz0zyt0S8yA?ext=mp4","type":"video/mp4"}],"category":"video","creators":[{"address":"2NCZuPwjCnEzZiFspvUZAeW9E36aLLWpn92VxunKTRQQ","share":100}]}}
  } catch (e) {
    console.log(e);
    console.log('Invalid metadata at', metadataLink);
    return;
  }

  // Validate metadata
  if (
    !metadata.name ||
    !metadata.image ||
    isNaN(metadata.seller_fee_basis_points) ||
    !metadata.properties ||
    !Array.isArray(metadata.properties.creators)
  ) {
    console.log('Invalid metadata file', metadata);
    return;
  }

  // Validate creators
  const metaCreators = metadata.properties.creators;
  if (
    metaCreators.some(creator => !creator.address) ||
    metaCreators.reduce((sum, creator) => creator.share + sum, 0) !== 100
  ) {
    return;
  }

  const creators = metaCreators.map(
    creator =>
      new Creator({
        address: creator.address,
        share: creator.share,
        verified: 1,
      }),
  );

  return new Data({
    symbol: metadata.symbol,
    name: metadata.name,
    uri: metadataLink,
    sellerFeeBasisPoints: metadata.seller_fee_basis_points,
    creators: creators,
  });
};

export class CreateMasterEditionArgs {
  instruction: number = 10;
  maxSupply: BN | null;
  constructor(args: { maxSupply: BN | null }) {
    this.maxSupply = args.maxSupply;
  }
}

export class UpdateMetadataArgs {
  instruction: number = 1;
  data: Data | null;
  // Not used by this app, just required for instruction
  updateAuthority: StringPublicKey | null;
  primarySaleHappened: boolean | null;
  constructor(args: {
    data?: Data;
    updateAuthority?: string;
    primarySaleHappened: boolean | null;
  }) {
    this.data = args.data ? args.data : null;
    this.updateAuthority = args.updateAuthority ? args.updateAuthority : null;
    this.primarySaleHappened = args.primarySaleHappened;
  }
}

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

  const setAuthorityResult = await mint.setAuthority(
    mint.publicKey,
    null,
    'MintTokens',
    fromWallet.publicKey,
    []
  );

  const data = await createMetadata('https://oieckdm2fptw3xzl6fiynca7wkxuineqx6nfzafqvfzbrynipljq.arweave.net/cgglDZor523fK_FRhogfsq9ENJC_mlyAsKlyGOGoetM/');
  console.log('data', data)
  const metadataAccount = await getMetadata(mint.publicKey);
  console.log('metadataAccount', metadataAccount.toString());

  const metadataArgs = new CreateMetadataArgs({ data, isMutable: true })
  console.log('metadataArgs', metadataArgs.data);
  console.log('txn1', METADATA_SCHEMA);
  let txnData = Buffer.from(
    serialize(
      METADATA_SCHEMA, metadataArgs
    ),
  );

  const instructions: TransactionInstruction[] = [];
  instructions.push(
    createMetadataInstruction(
      metadataAccount,
      mint.publicKey,
      mint.publicKey,
      mint.publicKey,
      mint.publicKey,
      txnData,
    ),
  );

  console.log(instructions)
  // await web3.sendAndConfirmTransaction(
  //   connection,
  //   instructions,
  //   [fromWallet],
  //   { commitment: 'confirmed' }
  // );
  

  const transactions = [
    splToken.Token.createTransferInstruction(
      splToken.TOKEN_PROGRAM_ID,
      fromTokenAccount.address,
      toTokenAccount.address,
      fromWallet.publicKey,
      [],
      1
    )
  ]
  console.log('transaction', transactions)

  const transaction = new web3.Transaction();
  transaction.add(...transactions);

  const signature = await web3.sendAndConfirmTransaction(
    connection,
    transaction,
    [fromWallet],
    { commitment: 'confirmed' }
  );

  console.log('METADATA_PROGRAM_ID', METADATA_PROGRAM_ID.toString());
  console.log('fromWallet', fromWallet.publicKey.toString());
  console.log('toWallet', toWallet.publicKey.toString());
  console.log('fromTokenAccount', fromTokenAccount.address.toString());
  console.log('toTokenAccount', toTokenAccount.address.toString());
  console.log('mint', mint.publicKey.toString());

})