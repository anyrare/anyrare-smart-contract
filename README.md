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
MemberContract Addr: 0x5d36D46E206C9CF6DcD99c6d6535D48B7d46FA2B
GovernanceContract Addr: 0xe35ef9F5c3De0893eEE90136e15B75Eb74E3d44B
BancorFormulaContract Addr: 0x09ba8c19ED0789e6Ed6E0956E822037170fB3808
CollateralTokenContract Addr: 0x2071f3318FfA0630F24b980631D5d5C0cbc77750
ARATokenContract Addr: 0x7147cD9D84D950533f552f8EF37c1c6801e91c7D
ProposalContract Addr: 0xa4fF6a94859088855380BF394eef5445CA93174b
NFTFactoryContract Addr: 0x386Ea16F8f11488950F982f263bbc74cFCb1937D
NFTUtilsContract Addr: 0x01939b51d682B3B78a6BfBA8eb96B0F58a043096
CollectionFactoryContract Addr: 0x18aBCaFB34211a1Dc151B157Bd3f7b875BB90c38
CollectionUtils Addr: 0x107CDA547A1152f9C54112ea0d0522D10e140802
ManagementFundContract Addr: 0x3Ec6Bc988BB8147F6A0145A85E101583AEdb8777
```

Emacs auto format
```
M x prettier-prettify
```
