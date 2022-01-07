// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";
import "./utils/SafemultisigTest.sol";

contract Owners is SafemultisigTest {
    function testOwners() public {
        assertEq(safe.owners.length, 1);
        assertEq(safe.owners[0], addr);
    }
}

contract AddOwner is SafemultisigTest {
    function testAddOwner() public {
        alice.addOwnerTx(address(bob));
        alice.confirmTx(0);
        alice.executeTx(0);
        assertTrue(safe.transactions[0].data != 0x0);
        assertEq(safe.transactions[0].to, address(safe));
        assertEq(safe.owners[1], address(bob));
    }
}

contract SubOwner is SafemultisigTest {
    function testRemoveOwner() public {
        alice.removeOwnerTx(1);
        alice.confirmTx(1);
        alice.executeTx(1);
        assertTrue(safe.transactions[1].data != 0x0);
        assertTrue(!safe.owners[1] == address(bob));
    }
}

contract Submit is SafemultisigTest {
    function testSubmitTx() public {
        alice.submitTx(address(bob), 1 ether, "");
        assertEq(safe.transactions[0].value, 1 ether);
        assertEq(safe.transactions[0].numConfirmations, 0);
        alice.submitTx(address(bob), 1 wei, "");
        assertEq(safe.transactions[0].value, 1 wei);
        assertEq(safe.transactions[0].numConfirmations, 0);
    }  
}

contract Confirm is SafemultisigTest {
    function testConfirmTx() public {
        alice.confirmTx(0);
        assertTrue(safe.transactions[0].isConfirmed);
        alice.confirmTx(1);
        assertTrue(safe.transactions[1].isConfirmed);
    }
}

contract Revoke is SafemultisigTest {
    function testRevokeConfirmation() public {
        alice.revokeConfirmation(1);
        assertTrue(!safe.transactions[1].isConfirmed);
    }
}

contract Execute is SafemultisigTest {
    function testExecuteTx() public {
        alice.executeTx(0);
        assertTrue(safe.transactions[0].executed);
    }
}

