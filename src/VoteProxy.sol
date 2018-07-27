pragma solidity ^0.4.21;

import "ds-token/token.sol";
import "ds-chief/chief.sol";

contract VoteProxy is DSMath {
  address public cold;
  address public hot;
  DSChief public chief;

  function VoteProxy(DSChief chief_, address cold_, address hot_) public {
    cold = cold_;
    hot = hot_;
    chief = chief_;
    chief.GOV().approve(chief, uint(-1));
    chief.IOU().approve(chief, uint(-1));
  }

  modifier canExecute() {
    require(msg.sender == hot || msg.sender == cold);
    _;
  }

  function approve(uint amt) public canExecute {
    chief.GOV().approve(chief, amt);
    chief.IOU().approve(chief, amt);
  }

  function lock(uint amt) public canExecute {
    chief.lock(amt);
  }

  function free(uint amt) public canExecute {
    chief.free(amt);
  }

  function withdraw(uint amt) public canExecute {
    chief.GOV().transfer(cold, amt);
  }

  function unlockWithdrawAll() public canExecute {
    uint locked = chief.deposits(this);
    chief.free(locked);
    uint amt = chief.GOV().balanceOf(this);
    withdraw(amt);
  }

  function unlockWithdraw(uint amt) public canExecute {
    uint locked = chief.deposits(this);
    uint here = chief.GOV().balanceOf(this);
    uint available = add(locked, here);
    require(amt <= available, "amount requested for withdrawal is more than what is available");
    if (here < amt) {
      uint diff = sub(amt, here);
      chief.free(diff);
    }
    withdraw(amt);
  }

  function vote(address[] yays) public canExecute returns (bytes32 slate) {
    return chief.vote(yays);
  }

  function vote(bytes32 slate) public canExecute {
    chief.vote(slate);
  }

  function lockAllVote(address[] yays) public canExecute returns (bytes32 slate) {
    uint amt = chief.GOV().balanceOf(this);
    chief.lock(amt);
    return chief.vote(yays);
  }

  function lockAllVote(bytes32 slate) public canExecute {
    uint amt = chief.GOV().balanceOf(this);
    chief.lock(amt);
    chief.vote(slate);
  }

  function etch(address[] yays) public canExecute returns (bytes32 slate) {
    return chief.etch(yays);
  }

  // lock proxy cold
  // free proxy cold
}
