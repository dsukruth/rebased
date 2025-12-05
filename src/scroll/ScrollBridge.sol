// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/*
 * @title ScrollBridge
 * @author Rebased Protocol Team
 * @notice L1 bridge contract for stETH to Scroll L2
 */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStETH} from "../external/IStETH.sol";

interface ScrollMessaging {
    function sendMessage(
        address target,
        uint256 value,
        bytes memory data,
        uint256 gasLimit
    ) external payable;
}

interface IScrollRebasedReceiver {
    function mintFromBridge(bytes memory data) external;
}

contract ScrollBridge {
    // ═══════════════════════════════════════════════════════════════════════════
    // STATE
    // ═══════════════════════════════════════════════════════════════════════════

    ScrollMessaging public messenger;
    IERC20 public immutable stakedToken;
    address public l2Receiver;
    uint256 public bridgeGasLimit = 1_000_000;

    struct BridgePayload {
        address recipient;
        uint256 amount;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ERRORS & MODIFIERS
    // ═══════════════════════════════════════════════════════════════════════════

    error UnauthorizedCaller();
    error TransferFailed();

    modifier onlyMessenger() {
        if (msg.sender != address(messenger)) revert UnauthorizedCaller();
        _;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════

    constructor(ScrollMessaging messenger_, IERC20 token_) {
        messenger = messenger_;
        stakedToken = token_;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN
    // ═══════════════════════════════════════════════════════════════════════════

    function setL2Receiver(address receiver) external {
        l2Receiver = receiver;
    }

    function setMessenger(ScrollMessaging m) external {
        messenger = m;
    }

    function setGasLimit(uint256 limit) external {
        bridgeGasLimit = limit;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // BRIDGE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    function bridgeToL2(uint256 amount) external payable {
        stakedToken.transferFrom(msg.sender, address(this), amount);

        BridgePayload memory payload = BridgePayload({
            recipient: msg.sender,
            amount: amount
        });

        messenger.sendMessage{value: msg.value}(
            l2Receiver,
            0,
            abi.encodeWithSelector(IScrollRebasedReceiver.mintFromBridge.selector, abi.encode(payload)),
            bridgeGasLimit
        );
    }

    function processWithdrawal(bytes memory encoded) external onlyMessenger {
        BridgePayload memory payload = abi.decode(encoded, (BridgePayload));
        bool ok = stakedToken.transfer(payload.recipient, payload.amount);
        if (!ok) revert TransferFailed();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LEGACY COMPATIBILITY
    // ═══════════════════════════════════════════════════════════════════════════

    function setScrollRstETH(address r) external { setL2Receiver(r); }
    function setScrollMessenger(ScrollMessaging m) external { setMessenger(m); }
    function bridgeRStETH(uint256 a) external payable { bridgeToL2(a); }
    function payOutRstETH(bytes memory d) external { processWithdrawal(d); }

    // ═══════════════════════════════════════════════════════════════════════════
    // UTILITIES
    // ═══════════════════════════════════════════════════════════════════════════

    function rescueEth() external {
        (bool ok,) = msg.sender.call{value: address(this).balance}("");
        require(ok, "TransferFailed");
    }

    receive() external payable {}
}

