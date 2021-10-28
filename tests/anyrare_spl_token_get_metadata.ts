// import * as web3 from "@solana/web3.js";
// import * as splToken from "@solana/spl-token";
// import { BinaryReader, BinaryWriter, deserializeUnchecked } from "borsh";
// import base58 from "bs58";
// import { PublicKey } from "@solana/web3.js";

// const tokenAddress = new web3.PublicKey(
//   "2aQDuqziMoPVY6BffAWPQVhcKhDPVfrg2eGs8pLYH8zf"
// );


// describe("Token", async () => {
//   const connection = new web3.Connection(
//     web3.clusterApiUrl('devnet'),
//     'confirmed'
//   );

//   const fromWallet = web3.Keypair.generate();
//   const toWallet = web3.Keypair.generate();
//   await connection.confirmTransaction(
//     await connection.requestAirdrop(
//       fromWallet.publicKey,
//       web3.LAMPORTS_PER_SOL
//     )
//   );

//   const mint = await splToken.Token.createMint(
//     connection,
//     fromWallet,
//     fromWallet.publicKey,
//     null,
//     0,
//     splToken.TOKEN_PROGRAM_ID
//   );

//   const fromTokenAccount = await mint.getOrCreateAssociatedAccountInfo(
//     fromWallet.publicKey,
//   );
//   const toTokenAccount = await mint.getOrCreateAssociatedAccountInfo(
//     toWallet.publicKey,
//   );

//   await mint.mintTo(
//     fromTokenAccount.address,
//     fromWallet.publicKey,
//     [],
//     100
//   );

//   const setAuthorityResult = await mint.setAuthority(
//     mint.publicKey,
//     null,
//     'MintTokens',
//     fromWallet.publicKey,
//     []
//   );

//   const transactions = [
//     splToken.Token.createTransferInstruction(
//       splToken.TOKEN_PROGRAM_ID,
//       fromTokenAccount.address,
//       toTokenAccount.address,
//       fromWallet.publicKey,
//       [],
//       1
//     )
//   ]

//   const transaction = new web3.Transaction();
//   transaction.add(...transactions);

//   const signature = await web3.sendAndConfirmTransaction(
//     connection,
//     transaction,
//     [fromWallet],
//     { commitment: 'confirmed' }
//   );


//   // const metadataProgram = await web3.PublicKey.findProgramAddress(
//   //   [Buffer.from("Token Metadata Program")],
//   //   METADATA_PROGRAM_ID
//   // );

//   // console.log(metadataProgram)
//   console.log('METADATA_PROGRAM_ID', METADATA_PROGRAM_ID.toString());
//   console.log('fromWallet', fromWallet.publicKey.toString());
//   console.log('toWallet', toWallet.publicKey.toString());
//   console.log('fromTokenAccount', fromTokenAccount.address.toString());
//   console.log('toTokenAccount', toTokenAccount.address.toString());
//   console.log('mint', mint.publicKey.toString());


//   const m = await getMetadataAccount("2aQDuqziMoPVY6BffAWPQVhcKhDPVfrg2eGs8pLYH8zf");
//   console.log("metadata acc: ", m);
  
//   const accInfo = await connection.getAccountInfo(new web3.PublicKey(m));
//   console.log(accInfo);

//   console.log(decodeMetadata(accInfo!.data));
// })

// export const METADATA_PROGRAM_ID =
//   "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s" as StringPublicKey;
// export const METADATA_PREFIX = "metadata";

// const PubKeysInternedMap = new Map<string, PublicKey>();

// // Borsh extension for pubkey stuff
// (BinaryReader.prototype as any).readPubkey = function () {
//   const reader = this as unknown as BinaryReader;
//   const array = reader.readFixedArray(32);
//   return new PublicKey(array);
// };

// (BinaryWriter.prototype as any).writePubkey = function (value: PublicKey) {
//   const writer = this as unknown as BinaryWriter;
//   writer.writeFixedArray(value.toBuffer());
// };

// (BinaryReader.prototype as any).readPubkeyAsString = function () {
//   const reader = this as unknown as BinaryReader;
//   const array = reader.readFixedArray(32);
//   return base58.encode(array) as StringPublicKey;
// };

// (BinaryWriter.prototype as any).writePubkeyAsString = function (
//   value: StringPublicKey
// ) {
//   const writer = this as unknown as BinaryWriter;
//   writer.writeFixedArray(base58.decode(value));
// };

// const toPublicKey = (key: string | PublicKey) => {
//   if (typeof key !== "string") {
//     return key;
//   }

//   let result = PubKeysInternedMap.get(key);
//   if (!result) {
//     result = new PublicKey(key);
//     PubKeysInternedMap.set(key, result);
//   }

