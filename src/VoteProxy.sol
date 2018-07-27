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
    chief.free(chief.deposits(this));
    withdraw(chief.GOV().balanceOf(this));
  }

  function unlockWithdraw(uint amt) public canExecute {
    uint here = chief.GOV().balanceOf(this);
    require(amt <= add(chief.deposits(this), here), "amount requested for withdrawal is more than what is available");
    if (here < amt) {
      chief.free(sub(amt, here));
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
    chief.lock(chief.GOV().balanceOf(this));
    return chief.vote(yays);
  }

  function lockAllVote(bytes32 slate) public canExecute {
    chief.lock(chief.GOV().balanceOf(this));
    chief.vote(slate);
  }

  function etch(address[] yays) public canExecute returns (bytes32 slate) {
    return chief.etch(yays);
  }

  // lock proxy cold
  // free proxy cold
}
