# Anyrare Smart Contract

This project was written based on [Anyrare Whitepaper](https://github.com/anyrare/whitepaper).

To run this poject please use these command::

```
yarn install
yarn run hardhat:test
```

Other commands:
```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.ts
TS_NODE_FILES=true npx ts-node scripts/deploy.ts
npx eslint '**/*.{js,ts}'
npx eslint '**/*.{js,ts}' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

Contract address (Testnet):
```
MemberContract Addr: 0xe4E624C0137dBf1fB90Ed9BE08069142727ba965
GovernanceContract Addr: 0xb462230AbFAB8610AEe35516B4186d3BCBAE5eC5
BancorFormulaContract Addr: 0x6B9Fb38de9BD2A9621444e374873d070d2b1e715
CollateralTokenContract Addr: 0x3CB78C7C2E2F8070912BF0ad3e40Be7aC3411a1d
ARATokenContract Addr: 0x8f4dEdDfB5a29b4dafA133311a78677f1b90e102
ProposalContract Addr: 0xaE2D1a1d4CC05B0a3b42902Eb01FB92F6B890614
NFTFactoryContract Addr: 0xd2a9d52071B8dc324C0406355B3A2D507db3C6FC
NFTUtilsContract Addr: 0xfBb61f888Ec9B5DeD8E4565629CC4617FA4Ca772
CollectionFactoryContract Addr: 0x7b4A388AA5818b414ACbe8F2A4C707d7D3129bf8
CollectionUtils Addr: 0x405D239fa09FC98B0097C5c3f67660e94F6AC1B2
ManagementFundContract Addr: 0xF4E8909a734534a6195823F5A1cb8FdC168D745D
```

Emacs auto format
```
M x prettier-prettify
```
