// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/*
 * @title SlotStorage
 * @notice Low-level storage slot manipulation utilities
 */

library SlotStorage {
    function readBool(bytes32 slot) internal view returns (bool val) {
        assembly { val := sload(slot) }
    }

    function readAddress(bytes32 slot) internal view returns (address val) {
        assembly { val := sload(slot) }
    }

    function readBytes32(bytes32 slot) internal view returns (bytes32 val) {
        assembly { val := sload(slot) }
    }

    function readUint256(bytes32 slot) internal view returns (uint256 val) {
        assembly { val := sload(slot) }
    }

    function writeBool(bytes32 slot, bool val) internal {
        assembly { sstore(slot, val) }
    }

    function writeAddress(bytes32 slot, address val) internal {
        assembly { sstore(slot, val) }
    }

    function writeBytes32(bytes32 slot, bytes32 val) internal {
        assembly { sstore(slot, val) }
    }

    function writeUint256(bytes32 slot, uint256 val) internal {
        assembly { sstore(slot, val) }
    }
}

contract StorageDemo {
    using SlotStorage for bytes32;

    bytes32 private constant DEMO_SLOT = 0xe3b4b636e601189b5f4c6742edf2538ac12bb61ed03e6da26949d69838fa447e;

    function read() public view returns (uint256) {
        return DEMO_SLOT.readUint256();
    }

    function write(uint256 val) public {
        DEMO_SLOT.writeUint256(val);
    }
}

