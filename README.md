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
MemberContract Addr: 0xA8903fa9655D5f3F47f8aE87E23C8c8876b6f424
GovernanceContract Addr: 0xA00DF77d5ba0870C068F900d43A7449799A69531
BancorFormulaContract Addr: 0x53df2C0022766137a2edeE3ce93DC71fAC9aBeb1
CollateralTokenContract Addr: 0xeEb134eEa9f322C3DB6750B29e538B3B1018E102
ARATokenContract Addr: 0x89efC4c581898b87f572Bd7f4997D9166CDc988E
ProposalContract Addr: 0xDB1a11cCf7Fe155BEB47144238225e39640f97b9
NFTFactoryContract Addr: 0x1716a8d8BCeBBd9f9E7E349008aCa2a7ea96828e
NFTUtilsContract Addr: 0xb663FE4Bbf50f5a8F036f0A2DA4Cd7c4EB67919A
CollectionFactoryContract Addr: 0xa4315AB0bAB142F36D58122b02FC8DCf8DEb5A20
CollectionUtils Addr: 0x59c7476fF496590bA7D0d8b00bDD16f332372878
ManagementFundContract Addr: 0xD0fCb6c50602aE78aeB06aEAfE63AD59b2440c66
```

Emacs auto format
```
M x prettier-prettify
```
