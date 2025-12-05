// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/*
 * @title MockStakedEth
 * @notice Mock implementation of stETH for testing purposes
 */

import "../external/IStETH.sol";
import {SlotStorage} from "./SlotStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockStakedEth is ERC20 {
    using SlotStorage for bytes32;

    // ═══════════════════════════════════════════════════════════════════════════
    // STORAGE SLOTS
    // ═══════════════════════════════════════════════════════════════════════════

    bytes32 private constant SLOT_TOTAL_SHARES = 0xe3b4b636e601189b5f4c6742edf2538ac12bb61ed03e6da26949d69838fa447e;
    bytes32 private constant SLOT_BUFFERED_ETH = 0xed310af23f61f96daefbcd140b306c0bdbf8c178398299741687b90e794772b0;
    bytes32 private constant SLOT_CL_BALANCE = 0xa66d35f054e68143c18f32c990ed5cb972bb68a68f500cd2dd3a16bbf3686483;
    bytes32 private constant SLOT_DEPOSITED_VALIDATORS = 0xe6e35175eb53fc006520a2a9c3e9711a7c00de6ff2c32dd31df8c5a24cac1b5c;
    bytes32 private constant SLOT_CL_VALIDATORS = 0x9f70001d82b6ef54e9d3725b46581c3eb9ee3aa02b941b6aa54d678a9ca35b10;
    bytes32 private constant SLOT_SHARES_BASE = keccak256("rebased.mock.shares");

    uint256 private constant RATE_PRECISION = 1e18;

    // ═══════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════

    constructor() ERC20("Mock Staked Ether", "mockstETH") {
        uint256 initialAmount = 1000 ether;
        _mint(msg.sender, initialAmount);
        _writeShares(msg.sender, initialAmount);
        SLOT_TOTAL_SHARES.writeUint256(initialAmount);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // STAKING
    // ═══════════════════════════════════════════════════════════════════════════

    function stake() external payable {
        require(msg.value > 0, "ZeroAmount");

        uint256 shares = convertPooledEthToShares(msg.value);
        _writeShares(msg.sender, sharesOf(msg.sender) + shares);
        SLOT_TOTAL_SHARES.writeUint256(getTotalShares() + shares);
        _mint(msg.sender, msg.value);
    }

    function addRewards(uint256 rewardAmount) external {
        _mint(address(this), rewardAmount);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    function balanceOf(address account) public view override returns (uint256) {
        return convertSharesToPooledEth(sharesOf(account));
    }

    function getTotalShares() public view returns (uint256) {
        return SLOT_TOTAL_SHARES.readUint256();
    }

    function sharesOf(address account) public view returns (uint256) {
        return _readShares(account);
    }

    function convertPooledEthToShares(uint256 ethAmount) public view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) return ethAmount;
        return (ethAmount * getTotalShares()) / supply;
    }

    function convertSharesToPooledEth(uint256 shares) public view returns (uint256) {
        uint256 totalShares = getTotalShares();
        if (totalShares == 0) return 0;
        return (shares * totalSupply()) / totalShares;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LEGACY COMPATIBILITY
    // ═══════════════════════════════════════════════════════════════════════════

    function submit() external payable { this.stake{value: msg.value}(); }
    function getSharesByPooledEth(uint256 e) external view returns (uint256) { return convertPooledEthToShares(e); }
    function getPooledEthByShares(uint256 s) external view returns (uint256) { return convertSharesToPooledEth(s); }
    function distributeRewards(uint256 r) external { addRewards(r); }

    // ═══════════════════════════════════════════════════════════════════════════
    // INTERNAL
    // ═══════════════════════════════════════════════════════════════════════════

    function _readShares(address account) internal view returns (uint256) {
        bytes32 slot = keccak256(abi.encodePacked(account, SLOT_SHARES_BASE));
        return SlotStorage.readUint256(slot);
    }

    function _writeShares(address account, uint256 amount) internal {
        bytes32 slot = keccak256(abi.encodePacked(account, SLOT_SHARES_BASE));
        SlotStorage.writeUint256(slot, amount);
    }
}

