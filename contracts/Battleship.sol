// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity 0.8.19;

import "fhevm/abstracts/EIP712WithModifier.sol";

import "fhevm/lib/TFHE.sol";

import "./lib/permutation/Permutation.sol";

contract Battleship is EIP712WithModifier {

    uint16 public constant MAX_ROW_COL = 16;
    

    address public contractOwner;

    uint16 public cols;
    uint16 public rows;
    uint16 public mines;
    euint16[MAX_ROW_COL] public gridMasks; // masks for each col i \in [1..cols], where j-th bit set to 1 means there is a bomb in cell (i, j)
    Permutation public permGen;

    constructor(uint16 cols_, uint16 rows_, uint16 mines_, Permutation permGen_) EIP712WithModifier("Authorization token", "1") {
        contractOwner = msg.sender;
        require(cols_ <= MAX_ROW_COL, "Columns exceed maximum bound");
        require(rows_ <= MAX_ROW_COL, "Rows exceed maximum bound");
        require(mines_ <= cols_*rows_, "Mines exceed number of cells");
        cols = cols_;
        rows = rows_;
        mines = mines_;
        permGen = permGen_;
    }

    function genGrid() internal {
        uint16 totalCells = cols*rows;
        euint16[] memory perm = permGen.genPermutation16(totalCells);

        for (uint16 i = 0; i < cols; i++) {
            gridMasks[i] = TFHE.asEuint16(0);
            for (uint16 j = 0; j < rows; j++) {
                uint16 curCell = i*rows + j;
                euint16 curState = TFHE.asEuint16(0);
                for (uint8 k = 0; k < mines; k++) {
                    curState = TFHE.cmux(TFHE.eq(curCell, perm[k]), TFHE.asEuint16(1), curState);
                }
                gridMasks[i] = TFHE.or(gridMasks[i], TFHE.shl(curState, j));
            }
        }
        
    }

}