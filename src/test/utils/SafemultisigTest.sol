// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
import "ds-test/test.sol";

import "../../Safemultisig.sol";
import "./Hevm.sol";

contract User {
    Safemultisig internal safe;

    constructor(address payable _sig) {
        safe = Safemultisig(_sig);
    }

    function submitTx(address _to, uint128 _value, bytes memory _data) public {
        safe.submitTx(_to, _value, _data);
    }

    function confirmTx(uint128 _txIndex) public {
        safe.confirmTx(_txIndex);
    }

    function revokeConfirmation(uint128 _txIndex) public {
        safe.revokeConfirmation(_txIndex);
    }

    function executeTx(uint128 _txIndex) public {
        safe.executeTx(_txIndex);
    }

    function addOwner(address _owner) public {
        safe.addOwner(_owner);
    }

    function removeOwner(uint256 _index) public {
        safe.removeOwner(_index);
    }

}

contract Owns {
    Safemultisig internal safe;
}

abstract contract SafemultisigTest is DSTest {
    Hevm internal constant hevm = Hevm(HEVM_ADDRESS);

    // contracts
    Safemultisig internal safe;
    Owns internal owns;
    
    // users
    User internal alice;
    User internal bob;
    address[] public sOwners;

    function setUp() public virtual {
        sOwners.push(address(alice));
        safe = new Safemultisig(sOwners, 1);
        alice = new User(payable(address(safe)));
        bob = new User(payable(address(safe)));
    }
}
