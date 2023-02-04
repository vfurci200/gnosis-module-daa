// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IGnosisSafe} from "../src/interfaces/IGnosisSafe.sol";
import {IERC20Minimal} from "../src/interfaces/IERC20Minimal.sol";
import {DaaModule} from "../src/contracts/DaaModule.sol";
import {DaaModuleV2} from "../src/contracts/DaaModuleV2.sol";

contract DaaModulesTest is Test {
    DaaModule public daaModuleV1;
    DaaModuleV2 public daaModuleV2;
    IGnosisSafe public safe;
    IGnosisSafe public safeAuth;
    IERC20Minimal public usdc;
    address[] public safeOwners;
    address[] public safeAuthOwners;
    address payable targetWhitelisted;

    function setUp() public {
        // get random safe
        safe = IGnosisSafe(0x1A8c53147E7b61C015159723408762fc60A34D17);
        // get random safe for auth
        safeAuth = IGnosisSafe(0x7951c7ef839e26F63DA87a42C9a87986507f1c07);
        usdc = IERC20Minimal(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        targetWhitelisted = payable(address(0x369369));
        safeOwners = safe.getOwners();
        safeAuthOwners = safeAuth.getOwners();
        daaModuleV1 = new DaaModule(targetWhitelisted,safe);
        daaModuleV2 = new DaaModuleV2(safe,safeAuth,targetWhitelisted);
        vm.prank(address(safe));
        safe.enableModule(address(daaModuleV1));
        vm.prank(address(safe));
        safe.enableModule(address(daaModuleV2));
    }

    // ----- * V1 TESTS * ----- // 

    function testV1Deployment() public {
        vm.prank(address(safe));
        address _whitelisted = daaModuleV1._whitelisted();
        IGnosisSafe _safe = daaModuleV1._safe();
        assert(_whitelisted == targetWhitelisted);
        assert(_safe == safe);
    }

    function testV1ERC20Withdraw() public {
        vm.prank(address(safe));
        address whitelisted = daaModuleV1._whitelisted();
        uint balancePre = usdc.balanceOf(whitelisted);
        vm.prank(address(safeOwners[0]));
        daaModuleV1.executeTransfer(address(usdc),10*10**6);
        assert(balancePre == usdc.balanceOf(whitelisted) - 10*10**6);
    }

    function testV1ETHWithdraw() public {
        vm.prank(address(safe));
        address whitelisted = daaModuleV1._whitelisted();
        uint balancePre = whitelisted.balance;
        vm.prank(address(safeOwners[0]));
        daaModuleV1.executeTransfer(address(0),10*10**6);
        assert(balancePre == whitelisted.balance - 10*10**6);
    }

    function testV1ERC20WithdrawFail(address addr) public {
        vm.assume(!contains(safeOwners,addr));
        vm.prank(address(safe));
        address whitelisted = daaModuleV1._whitelisted();
        uint balancePre = usdc.balanceOf(whitelisted);
        vm.expectRevert("Sender not authorized");
        vm.prank(addr);
        daaModuleV1.executeTransfer(address(usdc),10*10**6);
        assert(balancePre == usdc.balanceOf(whitelisted));
    }

    function testV1ETHWithdrawFail(address addr) public {
        vm.assume(!contains(safeOwners,addr));
        vm.prank(address(safe));
        address whitelisted = daaModuleV1._whitelisted();
        uint balancePre = whitelisted.balance;
        vm.expectRevert("Sender not authorized");
        vm.prank(addr);
        daaModuleV1.executeTransfer(address(0),10*10**6);
        assert(balancePre == whitelisted.balance);
    }


    // ----- * V2 TESTS * ----- // 


    function testV2Deployment() public {
        vm.prank(address(safe));
        address _whitelisted = daaModuleV2._whitelisted();
        IGnosisSafe _safe = daaModuleV2.targetSafe();
        IGnosisSafe _authSafe = daaModuleV2.authSafe();
        assert(_whitelisted == targetWhitelisted);
        assert(_safe == safe);
        assert(_authSafe == safeAuth);
    }

    function testV2ERC20Withdraw() public {
        vm.prank(address(safe));
        address whitelisted = daaModuleV2._whitelisted();
        uint balancePre = usdc.balanceOf(whitelisted);
        vm.prank(address(safeAuthOwners[0]));
        daaModuleV2.executeTransfer(address(usdc),10*10**6);
        assert(balancePre == usdc.balanceOf(whitelisted) - 10*10**6);
    }

    function testV2ETHWithdraw() public {
        vm.prank(address(safe));
        address whitelisted = daaModuleV2._whitelisted();
        uint balancePre = whitelisted.balance;
        vm.prank(address(safeAuthOwners[0]));
        daaModuleV2.executeTransfer(address(0),10*10**6);
        assert(balancePre == whitelisted.balance - 10*10**6);
    }

    function testV2ERC20WithdrawFail() public {
        vm.prank(address(safe));
        address whitelisted = daaModuleV2._whitelisted();
        uint balancePre = usdc.balanceOf(whitelisted);
        vm.expectRevert("Sender not authorized");
        vm.prank(address(safeOwners[0]));
        daaModuleV2.executeTransfer(address(usdc),10*10**6);
        assert(balancePre == usdc.balanceOf(whitelisted));
    }

    function testV2ETHWithdrawFail() public {
        vm.prank(address(safe));
        address whitelisted = daaModuleV2._whitelisted();
        uint balancePre = whitelisted.balance;
        vm.expectRevert("Sender not authorized");
        vm.prank(address(safeOwners[0]));
        daaModuleV2.executeTransfer(address(0),10*10**6);
        assert(balancePre == whitelisted.balance);
    }

    function testV2ERC20WithdrawFailFuzz(address addr) public {
        vm.assume(!contains(safeAuthOwners,addr));
        vm.prank(address(safe));
        address whitelisted = daaModuleV2._whitelisted();
        uint balancePre = usdc.balanceOf(whitelisted);
        vm.expectRevert("Sender not authorized");
        vm.prank(addr);
        daaModuleV2.executeTransfer(address(usdc),10*10**6);
        assert(balancePre == usdc.balanceOf(whitelisted));
    }

    function testV2ETHWithdrawFailFuzz(address addr) public {
        vm.assume(!contains(safeAuthOwners,addr));
        vm.prank(address(safe));
        address whitelisted = daaModuleV2._whitelisted();
        uint balancePre = whitelisted.balance;
        vm.expectRevert("Sender not authorized");
        vm.prank(addr);
        daaModuleV2.executeTransfer(address(0),10*10**6);
        assert(balancePre == whitelisted.balance);
    }

    // ----- * UTILS * ----- // 

    function contains(
        address[] memory arr, 
        address addr) 
        internal 
        view 
        returns (bool res)
    {
        uint len = arr.length;
        for(uint i =0; i< len; ++i){
            if (arr[i] == addr){
                res = true;
            }
        }
    }
}

