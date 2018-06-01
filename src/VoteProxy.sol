pragma solidity ^0.4.21;

import "ds-token/token.sol";
import "ds-chief/chief.sol";

contract VoteProxy {
  address cold;
  address hot;
  DSToken gov;
  DSToken iou;
  DSChief chief;

  function VoteProxy(DSToken gov_, DSChief chief_, DSToken iou_, address cold_, address hot_) public {
    cold = cold_;
    hot = hot_;
    gov = gov_;
    chief = chief_;
    iou = iou_;
    gov.approve(chief, uint(-1));
    iou.approve(chief, uint(-1));
  }

  modifier canExecute() {
    require(msg.sender == hot || msg.sender == cold);
    _;
  }

  function approve(uint amt) public canExecute {
    gov.approve(chief, amt);
    iou.approve(chief, amt);
  }

  function lock(uint amt) public canExecute {
    chief.lock(amt);
  }

  function free(uint amt) public canExecute {
    chief.free(amt);
  }

  function withdraw(uint amt) public canExecute {
    gov.transfer(cold, amt);
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
