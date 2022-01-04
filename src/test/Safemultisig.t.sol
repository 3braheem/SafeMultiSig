// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";
import "./utils/SafemultisigTest.sol";

contract Owners is SafemultisigTest {
    function testOwners() public {
        assertEq(sOwners.length, 1);
    }
}

contract addOwner is SafemultisigTest {
    function testAddOwner() public {

    }
}

contract subOwner is SafemultisigTest {
    function testRemoveOwner() public {

    }
}

contract Submit is SafemultisigTest {
    function testSubmitTx() public {
        alice.submitTx(address(bob), 1 ether, "");
        // Transaction aliceTx = transactions[0];
    }  
}

contract Confirm is SafemultisigTest {
    function testConfirmTx() public {

    }
}

contract Revoke is SafemultisigTest {
    function testRevokeConfirmation() public {

    }
}

contract Execute is SafemultisigTest {
    function testExecuteTx() public {

    }
}

