// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity 0.8.19;

import "fhevm/lib/TFHE.sol";

import "./Permutation.sol";

contract MockedPermutation is Permutation {
    uint16[] mockedArr;

    constructor(uint16[] memory mockedArr_) {
        mockedArr = mockedArr_;
    }

    function genPermutation16(uint16 n) public view override returns (euint16[] memory) {
        require(n == mockedArr.length);
        euint16[] memory arr = new euint16[](n);
        for (uint16 i = 0; i < n; i++) {
            arr[i] = TFHE.asEuint16(mockedArr[i]);
        }
        return arr;
    }
}
