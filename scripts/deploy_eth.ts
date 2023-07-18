import { ethers, run  } from 'hardhat';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

let signer: SignerWithAddress;
async function main() {
  [signer] = await ethers.getSigners();

  const MevBot = await ethers.getContractFactory('MevBot',signer);
  const mevBot = await MevBot.deploy();
  await mevBot.deployed();

  console.log(`FlashBot deployed to mevBot ${mevBot.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
