// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IGnosisSafe.sol";

/// @title Safe Module DAA - A gnosis safe module to execute transactions to a trusted whitelisted address.
/// @author vinc.eth


contract DaaModuleV2 {

    address payable public _whitelisted;
    IGnosisSafe public targetSafe;
    IGnosisSafe public authSafe;
    string public constant name = "DAA Withdraw Module";
    string public constant version  = "2";


    event ExecuteTransfer(address indexed safe, address token, address from, address to, uint96 value);
    
    constructor(IGnosisSafe _targetSafe, IGnosisSafe _authSafe, address payable whitelisted){
        targetSafe = _targetSafe;
        authSafe = _authSafe;
        if (whitelisted != address(0)){
            _whitelisted = whitelisted;
        } else {
            _whitelisted = payable(address(_authSafe));
        }
    }
    
    /// @dev Allows to perform a transfer to the whitelisted address.
    /// @param token Token contract address. Address(0) for ETH transfers.
    /// @param amount Amount that should be transferred.
    function executeTransfer(
        address token,
        uint96 amount
    ) 
        public 
    {
        isAuthorized(msg.sender);
        // Transfer token
        transfer(targetSafe, token, _whitelisted, amount);
        emit ExecuteTransfer(address(targetSafe), token, msg.sender, _whitelisted, amount);
    }

    function transfer(IGnosisSafe safe, address token, address payable to, uint96 amount) private {
        if (token == address(0)) {
            // solium-disable-next-line security/no-send
            require(safe.execTransactionFromModule(to, amount, "", Enum.Operation.Call), "Could not execute ether transfer");
        } else {
            bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
            require(safe.execTransactionFromModule(token, 0, data, Enum.Operation.Call), "Could not execute token transfer");
        }
    }

    function isAuthorized(address sender) internal view returns (bool isOwner){
        address[] memory _owners = authSafe.getOwners();
        uint256 len = _owners.length;
        for (uint256 i = 0; i < len; i++) {
            if (_owners[i]==sender) { isOwner = true;}
        }
        require(isOwner, "Sender not authorized");
    }
}
