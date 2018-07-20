pragma solidity ^0.4.21;

import "ds-token/token.sol";
import "ds-chief/chief.sol";

contract VoteProxy {
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

  // actions which can be called from the hot wallet
  function vote(address[] yays) public canExecute returns (bytes32 slate) {
    return chief.vote(yays);
  }

  function vote(bytes32 slate) public canExecute {
    chief.vote(slate);
  }

  function etch(address[] yays) public canExecute returns (bytes32 slate) {
    return chief.etch(yays);
  }

  // lock proxy cold
  // free proxy cold
}
