import { HardhatUserConfig } from 'hardhat/config';
import '@typechain/hardhat';
import '@nomiclabs/hardhat-waffle'
// import "hardhat-deploy"
// import '@openzeppelin/hardhat-upgrades';
import "hardhat-gas-reporter"
import "@nomiclabs/hardhat-web3";
import "@nomiclabs/hardhat-truffle5";

import deployer from './.secret';
import conf from './config';


const config: HardhatUserConfig = {

  solidity: {
    compilers: [
      {
        version: "0.7.6",
        settings: {},
      },
      {
        version: "0.8.2",
      },

    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      loggingEnabled: true,
      forking: {
        url: conf.rpc,
        enabled: true,
        blockNumber: conf.block_number
      },
    },
    forked: {
      url: conf.fork_rpc + conf.fork_id,
      chainId: conf.chain_id,
    },
    eth: {
      url: conf.rpc,
      chainId: 1,
      accounts: deployer.private,
      gas: 9999900,

    },
    bsc: {
      url: conf.bscrpc,
      chainId: 56,
      accounts: deployer.private,
      gas: 9999900,
    },
    local: {
      url: 'http://127.0.0.1:8545',
    },
  },
  mocha: {
    timeout: 400000000,
  },
  gasReporter: {
    gasPrice: 7

  }

};
module.exports = config;
