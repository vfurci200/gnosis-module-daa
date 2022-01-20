// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./Enum.sol";
import "./SignatureDecoder.sol";


interface GnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);
    
    function getOwners() external view returns (address[] memory);

    function enableModule(address module) external;
}

contract DaaModule is SignatureDecoder {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public _whitelisted;
    GnosisSafe public _safe;
    EnumerableSet.AddressSet private _spenders;


    event ExecuteTransfer(address indexed safe, address token, address to, uint96 value);
    
    constructor(address whitelisted, GnosisSafe safe){
        _whitelisted = whitelisted;
        _safe = safe;
        address[] memory spenders = safe.getOwners();
        uint256 len = spenders.length;
        for (uint256 i = 0; i < len; i++) {
            address spender = spenders[i];
            require(_spenders.add(spender), "Owner is already registered");
            _spenders.add(spender);
        }
    }
    

    /// @dev Allows to perform a transfer.
    /// @param token Token contract address.
    /// @param to Address that should receive the tokens.
    /// @param amount Amount that should be transferred.
    function executeTransfer(
        address token,
        address payable to,
        uint96 amount
    ) 
        public 
        isAuthorized(msg.sender)
    {
        require(to == _whitelisted,"Address not whitelisted");
        // Transfer token
        transfer(_safe, token, to, amount);
        emit ExecuteTransfer(address(_safe), token, to, amount);
    }

    function transfer(GnosisSafe safe, address token, address payable to, uint96 amount) private {
        if (token == address(0)) {
            // solium-disable-next-line security/no-send
            require(safe.execTransactionFromModule(to, amount, "", Enum.Operation.Call), "Could not execute ether transfer");
        } else {
            bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
            require(safe.execTransactionFromModule(token, 0, data, Enum.Operation.Call), "Could not execute token transfer");
        }
    }

    modifier isAuthorized(address sender) {
        require(_spenders.contains(sender), "Sender not authorized");
        _;
    }
}