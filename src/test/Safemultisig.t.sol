// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";
import "./utils/SafemultisigTest.sol";

import "../Safemultisig.sol";

contract Submit is SafemultisigTest {
    function test_submitTx(
        address _to,
        uint128 _value,
        bytes memory _data
    ) public {
        safe.submitTx(_to, _value, _data);
        assertEq(safe.submitTx(_to, _value, _data), true);
    }
}

