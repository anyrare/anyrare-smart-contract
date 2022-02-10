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
MemberContract Addr: 0x066E11E001407c571C0055eACD7Bbf58a419c6d5
GovernanceContract Addr: 0xCE925c876Ed70402b97B48FEaf8A60514E049361
BancorFormulaContract Addr: 0x39A07d0bA0571B42C41D14628F98B50E934e1D0B
CollateralTokenContract Addr: 0x980e704bD12CFb2EA6f771033c2b8DAa00204A2F
ARATokenContract Addr: 0xE918f22b0384dF77F7f476430d3fBD12E29D207E
ProposalContract Addr: 0x7e33603e824e3825e1Be299dbF221d1C22DcD5D5
NFTFactoryContract Addr: 0xBA83Cae2Bdd9cbe1Dc497a379E13E5378FF9DCEa
NFTUtilsContract Addr: 0x75f58A096124e1B60698751394e74E599033E402
CollectionFactoryContract Addr: 0xd05522DDA6b795E976D3b3A49eF99e01F3d75B3E
CollectionUtils Addr: 0xC1b1A12794154B6Cc7951A374a8F6cc271f40116
ManagementFundContract Addr: 0xAb75657C3E7b47AEc6E8b22bc18Ed59b7816a4bf
```

Emacs auto format
```
M x prettier-prettify
```
