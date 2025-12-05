// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/*
 * @title RebasedOFT Test Suite
 * @notice Tests for the Rebased OFT cross-chain token
 */

import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {IOFT, SendParam, OFTReceipt} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {MessagingFee, MessagingReceipt} from "@layerzerolabs/oft-evm/contracts/OFTCore.sol";
import {OFTMsgCodec} from "@layerzerolabs/oft-evm/contracts/libs/OFTMsgCodec.sol";
import {OFTComposeMsgCodec} from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "forge-std/src/console.sol";
import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";
import {RebasedOFT} from "../src/RebasedOFT.sol";

contract RebasedOFTTest is TestHelperOz5 {
    using OptionsBuilder for bytes;

    // ═══════════════════════════════════════════════════════════════════════════
    // TEST CONFIG
    // ═══════════════════════════════════════════════════════════════════════════

    uint32 private constant CHAIN_A = 1;
    uint32 private constant CHAIN_B = 2;

    RebasedOFT private tokenA;
    RebasedOFT private tokenB;

    address private alice = address(0x1);
    address private bob = address(0x2);
    uint256 private startingBalance = 100 ether;

    // ═══════════════════════════════════════════════════════════════════════════
    // SETUP
    // ═══════════════════════════════════════════════════════════════════════════

    function setUp() public virtual override {
        vm.deal(alice, 1000 ether);
        vm.deal(bob, 1000 ether);

        super.setUp();
        setUpEndpoints(2, LibraryType.UltraLightNode);

        tokenA = new RebasedOFT("Rebased A", "rebA", address(endpoints[CHAIN_A]), address(this));
        tokenB = new RebasedOFT("Rebased B", "rebB", address(endpoints[CHAIN_A]), address(this));

        address[] memory tokens = new address[](2);
        tokens[0] = address(tokenA);
        tokens[1] = address(tokenB);
        this.wireOApps(tokens);

        tokenA.mint(alice, startingBalance);
        tokenB.mint(bob, startingBalance);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    function test_deployment() public view {
        assertEq(tokenA.owner(), address(this));
        assertEq(tokenB.owner(), address(this));
        assertEq(tokenA.balanceOf(alice), startingBalance);
        assertEq(tokenB.balanceOf(bob), startingBalance);
        assertEq(tokenA.token(), address(tokenA));
        assertEq(tokenB.token(), address(tokenB));
    }

    function test_crossChainTransfer() public {
        uint256 amount = 1 ether;

        bytes memory opts = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        SendParam memory params = SendParam(
            CHAIN_B,
            addressToBytes32(bob),
            amount,
            amount,
            opts,
            "",
            ""
        );

        MessagingFee memory fee = tokenA.quoteSend(params, false);

        assertEq(tokenA.balanceOf(alice), startingBalance);
        assertEq(tokenB.balanceOf(bob), startingBalance);

        vm.prank(alice);
        tokenA.send{value: fee.nativeFee}(params, fee, payable(address(this)));

        verifyPackets(CHAIN_B, addressToBytes32(address(tokenB)));

        assertEq(tokenA.balanceOf(alice), startingBalance - amount);
        assertEq(tokenB.balanceOf(bob), startingBalance + amount);
    }
}

