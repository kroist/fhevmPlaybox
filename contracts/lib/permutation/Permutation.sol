// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity 0.8.19;

import "fhevm/lib/TFHE.sol";

interface Permutation {
    function genPermutation16(uint16 n) external view returns (euint16[] memory);
}
