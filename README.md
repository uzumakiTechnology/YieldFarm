# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```

At its core, yield farming is a process that allows cryptocurrency holders to lock up their holdings, which in turn provides them with rewards.

In brief:

Yield farming lets you lock up funds, providing rewards in the process.
It involves lending out cryptos via DeFi protocols in order to earn fixed or variable interest.
The rewards can be far greater than traditional investments, but higher rewards bring higher risks, especially in such a volatile market.

Allocation point:
define how rewards are distributed among various pool

In contract, each pool has an allocation points assigned to it
The amount of the token are distributed to each pool per block is proportional to the number of allocation points assigned to the pools, the more allocation points it has, the more reward it get distributed

Ex : 2 pool A and B, which allocation points are 10 and 20, have 30 token created each block
method :

poolA gets 10/30 (1/3 of total token)
poolB gets 20/30 (2/3 of total token)
