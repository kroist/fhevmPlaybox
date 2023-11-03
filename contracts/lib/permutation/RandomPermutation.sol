// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity 0.8.19;

import "fhevm/lib/TFHE.sol";

import "./Permutation.sol";

contract RandomPermutation is Permutation {
    function genPermutation16(uint16 n) public view override returns (euint16[] memory) {
        euint16[] memory arr = new euint16[](n);
        for (uint16 i = 0; i < n; i++) {
            arr[i] = TFHE.asEuint16(i);
        }
        for (uint16 i = 1; i < n; i++) {
            euint16 toSwap = TFHE.add(i + 1, TFHE.rem(TFHE.randEuint16(), n - i));
            for (uint16 j = i; j < n; j++) {
                arr[i] = TFHE.cmux(TFHE.eq(toSwap, j), arr[j], arr[i]);
            }
        }
        return arr;
    }
}