//   return result;
// };

// const findProgramAddress = async (
//   seeds: (Buffer | Uint8Array)[],
//   programId: PublicKey
// ) => {
//   const key =
//     "pda-" +
//     seeds.reduce((agg, item) => agg + item.toString("hex"), "") +
//     programId.toString();

//   const result = await PublicKey.findProgramAddress(seeds, programId);

//   return [result[0].toBase58(), result[1]] as [string, number];
// };

// export type StringPublicKey = string;

// export enum MetadataKey {
//   Uninitialized = 0,
//   MetadataV1 = 4,
//   EditionV1 = 1,
//   MasterEditionV1 = 2,
//   MasterEditionV2 = 6,
//   EditionMarker = 7,
// }

// class Creator {
//   address: StringPublicKey;
//   verified: boolean;
//   share: number;

//   constructor(args: {
//     address: StringPublicKey;
//     verified: boolean;
//     share: number;
//   }) {
//     this.address = args.address;
//     this.verified = args.verified;
//     this.share = args.share;
//   }
// }

// class Data {
//   name: string;
//   symbol: string;
//   uri: string;
//   sellerFeeBasisPoints: number;
//   creators: Creator[] | null;
//   constructor(args: {
//     name: string;
//     symbol: string;
//     uri: string;
//     sellerFeeBasisPoints: number;
//     creators: Creator[] | null;
//   }) {
//     this.name = args.name;
//     this.symbol = args.symbol;
//     this.uri = args.uri;
//     this.sellerFeeBasisPoints = args.sellerFeeBasisPoints;
//     this.creators = args.creators;
//   }
// }

// class Metadata {
//   key: MetadataKey;
//   updateAuthority: StringPublicKey;
//   mint: StringPublicKey;
//   data: Data;
//   primarySaleHappened: boolean;
//   isMutable: boolean;
//   editionNonce: number | null;

//   // set lazy
//   masterEdition?: StringPublicKey;
//   edition?: StringPublicKey;

//   constructor(args: {
//     updateAuthority: StringPublicKey;
//     mint: StringPublicKey;
//     data: Data;
//     primarySaleHappened: boolean;
//     isMutable: boolean;
//     editionNonce: number | null;
//   }) {
//     this.key = MetadataKey.MetadataV1;
//     this.updateAuthority = args.updateAuthority;
//     this.mint = args.mint;
//     this.data = args.data;
//     this.primarySaleHappened = args.primarySaleHappened;
//     this.isMutable = args.isMutable;
//     this.editionNonce = args.editionNonce;
//   }
// }

// const METADATA_SCHEMA = new Map<any, any>([
//   [
//     Data,
//     {
//       kind: "struct",
//       fields: [
//         ["name", "string"],
//         ["symbol", "string"],
//         ["uri", "string"],
//         ["sellerFeeBasisPoints", "u16"],
//         ["creators", { kind: "option", type: [Creator] }],
//       ],
//     },
//   ],
//   [
//     Creator,
//     {
//       kind: "struct",
//       fields: [
//         ["address", "pubkeyAsString"],
//         ["verified", "u8"],
//         ["share", "u8"],
//       ],
//     },
//   ],
//   [
//     Metadata,
//     {
//       kind: "struct",
//       fields: [
//         ["key", "u8"],
//         ["updateAuthority", "pubkeyAsString"],
//         ["mint", "pubkeyAsString"],
//         ["data", Data],
//         ["primarySaleHappened", "u8"], // bool
//         ["isMutable", "u8"], // bool
//       ],
//     },
//   ],
// ]);

// export async function getMetadataAccount(
//   tokenMint: StringPublicKey
// ): Promise<StringPublicKey> {
//   return (
//     await findProgramAddress(
//       [
//         Buffer.from(METADATA_PREFIX),
//         toPublicKey(METADATA_PROGRAM_ID).toBuffer(),
//         toPublicKey(tokenMint).toBuffer(),
//       ],
//       toPublicKey(METADATA_PROGRAM_ID)
//     )
//   )[0];
// }

// const METADATA_REPLACE = new RegExp("\u0000", "g");
// export const decodeMetadata = (buffer: Buffer): Metadata => {
//   const metadata = deserializeUnchecked(
//     METADATA_SCHEMA,
//     Metadata,
//     buffer
//   ) as Metadata;

//   metadata.data.name = metadata.data.name.replace(METADATA_REPLACE, "");
//   metadata.data.uri = metadata.data.uri.replace(METADATA_REPLACE, "");
//   metadata.data.symbol = metadata.data.symbol.replace(METADATA_REPLACE, "");
//   return metadata;
// };