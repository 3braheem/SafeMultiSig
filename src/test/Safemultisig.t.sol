// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";
import "./utils/SafemultisigTest.sol";

contract Submit is SafemultisigTest {

    function testOwners() public {
        assertEq(sOwners.length, 1);
    }
    
    function testAddOwner() public {

    }

    function testRemoveOwner() public {

    }

    function testSubmitTx() public {
        alice.submitTx(address(bob), 1 ether, "");
        // Transaction aliceTx = transactions[0];
    }

    function testConfirmTx() public {

    }

    function testRevokeConfirmation() public {

    }

    function testExecuteTx() public {
        
    }
}

