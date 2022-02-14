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
MemberContract Addr: 0x645690050fBc7267DeeEF36961EA3d5808b9BaA7
GovernanceContract Addr: 0x2a3e675885E1bb2668E20c5EC8101cE958Ff0a8b
BancorFormulaContract Addr: 0x0C42d35aDDdFc2BCC8cE96c1ef5566f50C512DDD
CollateralTokenContract Addr: 0x487B05a3F1dF5FAD1f3eeA746675B7085686dea7
ARATokenContract Addr: 0xD30b2Be5E78E9843fF5205B78141E531CF4dD1dd
ProposalContract Addr: 0x82c11F6F0fC4b3741364e7B269e2212dE40EeDD4
NFTFactoryContract Addr: 0x1F109F6C7D4F3004588215c88a2DDd08ec372d01
NFTUtilsContract Addr: 0x400cfcc287610C70bcC0F2F42dd20279344978e7
CollectionFactoryContract Addr: 0x1C9d943A1a4d5bee799DfF23E046fBa19D9C4723
CollectionUtils Addr: 0xe8C72cB269cA576AaFF103dF2F6c3947Bd0b0776
ManagementFundContract Addr: 0x8CA572CF469C22C05b971a3e9C446864b64AC5E4
```

Emacs auto format
```
M x prettier-prettify
```
