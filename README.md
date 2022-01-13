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

Initial Policy
|policyName                                     |policyWeight|maxWeight|voteDuration|effectiveDuration|minWeightOpenVote|minWeightValidVote|minWeightApproveVote|policyValue|decider|
|-----------------------------------------------|------------|---------|------------|-----------------|-----------------|------------------|--------------------|-----------|-------|
|ARA_COLLATERAL_WEIGHT                          |400000      |1000000  |432000      |432000           |100000           |510000            |750000              |0          |0      |
|ARA_MINT_MANAGEMENT_FUND_WEIGHT                |600000      |1000000  |432000      |432000           |100000           |510000            |750000              |0          |0      |
|BUYBACK_WEIGHT                                 |50000       |1000000  |432000      |432000           |100000           |510000            |750000              |0          |0      |
|MANAGEMENT_FUND_MANAGER_WEIGHT                 |300000      |1000000  |432000      |432000           |100000           |510000            |750000              |0          |0      |
|FINANCING_CASHFLOW_LOCKUP_WEIGHT               |650000      |1000000  |432000      |432000           |100000           |510000            |750000              |0          |0      |
|FINANCING_CASHFLOW_LOCKUP_TARGET_VALUE_WEIGHT  |3000000     |1000000  |432000      |432000           |100000           |510000            |750000              |0          |0      |
|FINANCING_CASHFLOW_LOCKUP_PARTIAL_UNLOCK_WEIGHT|50000       |1000000  |432000      |432000           |100000           |510000            |750000              |0          |0      |
|MANAGEMENT_FUND_DISTRIBUTE_FUND_PERIOD         |0           |1000000  |432000      |432000           |100000           |510000            |750000              |21600      |1      |
|MANAGEMENT_FUND_DISTRIBUTE_LOCKUP_FUND_PERIOD  |0           |1000000  |432000      |432000           |100000           |510000            |750000              |21600      |1      |
|OPEN_AUCTION_NFT_PLATFORM_FEE                  |0           |1000000  |432000      |86400            |100000           |510000            |750000              |90000      |1      |
|OPEN_AUCTION_NFT_REFERRAL_FEE                  |0           |1000000  |432000      |86400            |100000           |510000            |750000              |10000      |0      |
|EXTENDED_AUCTION_NFT_TIME_TRIGGER              |0           |1000000  |432000      |86400            |100000           |510000            |750000              |300        |1      |
|EXTENDED_AUCTION_NFT_DURATION                  |0           |1000000  |432000      |86400            |100000           |510000            |750000              |300        |1      |
|EXTENDED_AUCTION_COLLECTION_TIME_TRIGGER       |0           |1000000  |432000      |86400            |100000           |510000            |750000              |300        |1      |
|EXTENDED_AUCTION_COLLECTION_DURATION           |0           |1000000  |432000      |86400            |100000           |510000            |750000              |300        |1      |
|MEET_RESERVE_PRICE_AUCTION_NFT_TIME_LEFT       |0           |1000000  |432000      |86400            |100000           |510000            |750000              |86400      |1      |
|CLOSE_AUCTION_NFT_PLATFORM_FEE                 |22500       |1000000  |432000      |86400            |100000           |510000            |750000              |0          |1      |
|CLOSE_AUCTION_NFT_REFERRAL_BUYER_FEE           |2500        |1000000  |432000      |86400            |100000           |510000            |750000              |0          |0      |
|CLOSE_AUCTION_NFT_REFERRAL_SELLER_FEE          |2000        |1000000  |432000      |86400            |100000           |510000            |750000              |0          |0      |
|NFT_MINT_FEE                                   |0           |1000000  |432000      |86400            |100000           |510000            |750000              |10000      |1      |
|NFT_CUSTODIAN_CAN_CLAIM_DURATION               |0           |1000000  |432000      |86400            |100000           |510000            |750000              |7776000    |1      |
|CREATE_COLLECTION_FEE                          |0           |1000000  |432000      |86400            |100000           |510000            |750000              |10000      |1      |
|BUY_COLLECTION_PLATFORM_FEE                    |200         |1000000  |432000      |86400            |100000           |510000            |750000              |0          |1      |
|BUY_COLLECTION_REFERRAL_COLLECTOR_FEE          |25          |1000000  |432000      |86400            |100000           |510000            |750000              |0          |0      |
|BUY_COLLECTION_REFERRAL_INVESTOR_FEE           |25          |1000000  |432000      |86400            |100000           |510000            |750000              |0          |0      |
|SELL_COLLECTION_PLATFORM_FEE                   |200         |1000000  |432000      |86400            |100000           |510000            |750000              |0          |1      |
|SELL_COLLECTION_REFERRAL_COLLECTOR_FEE         |25          |1000000  |432000      |86400            |100000           |510000            |750000              |0          |0      |
|SELL_COLLECTION_REFERRAL_INVESTOR_FEE          |25          |1000000  |432000      |86400            |100000           |510000            |750000              |0          |0      |
|TRANSFER_COLLECTION_PLATFORM_FEE               |200         |1000000  |432000      |86400            |100000           |510000            |750000              |0          |1      |
|TRANSFER_COLLECTION_REFERRAL_COLLECTOR_FEE     |25          |1000000  |432000      |86400            |100000           |510000            |750000              |0          |1      |
|TRANSFER_COLLECTION_REFERRAL_SENDER_FEE        |25          |1000000  |432000      |86400            |100000           |510000            |750000              |0          |1      |
|TRANSFER_COLLECTION_REFERRAL_RECEIVER_FEE      |25          |1000000  |432000      |86400            |100000           |510000            |750000              |0          |0      |
|OPEN_AUCTION_COLLECTION_DURATION               |0           |1000000  |432000      |86400            |100000           |510000            |750000              |432000     |1      |
|OPEN_AUCTION_COLLECTION_NEXT_BID_WEIGHT        |100000      |1000000  |432000      |86400            |100000           |510000            |750000              |0          |1      |
|CLOSE_AUCTION_COLLECTION_PLATFORM_FEE          |200         |1000000  |432000      |86400            |100000           |510000            |750000              |0          |1      |
|CLOSE_AUCTION_COLLECTION_REFERRAL_COLLECTOR_FEE|25          |1000000  |432000      |86400            |100000           |510000            |750000              |0          |0      |
|CLOSE_AUCTION_COLLECTION_REFERRAL_INVESTOR_FEE |25          |1000000  |432000      |86400            |100000           |510000            |750000              |0          |0      |
|MANAGERS_LIST                                  |0           |1000000  |432000      |432000           |100000           |510000            |750000              |0          |0      |
|AUDITORS_LIST                                  |0           |1000000  |432000      |86400            |110000           |510000            |750000              |0          |1      |
|CUSTODIANS_LIST                                |0           |1000000  |432000      |86400            |100000           |510000            |750000              |0          |1      |
|OPEN_BUY_IT_NOW_NFT_PLATFORM_FEE               |0           |1000000  |432000      |86400            |100000           |510000            |750000              |10000      |1      |
|OPEN_BUY_IT_NOW_NFT_REFERRAL_FEE               |0           |1000000  |432000      |86400            |100000           |510000            |750000              |1000       |1      |
|BUY_IT_NOW_NFT_PLATFORM_FEE                    |22500       |1000000  |432000      |86400            |100000           |510000            |750000              |0          |1      |
|BUY_IT_NOW_NFT_REFERRAL_BUYER_FEE              |2500        |1000000  |432000      |86400            |100000           |510000            |750000              |0          |0      |
|BUY_IT_NOW_NFT_REFERRAL_SELLER_FEE             |2000        |1000000  |432000      |86400            |100000           |510000            |750000              |0          |0      |
|OFFER_NFT_DURATION                             |0           |1000000  |432000      |86400            |100000           |510000            |750000              |864000     |1      |
|OFFER_NFT_PLATFORM_FEE                         |22500       |1000000  |432000      |86400            |100000           |510000            |750000              |0          |1      |
|OFFER_NFT_REFERRAL_BUYER_FEE                   |2500        |1000000  |432000      |86400            |100000           |510000            |750000              |0          |0      |
|OFFER_NFT_REFERRAL_SELLER_FEE                  |2000        |1000000  |432000      |86400            |100000           |510000            |750000              |0          |0      |
|REDEEM_NFT_PLATFORM_FEE                        |20000       |1000000  |432000      |86400            |100000           |510000            |750000              |1000       |1      |
|REDEEM_NFT_REFERRAL_FEE                        |20000       |1000000  |432000      |86400            |100000           |510000            |750000              |1000       |1      |
|REDEEM_NFT_REVERT_DURATION                     |0           |1000000  |432000      |86400            |100000           |510000            |750000              |604800     |1      |
|TRANSFER_NFT_PLATFORM_FEE                      |22500       |1000000  |432000      |86400            |100000           |510000            |750000              |1000       |1      |
|TRANSFER_NFT_REFERRAL_SENDER_FEE               |2000        |1000000  |432000      |86400            |100000           |510000            |750000              |1000       |0      |
|TRANSFER_NFT_REFERRAL_RECEIVER_FEE             |2500        |1000000  |432000      |86400            |100000           |510000            |750000              |1000       |0      |
