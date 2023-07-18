import { BigNumberish } from 'ethers';


interface Config {
  contractAddr: string;
  logLevel: string;
  rpc: string;
  bscrpc: string;
  api: string;
  fork_rpc: string;
  gasLimit: BigNumberish;
  block_number: number;
  chain_id: number;
  access_key: string;
  fork_id: string;
  username: string;
}
