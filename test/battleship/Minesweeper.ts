import { expect } from "chai";
import { ethers } from "hardhat";

import { getSigners } from "../signers";
import { MinesweeperMocked } from "../../types";
import { createTransaction } from "../utils";

export async function checkIfCorrect(minesweeperContract: MinesweeperMocked, n: number) {

  for (let i = 1; i < n; i++) {
    {
      const tx1 = await createTransaction(minesweeperContract.playerOpensCell, i, 0);
      await tx1.wait();
      while(await minesweeperContract.partOpenedCell()) {
        const tx2 = await createTransaction(minesweeperContract.playerOpensCellRepeat, i, 0);
        await tx2.wait();
      }
      expect(await minesweeperContract.openedCellValue(i*n)).equals(i == 1 ? 2 : 0);
      expect(await minesweeperContract.cellsOpenedCnt()).equals((i-1)*n+1);
      expect(await minesweeperContract.gameEnded()).equals(false);
    }
    for (let j = 1; j + 1 < n; j++) {
      const tx1 = await createTransaction(minesweeperContract.playerOpensCell, i, j);
      await tx1.wait();
      while(await minesweeperContract.partOpenedCell()) {
        const tx2 = await createTransaction(minesweeperContract.playerOpensCellRepeat, i, j);
        await tx2.wait();
      }
      expect(await minesweeperContract.openedCellValue(i*n+j)).equals(i == 1 ? 3 : 0);
      expect(await minesweeperContract.cellsOpenedCnt()).equals((i-1)*n+j+1);
      expect(await minesweeperContract.gameEnded()).equals(false);
    }
    {
      const tx1 = await createTransaction(minesweeperContract.playerOpensCell, i, n-1);
      await tx1.wait();
      while(await minesweeperContract.partOpenedCell()) {
        const tx2 = await createTransaction(minesweeperContract.playerOpensCellRepeat, i, n-1);
        await tx2.wait();
      }
      expect(await minesweeperContract.openedCellValue(i*n+n-1)).equals(i == 1 ? 2 : 0);
      expect(await minesweeperContract.cellsOpenedCnt()).equals(i*n);
      expect(await minesweeperContract.gameEnded()).equals(i + 1 == n);
    }
  }

}


describe("Minesweeper", function() {
  before(async function () {
    this.signers = await getSigners(ethers);
  });

  it("should end game correctly 2x2", async function() {
    const minesweeper9Factory = await ethers.getContractFactory("MinesweeperMocked");
    const contract: MinesweeperMocked = await minesweeper9Factory.connect(this.signers.alice).deploy(2, 2, 2);
    await contract.waitForDeployment();
    {
      const tx1 = await createTransaction(contract.playerOpensCell, 1, 0);
      await tx1.wait();
      while(await contract.partOpenedCell()) {
        const tx2 = await createTransaction(contract.playerOpensCellRepeat, 1, 0);
        await tx2.wait();
      }
      expect(await contract.gameEnded()).equals(false);
      expect(await contract.openedCellValue(2)).equals(2);
    }
    
    {
      const tx1 = await createTransaction(contract.playerOpensCell, 0, 1);
      await tx1.wait();
      expect(await contract.partOpenedCell()).equals(0);
      expect(await contract.gameEnded()).equals(true);
      expect(await contract.cellsOpenedCnt()).equals(1);
    }
  }).timeout(80000);
  
  it("should set mines on 2x2 field", async function() {
    const minesweeper9Factory = await ethers.getContractFactory("MinesweeperMocked");
    const contract: MinesweeperMocked = await minesweeper9Factory.connect(this.signers.alice).deploy(2, 2, 2);
    await contract.waitForDeployment();
    await checkIfCorrect(contract, 2);
  }).timeout(240000);
  
  it("should set mines on 3x3 field", async function() {
    const minesweeper9Factory = await ethers.getContractFactory("MinesweeperMocked");
    const contract: MinesweeperMocked = await minesweeper9Factory.connect(this.signers.alice).deploy(3, 3, 3);
    await contract.waitForDeployment();
    await checkIfCorrect(contract, 3);
  }).timeout(240000);
  
  it("should set mines on 4x4 field", async function() {
    const minesweeper9Factory = await ethers.getContractFactory("MinesweeperMocked");
    const contract: MinesweeperMocked = await minesweeper9Factory.connect(this.signers.alice).deploy(4, 4, 4);
    await contract.waitForDeployment();
    await checkIfCorrect(contract, 4);
  }).timeout(800000);
  

});