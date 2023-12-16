import { ethers } from "hardhat";

import type { Minesweeper } from "../../types";
import { getSigners } from "../signers";

export async function deployEncryptedERC20Fixture(): Promise<Minesweeper> {
  const signers = await getSigners(ethers);

  const contractFactory = await ethers.getContractFactory("Minesweeper");
  const contract = await contractFactory.connect(signers.alice).deploy();
  await contract.waitForDeployment();

  return contract;
}
