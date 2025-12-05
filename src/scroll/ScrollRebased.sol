// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/*
 * @title ScrollRebased
 * @author Rebased Protocol Team  
 * @notice L2 rebasing token using L1SLOAD for real-time stETH data on Scroll
 */

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ScrollMessaging, IScrollRebasedReceiver} from "./ScrollBridge.sol";

interface IRebasedAdapter {
    function processWithdrawal(bytes memory data) external;
}

contract ScrollRebased is ERC20, IScrollRebasedReceiver {
    // ═══════════════════════════════════════════════════════════════════════════
    // STORAGE SLOTS (Lido contract positions)
    // ═══════════════════════════════════════════════════════════════════════════

    bytes32 private constant SLOT_TOTAL_SHARES = 0xe3b4b636e601189b5f4c6742edf2538ac12bb61ed03e6da26949d69838fa447e;
    bytes32 private constant SLOT_BUFFERED_ETH = 0xed310af23f61f96daefbcd140b306c0bdbf8c178398299741687b90e794772b0;
    bytes32 private constant SLOT_CL_BALANCE = 0xa66d35f054e68143c18f32c990ed5cb972bb68a68f500cd2dd3a16bbf3686483;
    bytes32 private constant SLOT_DEPOSITED_VALIDATORS = 0xe6e35175eb53fc006520a2a9c3e9711a7c00de6ff2c32dd31df8c5a24cac1b5c;
    bytes32 private constant SLOT_CL_VALIDATORS = 0x9f70001d82b6ef54e9d3725b46581c3eb9ee3aa02b941b6aa54d678a9ca35b10;

    uint256 private constant VALIDATOR_DEPOSIT = 32 ether;
    address private constant L1_BLOCKS = 0x5300000000000000000000000000000000000001;
    address private constant L1_SLOAD = 0x0000000000000000000000000000000000000101;

    // ═══════════════════════════════════════════════════════════════════════════
    // STATE
    // ═══════════════════════════════════════════════════════════════════════════

    address public immutable l1TokenAddr;
    ScrollMessaging public messenger;
    IRebasedAdapter public adapter;
    uint256 public bridgeGasLimit = 1_000_000;
    mapping(address => uint256) public userShares;

    struct BridgePayload {
        address recipient;
        uint256 amount;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ERRORS & MODIFIERS
    // ═══════════════════════════════════════════════════════════════════════════

    error UnauthorizedCaller();
    error L1ReadFailed();

    modifier onlyMessenger() {
        if (msg.sender != address(messenger)) revert UnauthorizedCaller();
        _;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════

    constructor(
        address l1Token_,
        IRebasedAdapter adapter_,
        ScrollMessaging messenger_
    ) ERC20("Rebased Staked Ether", "rebETH") {
        l1TokenAddr = l1Token_;
        adapter = adapter_;
        messenger = messenger_;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN
    // ═══════════════════════════════════════════════════════════════════════════

    function setMessenger(ScrollMessaging m) external {
        messenger = m;
    }

    function setGasLimit(uint256 limit) external {
        bridgeGasLimit = limit;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // BRIDGE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    function mintFromBridge(bytes memory encoded) external {
        BridgePayload memory payload = abi.decode(encoded, (BridgePayload));
        _mint(payload.recipient, payload.amount);
        userShares[payload.recipient] += convertEthToShares(payload.amount);
    }

    function bridgeToL1(uint256 amount) external payable {
        _burn(msg.sender, amount);
        userShares[msg.sender] -= convertEthToShares(amount);

        BridgePayload memory payload = BridgePayload({
            recipient: msg.sender,
            amount: amount
        });

        messenger.sendMessage{value: msg.value}(
            address(adapter),
            0,
            abi.encodeWithSelector(IRebasedAdapter.processWithdrawal.selector, abi.encode(payload)),
            bridgeGasLimit
        );
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // L1 DATA READING
    // ═══════════════════════════════════════════════════════════════════════════

    function readL1Slot(bytes32 slot) public view returns (uint256) {
        (bool ok, bytes memory result) = L1_SLOAD.staticcall(
            abi.encodePacked(l1TokenAddr, slot)
        );
        if (!ok) revert L1ReadFailed();
        return abi.decode(result, (uint256));
    }

    function getTotalPooledEth() public view returns (uint256) {
        uint256 buffered = readL1Slot(SLOT_BUFFERED_ETH);
        uint256 clBalance = readL1Slot(SLOT_CL_BALANCE);
        uint256 transient = _calculateTransientBalance();
        return buffered + clBalance + transient;
    }

    function _calculateTransientBalance() internal view returns (uint256) {
        uint256 deposited = readL1Slot(SLOT_DEPOSITED_VALIDATORS);
        uint256 clValidators = readL1Slot(SLOT_CL_VALIDATORS);
        assert(deposited >= clValidators);
        return (deposited - clValidators) * VALIDATOR_DEPOSIT;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SHARE CONVERSIONS
    // ═══════════════════════════════════════════════════════════════════════════

    function convertSharesToEth(uint256 shares) public view returns (uint256) {
        uint256 totalShares = readL1Slot(SLOT_TOTAL_SHARES);
        if (totalShares == 0) return 0;
        return (shares * getTotalPooledEth()) / totalShares;
    }

    function convertEthToShares(uint256 eth) public view returns (uint256) {
        uint256 pooled = getTotalPooledEth();
        if (pooled == 0) return eth;
        return (eth * readL1Slot(SLOT_TOTAL_SHARES)) / pooled;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LEGACY COMPATIBILITY
    // ═══════════════════════════════════════════════════════════════════════════

    function receiveRstETH(bytes memory d) external { mintFromBridge(d); }
    function payoutRstETH(uint256 a) external payable { bridgeToL1(a); }
    function getPooledEthByShares(uint256 sh) external view returns (uint256) { return convertSharesToEth(sh); }
    function getSharesByEth(uint256 e) external view returns (uint256) { return convertEthToShares(e); }
    function sharesPerUser(address u) external view returns (uint256) { return userShares[u]; }

    // ═══════════════════════════════════════════════════════════════════════════
    // UTILITIES
    // ═══════════════════════════════════════════════════════════════════════════

    function rescueEth() external {
        (bool ok,) = msg.sender.call{value: address(this).balance}("");
        require(ok, "TransferFailed");
    }

    receive() external payable {}
}

