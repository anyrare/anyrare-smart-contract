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
MemberContract Addr: 0x2CE589b28f4E755C7322fB2D4F35d33352b304fC
GovernanceContract Addr: 0x1F437134c7Bc429030546DE54C0989F67FC808e5
BancorFormulaContract Addr: 0x3416aFB28bB6216924F72788DCfa49e13B679133
CollateralTokenContract Addr: 0x736e3252D943638eC3E7A902FBdE90d9Ed1Ab7eF
ARATokenContract Addr: 0xbF489F0d53976913e461B76D23ec6e43732A8DB3
ProposalContract Addr: 0xCD4A580d41B681830f00cC792E4E136fE3B8Ab37
NFTFactoryContract Addr: 0xdE30Ba771bca3e474449e98415885Dc1c05dcb0C
NFTUtilsContract Addr: 0x2064f4ABFF6cf4114D1b43c6Fc8d9F64315E3De6
CollectionFactoryContract Addr: 0x26D78CBc92239Ec112cF8A151Ef8297CDeF5672A
CollectionUtils Addr: 0x8aE0ba93d758292e2213fC5e0A5E9E25eAE57B63
ManagementFundContract Addr: 0xBe54Fc1CDc28048eafF882B3be608a14D6A75245
```

Emacs auto format
```
M x prettier-prettify
```
