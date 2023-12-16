// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity 0.8.19;

import "fhevm/abstracts/EIP712WithModifier.sol";

import "fhevm/lib/TFHE.sol";

contract Minesweeper is EIP712WithModifier {

    event EmptyCellOpened(
        uint8 col,
        uint8 row,
        uint8 cnt
    );
    event MineCellOpened(
        uint8 col,
        uint8 row
    );
    event PlayerLoses(
        uint8 col,
        uint8 row,
        uint8 turns
    );
    event PlayerWins(
        uint8 turns
    );

    uint8 public constant MAX_ROW_COL = 15;

    // uint8 public constant cols = 3;
    // uint8 public constant rows = 3;
    // uint8 public constant mines = 3;
    uint8 public cols;
    uint8 public rows;
    uint8 public mines;

    address public player;
    bool public gameEnded;

    // masks for each col i \in [1..cols], where j-th bit set to 1 means there is a bomb in cell (i, j)
    uint8[MAX_ROW_COL] public cellOpenedMask;
    uint8[MAX_ROW_COL] public cellCountedMask;


    //
    euint8[MAX_ROW_COL*MAX_ROW_COL] public gridValues;
    // values for each opened cell
    uint8[MAX_ROW_COL*MAX_ROW_COL] public openedCellValue;

    uint8 public turns;
    uint8 public cellsOpenedCnt;

    euint8 private minesLeft;

    uint8 public partOpenedCellNumber;
    uint8 public partOpenedCell;

    uint8[8] public checkList;
    uint8 public checkListSize;
    uint8 public checkListPtr;

    constructor(uint8 cols_, uint8 rows_, uint8 mines_
    ) EIP712WithModifier("Authorization token", "1") {
        require(0 <= cols_ && cols_ < MAX_ROW_COL, "incorrect columns");
        require(0 <= rows_ && rows_ < MAX_ROW_COL, "incorrect columns");
        require(0 <= mines_ && mines_ < cols_*rows_, "incorrect mines");
        player = msg.sender;
        gameEnded = false;
        cols = cols_;
        rows = rows_;
        mines = mines_;
        turns = 0;
        cellsOpenedCnt = 0;
        minesLeft = TFHE.asEuint8(mines);
        partOpenedCell = 0;
        for (uint16 i = 0; i < cols; i++) {
            cellOpenedMask[i] = 0;
            cellCountedMask[i] = 0;
        }
    }

    function playerOpensCell(uint8 c, uint8 r) public onlyPlayer {
        require(!gameEnded, "Game has ended");
        require(r >= 0 && c >= 0 && r < rows && c < cols, "Wrong bounds");
        require(((cellOpenedMask[c]>>r)&1) == 0, "Cell is already opened");
        require(partOpenedCell == 0, "Open new cell");
        turns += 1;
        uint8 val = TFHE.decrypt(countCell(c, r));
        if (val != 1) {
            // not bomb
            // count number of bombs around
            checkListPtr = checkListSize = 0;
            for (int8 i = -1; i <= 1; i++) {
                for (int8 j = -1; j <= 1; j++) {
                    if (i == 0 && j == 0)
                        continue;
                    int8 x = int8(c) + i;
                    int8 y = int8(r) + j;
                    if (0 <= x && x < int8(cols) && 0 <= y && y < int8(rows)) {
                        checkList[checkListSize] = uint8(x)*rows+uint8(y);
                        ++checkListSize;
                    }
                }
            }
            openedCellValue[c*rows+r] = 0;
            if (checkListSize > 0) {
                partOpenedCell = 1;
                partOpenedCellNumber = c*rows+r;
            }
            else {
                partOpenedCell = 0;
            }
        }
        else {
            // bomb
            cellOpenedMask[c] |= uint8(1)<<r;
            declareLose(c, r);
        }
    }

    function playerOpensCellRepeat(uint8 c, uint8 r) public onlyPlayer {
        require(!gameEnded, "Game has ended");
        require(r >= 0 && c >= 0 && r < rows && c < cols, "Wrong bounds");
        require(((cellOpenedMask[c]>>r)&1) == 0, "Cell is already opened");
        require(partOpenedCell != 0, "Continue opening cell");
        require(c*rows+r == partOpenedCellNumber, "Did't finish opening");
        require(checkListPtr < checkListSize, "Has to be less");
        euint8 cntEncrypted = TFHE.asEuint8(0);

        {
            uint8 x = checkList[checkListPtr]/rows;
            uint8 y = checkList[checkListPtr]%rows;
            cntEncrypted = TFHE.add(cntEncrypted, countCell(x, y));
            checkListPtr += 1;
        }

        if (checkListPtr < checkListSize) {
            uint8 x = checkList[checkListPtr]/rows;
            uint8 y = checkList[checkListPtr]%rows;
            cntEncrypted = TFHE.add(cntEncrypted, countCell(x, y));
            checkListPtr += 1;
        }
        
        uint8 cnt = TFHE.decrypt(cntEncrypted);
        openedCellValue[c*rows+r] += cnt;
        if (checkListPtr < checkListSize) {
            partOpenedCell++;
        }
        else {
            partOpenedCell = 0;
            cellOpenedMask[c] |= uint8(1)<<r;
            declareEmptyCell(c, r, openedCellValue[c*rows+r]);
        }
    }

    function countCell(uint8 c, uint8 r) private returns (euint8) {
        uint8 cellNum = c*rows+r;
        if ((cellCountedMask[c]>>r)&1 == 1) {
            return gridValues[cellNum];
        }
        euint8 generated = TFHE.rem(TFHE.randEuint8(), cols*rows-cellsOpenedCnt);

        euint8 isBomb = TFHE.asEuint8(TFHE.lt(generated, minesLeft));
        minesLeft = TFHE.sub(minesLeft, isBomb);
        
        gridValues[cellNum] = isBomb;
        cellCountedMask[c] |= uint8(1)<<r;
        return isBomb;
    }

    function declareLose(uint8 col, uint8 row) private {
        for (uint8 i = 0; i < cols; i++) {
            for (uint8 j = 0; j < rows; j++) {
                // uint16 val = TFHE.decrypt(TFHE.and(TFHE.shr(gridMasks[i], j), TFHE.asEuint16(1)));
                // if (val == 1) {
                //     emit MineCellOpened(i, j);
                // }
            }
        }
        gameEnded = true;
        emit PlayerLoses(col, row, turns);
    }

    function declareWin() private {
        gameEnded = true;
        emit PlayerWins(turns);
    }

    function declareEmptyCell(uint8 c, uint8 r, uint8 cnt) private {
        emit EmptyCellOpened(c, r, cnt);
        cellsOpenedCnt += 1;
        if (cellsOpenedCnt == cols*rows-mines) {
            declareWin();
        }
    }

    modifier onlyPlayer() {
        require(msg.sender == player);
        _;
    }

}
