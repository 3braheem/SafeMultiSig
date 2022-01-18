// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

/// @title Multi-Signature wallet contract
/// @author 3braheem 
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

    /// @notice             Emitted when the contract receives deposits
    /// @param _sender      Address who sent funds
    /// @param _value       Value of funds received        
    event FundsReceived(
        address indexed _sender, 
        uint256 indexed _value
    );

    /// @notice             Emitted when a pending tx is confirmed by an owner
    /// @param owner        Owner who confirmed a pending tx
    /// @param txIndex      Index of confirmed tx in Transactions array
    event ConfirmTransaction(
        address indexed owner, 
        uint256 indexed txIndex
    );

    /// @notice             Emitted when a tx is executed
    /// @param owner        Owner who executed the tx
    /// @param txIndex      Index of executed tx in Transactions array
    event ExecuteTransaction(
        address indexed owner, 
        uint256 indexed txIndex
    );

    /// @notice             Emitted when a confirmation for a tx is revoked 
    /// @param owner        Owner who revoked their confirmation
    /// @param txIndex      Index of revoked tx in Transactions array
    event RevokeConfirmation(
        address indexed owner, 
        uint256 indexed txIndex
    );

    /// @notice             Emitted when a new tx is submitted
    /// @param owner        Owner who submitted the new tx
    /// @param txIndex      Index of confirmed tx in Transactions array
    /// @param to           Address submitted tx is sending to
    /// @param value        Value of submitted tx
    /// @param data         Data to be sent by submitted tx
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );

    /// @notice             Emitted when a new address `owner` becomes an owner
    /// @param owner        Owner who was added to the owners array
    event OwnerAdded(
        address indexed owner
    );

    /// @notice             Emitted when an owner at index `index` is removed from owners array
    /// @param index      Index at which the removed owner was
    event OwnerRemoved(
        uint256 indexed index
    );

    /// @notice             Basic requirements for txs to be valid and working
    /// @param ownerCount   Amount of owners specified in the owners array
    /// @param _threshold   The minimum required owners to confirm a tx for it to be executable
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

    /// @notice             Requires addresses to be non-null
    /// @param _address     Inputted address that must be a real address
    modifier notNull(address _address) {
        require(_address != address(0), "Null.");
        _;
    }

    /// @notice             Determines if a user is an owner 
    /// @param _claimant    Address trying to access permissioned functions
    modifier isAnOwner(address _claimant) {
        require(ownerState[_claimant], "Lacks permissions.");
        _;
    }

    /// @notice             Determines if a user is not at owner
    /// @param _claimant    Address trying to access permissioned functions
    modifier notAnOwner(address _claimant) {
        require(!ownerState[_claimant], "Already in ownership.");
        _;
    }

    /// @notice             Checks to see if stated tx at `_txIndex` is existing
    /// @param _txIndex     Index of tx in the Transactions array
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Tx non-existent.");
        _;
    }

    /// @notice             Checks if tx at index `_txIndex` has already been executed
    /// @param _txIndex     Index of tx in the Transactions array
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "Already executed.");
        _;
    }

    /// @notice             Checks if tx at index `_txIndex` has not yet been confirmed
    /// @param _txIndex     Index of tx in the Transactions array
    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "Already confirmed.");
        _;
    }

    /// @notice             Checks if tx at index `_index` has been confirmed by msg.sender
    /// @param _txIndex     Index of tx in the Transactions array
    modifier beenConfirmed(uint256 _txIndex) {
        require(isConfirmed[_txIndex][msg.sender], "You have not confirmed this tx yet.");
        _;
    }

    /// @notice             Initializes new multi-sig wallet
    /// @param _owners      Array of owners of the wallet
    /// @param _threshold   Minimum required number of confirmations to execute a tx
    constructor(address[] memory _owners, uint256 _threshold)
        validInputs(_owners.length, _threshold)
        payable
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            require(
                !ownerState[_owners[i]] && _owners[i] != address(0),
                "Those are invalid Inputs."
            );
            ownerState[_owners[i]] = true;
            owners.push(_owners[i]);
        }
        threshold = _threshold;
    }

    /// @notice             fallback function
    fallback() external payable {
        if (msg.value > 0) {
            emit FundsReceived(msg.sender, msg.value);
        }
    }

    /// @notice             Submits a tx going to `_to` with value `_value` and data `_data`
    /// @param _to          Address to receive tx
    /// @param _value       Value to be included in tx 
    /// @param _data        Data to be sent with tx
    function submitTx(
        address _to,
        uint256 _value,
        bytes calldata _data
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

    /// @notice             Confirms tx at index `_txIndex`
    /// @param _txIndex     The index of the tx to be confirmed
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

    /// @notice             Revokes confirmation of tx at index `_txIndex`
    /// @param _txIndex     The index of the tx to have a confirmation revoked
    function revokeConfirmation(uint256 _txIndex)
        public
        isAnOwner(msg.sender)
        txExists(_txIndex)
        notExecuted(_txIndex)
        beenConfirmed(_txIndex)
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

    /// @notice             Executes tx at index `_txIndex` if threshold of confirmations is passed
    /// @param _txIndex     The index of the tx to be executed
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

    /// @notice             Function to add a new owner `_owner` to the wallet, must be sent as a tx
    /// @param _owner       New owner to be added
    function addOwner(address _owner)
        external
        notAnOwner(_owner)
        notNull(_owner)
        validInputs(owners.length + 1, threshold)
    {
        require(msg.sender == address(this), "Must be confirmed through wallet.");
        ownerState[_owner] = true;
        owners.push(_owner);
        emit OwnerAdded(_owner);
    }

    /// @notice             Submits a tx to add new owner `_owner` to the wallet
    /// @param _owner       New owner to be added
    function addOwnerTx(address _owner) 
        external 
        notAnOwner(_owner)
        notNull(_owner) 
        validInputs(owners.length + 1, threshold) 
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

    /// @notice             Function to remove an owner at index `_index`, must be sent as a tx
    /// @param _index       Index of owner to be removed in owners array
    function removeOwner(uint256 _index)
        external
        isAnOwner(owners[_index])
        validInputs(owners.length - 1, threshold)
    {
        require(msg.sender == address(this), "Must be confirmed through wallet.");
        for (uint256 i = _index; i < owners.length - 1; i++) {
            owners[_index] = owners[_index + 1];
        }
        ownerState[owners[_index]] = false;
        owners.pop();
        emit OwnerRemoved(_index);
    }

    /// @notice             Submits a tx to remove owner at index `_index` from the wallet
    /// @param _index       Index of owner to be removed in owners array
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

    /// @notice             Helper function to retrieve contract balance
    /// @return             Contract balance
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice             Helper function to retrieve owners of the wallet
    /// @return             owners array
    function walletOwners() external view returns (address[] memory) {
        return owners;
    }
}