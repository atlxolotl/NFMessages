// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {MessagesToken}  from "../src/MessagesToken.sol";

contract MessagesTokenTest is Test {
    MessagesToken public msgTknSc;
    uint256 public startAt;
    uint256 public mintingAndLockDeadline;

    function setUp() public {
        startAt = block.timestamp;
        mintingAndLockDeadline = block.timestamp + 1 days;
        msgTknSc = new MessagesToken(mintingAndLockDeadline);
    }


    function testMintingTokens() public {
        msgTknSc.mint(address(1), 1000);
        assertEq(msgTknSc.balanceOf(address(1)), 1000);
    }

    function testFailMintingTokensAfterDeadLine() public {
        vm.warp(startAt + 1 days);
        msgTknSc.mint(address(1), 1000);
        assertEq(msgTknSc.balanceOf(address(1)), 1000);
    }

    // @Notice Should fail on tokens transfer before mintingAndLockDeadLine
    function testFailTransferTokensBeforeDeadline() public {
        msgTknSc.mint(address(1), 1000);
        vm.prank(address(1));
        msgTknSc.transfer(address(2), 500);
        assertEq(msgTknSc.balanceOf(address(2)), 500);
    }

    function testTransferAfterDeadline() public {
        msgTknSc.mint(address(1), 1000);
        vm.warp(mintingAndLockDeadline + 1 hours);
        vm.prank(address(1));
        msgTknSc.transfer(address(2), 500);
        assertEq(msgTknSc.balanceOf(address(2)), 500);
    }

    //function testFuzz_SetNumber(uint256 x) public {
    //    counter.setNumber(x);
    //    assertEq(counter.number(), x);
    //}
}
