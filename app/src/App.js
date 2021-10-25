import './App.css';
import { useState } from 'react';
import { Connection, PublicKey, clusterApiUrl } from '@solana/web3.js';
import {
  Program, Provider, web3
} from '@project-serum/anchor';
import idl from './idl.json';
import kp from './keypair.json'

import { getPhantomWallet } from '@solana/wallet-adapter-wallets';
import { useWallet, WalletProvider, ConnectionProvider } from '@solana/wallet-adapter-react';
import { WalletModalProvider, WalletMultiButton } from '@solana/wallet-adapter-react-ui';

const wallets = [
  /* view list of available wallets at https://github.com/solana-labs/wallet-adapter#wallets */
  getPhantomWallet()
]

const { SystemProgram, Keypair } = web3;
/* create an account  */
const arr = Object.values(kp._keypair.secretKey)
const secret = new Uint8Array(arr)
const baseAccount = web3.Keypair.fromSecretKey(secret)

// const baseAccount = Keypair.generate();
const opts = {
  preflightCommitment: "processed"
}
const programID = new PublicKey(idl.metadata.address);
const network = clusterApiUrl('devnet');

function App() {
  const [value, setValue] = useState(null);
  const wallet = useWallet();

  async function getProvider() {
    /* create the provider and return it to the caller */
    /* network set to local network for now */
    const connection = new Connection(network, opts.preflightCommitment);

    const provider = new Provider(
      connection, wallet, opts.preflightCommitment,
    );
    return provider;
  }

  async function create() {    
    const provider = await getProvider()
    /* create the program interface combining the idl, program ID, and provider */
    const program = new Program(idl, programID, provider);
    try {
      /* interact with the program via rpc */
      console.log(new PublicKey('D7KiKkBWh8LVX7DyvTAjKejDAQcZJE3BBUW1paUfGkWY'))
      const result = await program.rpc.create(
        'Test Asset',
        baseAccount.publicKey,
        baseAccount.publicKey,
        new PublicKey('D7KiKkBWh8LVX7DyvTAjKejDAQcZJE3BBUW1paUfGkWY'),
        baseAccount.publicKey,
        baseAccount.publicKey,
        baseAccount.publicKey,
        10,
        3,
        2,
        'QmR8Leqyv5iThoMyEyksxsaPqk27jJ3UCzAfeRyVoZ5DpT',
        {
        accounts: {
          asset: baseAccount.publicKey,
          user: provider.wallet.publicKey,
          systemProgram: SystemProgram.programId,

        },
        signers: [baseAccount],
      });

      console.log(result);

      const asset = await program.account.asset.fetch(baseAccount.publicKey);
      console.log('asset: ', asset);
      setValue(asset.assetName);
    } catch (err) {
      console.log("Transaction error: ", err);
    }
  }

  async function auditorSign() {
    const provider = await getProvider();
    const program = new Program(idl, programID, provider);
    console.log(baseAccount.publicKey)
    const result = await program.rpc.auditorSign({
      accounts: {
        asset: baseAccount.publicKey,
        auditorId: provider.wallet.publicKey,
      }
    });
    console.log(result)

    const asset = await program.account.asset.fetch(baseAccount.publicKey);
    console.log('asset: ', asset);
    setValue(asset.assetName);
  }

  async function transfer() {
    const provider = await getProvider();
    const program = new Program(idl, programID, provider);
    console.log(baseAccount.publicKey)
    await program.rpc.transfer({
      accounts: {
        baseAccount: baseAccount.publicKey,
        receiver: baseAccount.publicKey,
      }
    });

    const account = await program.account.baseAccount.fetch(baseAccount.publicKey);
    console.log('account: ', account);
    setValue(account.asset_name.toString());
  }

  if (!wallet.connected) {
    /* If the user's wallet is not connected, display connect wallet button. */
    return (
      <div style={{ display: 'flex', justifyContent: 'center', marginTop:'100px' }}>
        <WalletMultiButton />
      </div>
    )
  } else {
    return (
      <div className="App">
        <div>
          {
            (<button onClick={create}>create</button>)
          }
          {
             <button onClick={auditorSign}>auditorSign</button>
          }
          {
             <button onClick={transfer}>transfer</button>
          }

          {
            value ? (
              <h2>{value}</h2>
            ) : (
              <h3>Please create</h3>
            )
          }
        </div>
      </div>
    );
  }
}

const AppWithProvider = () => (
  <ConnectionProvider endpoint={network}>
    <WalletProvider wallets={wallets} autoConnect>
      <WalletModalProvider>
        <App />
      </WalletModalProvider>
    </WalletProvider>
  </ConnectionProvider>
)

export default AppWithProvider;