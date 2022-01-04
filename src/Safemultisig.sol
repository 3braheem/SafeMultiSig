// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

// @dev Multi-Signature safe contract, designed to be simple and straightforward.
contract Safemultisig {
    mapping(address => bool) internal ownerState;
    mapping(uint256 => mapping(address => bool)) internal isConfirmed;
    uint256 public maxOwners = 50;
    uint256 public threshold;
    address[] public owners;

    struct Transaction {
        address from;
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }
    Transaction[] public transactions;

    event FundsReceived(address indexed _sender, uint256 indexed _value);
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );

    modifier validInputs(uint256 ownerCount, uint256 _threshold) {
        require(
            ownerCount > 0 &&
                _threshold <= ownerCount &&
                ownerCount <= maxOwners &&
                _threshold > 0
                , "Invalid Inputs."
        );
        _;
    }
    modifier notNull(address _address) {
        require(_address != address(0), "Null.");
        _;
    }
    modifier isAnOwner(address _claimaint) {
        require(ownerState[_claimaint], "Lacks permissions.");
        _;
    }
    modifier notAnOwner(address _claimant) {
        require(!ownerState[_claimant], "Already in ownership.");
        _;
    }
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Tx non-existent.");
        _;
    }
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "Already executed.");
        _;
    }
    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "Already confirmed.");
        _;
    }

    constructor(address[] memory _owners, uint256 _threshold)
        validInputs(_owners.length, _threshold)
        payable
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            require(
                !ownerState[_owners[i]],
                "Those are invalid Inputs."
            );
            ownerState[_owners[i]] = true;
            owners.push(_owners[i]);
        }
        threshold = _threshold;
    }

    receive() external payable {
        if (msg.value > 0) {
            emit FundsReceived(msg.sender, msg.value);
        }
    }

    function submitTx(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public isAnOwner(msg.sender) {
        uint256 txIndex = transactions.length;
        transactions.push(
            Transaction({
                from: msg.sender,
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTx(uint256 _txIndex)
        public
        isAnOwner(msg.sender)
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        isConfirmed[_txIndex][msg.sender] = true;
        transaction.numConfirmations++;
        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        isAnOwner(msg.sender)
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(
            transaction.numConfirmations > 0,
            "No confirmations to revoke."
        );
        isConfirmed[_txIndex][msg.sender] = false;
        transaction.numConfirmations--;
        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function executeTx(uint256 _txIndex)
        public
        payable
        isAnOwner(msg.sender)
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(
            transaction.numConfirmations >= threshold,
            "Not enough signers."
        );
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "Something went wrong.");
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function addOwner(address _owner)
        internal
        notAnOwner(_owner)
        notNull(_owner)
        validInputs(owners.length + 1, threshold)
    {
        require(msg.sender == address(this), "Must be confirmed through wallet.");
        ownerState[_owner] = true;
        owners.push(_owner);
    }

    function addOwnerTx(address _owner) 
        external 
        notAnOwner(_owner)
        notNull(_owner) 
        validInputs(owners.length - 1, threshold) 
    {
        bytes memory payload = abi.encodeWithSignature("addOwner(address)", _owner);
        uint256 txIndex = transactions.length;
        transactions.push(
            Transaction({
                from: msg.sender,
                to: address(this),
                value: 0,
                data: payload,
                executed: false,
                numConfirmations: 0
            })
        );
        emit SubmitTransaction(msg.sender, txIndex, address(this), 0, payload);
    }

    function removeOwner(uint256 _index)
        internal
        isAnOwner(owners[_index])
        validInputs(owners.length - 1, threshold)
    {
        require(msg.sender == address(this), "Must be confirmed through wallet.");
        for (uint256 i = _index; i < owners.length - 1; i++) {
            owners[_index] = owners[_index + 1];
        }
        ownerState[owners[_index]] = false;
        owners.pop();
    }

    function removeOwnerTx(uint256 _index) 
        external 
        isAnOwner(owners[_index]) 
        validInputs(owners.length - 1, threshold) 
    {
        bytes memory payload = abi.encodeWithSignature("removeOwner(uint256)", _index);
        uint256 txIndex = transactions.length;
        transactions.push(
            Transaction({
                from: msg.sender,
                to: address(this),
                value: 0,
                data: payload,
                executed: false,
                numConfirmations: 0
            })
        );
        emit SubmitTransaction(msg.sender, txIndex, address(this), 0, payload);
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function safeOwners() external view returns (address[] memory) {
        return owners;
    }
}