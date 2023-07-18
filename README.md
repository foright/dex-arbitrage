#### <center> Note: This repo is not under maintenning. </center>
---
#### DEX arbitrage with uniswap v2 like and uniswap v3
---
#### Deploy the contranct
1. Edit network config in `hardhat.config.ts`.
2. Copy the secret sample config：

```bash
$ cp .secret.ts.sample .secret.ts
```

3. Edit the private key in above config.


4. Then run the script to deploy. you can deploy to bsc or eth

```bash
$ hardhart --network bsc run scripts/deploy_bsc.ts

