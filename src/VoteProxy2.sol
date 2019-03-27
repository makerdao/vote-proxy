// VoteProxy2 - A cold/hot proxy contract and key setup for voting on DSChief
pragma solidity ^0.4.24;

import 'ds-token/token.sol';
import 'ds-chief/chief.sol';

contract VoteProxy2 {
    address public cold;
    address public hot;
    DSToken public GOV;
    DSToken public IOU;
    DSChief chief;

    constructor(DSChief chief_, address cold_, address hot_) {
        chief = chief_;
        cold = cold_;
        hot = hot_;
        GOV = chief.GOV();
        IOU = chief.IOU();
        GOV.approve(chief, uint256(-1));
        IOU.approve(chief, uint256(-1));
    }

    // Hot and Cold addresses end up with same access tier - this is
    // because `release` pushes to the Cold address, not to the sender
    modifier hotOrCold() { require(msg.sender == cold || msg.sender == hot); _ }

    function vote(bytes32 slate)
        hotOrCold
    {
        chief.vote(slate);
    }
    function lock(uint256 wad)
        hotOrCold
    {
        chief.lock(wad);
    }
    function free(uint256 wad)
        hotOrCold
    {
        chief.free(wad);
    }
    function release(uint256 wad)
        hotOrCold
    {
        GOV.push(cold, wad);
    }
}


