// VoteProxy2 - A cold/hot proxy contract and key setup for voting on DSChief
pragma solidity >=0.5.6;

import 'ds-token/token.sol';
import 'ds-chief/chief.sol';

contract VoteProxy2 {
    address public cold;
    address public hot;
    DSToken public GOV;
    DSToken public IOU;
    DSChief chief;

    event Touch(address indexed sender, bytes4 func);

    constructor(DSChief chief_, address cold_, address hot_)
        public
    {
        chief = chief_;
        cold = cold_;
        hot = hot_;
        GOV = chief.GOV();
        IOU = chief.IOU();
        GOV.approve(address(chief), uint256(-1));
        IOU.approve(address(chief), uint256(-1));
    }

    // Hot and Cold addresses end up with same access tier - this is
    // because `release` pushes to the Cold address, not to the sender
    modifier controlled() {
        require(msg.sender == cold || msg.sender == hot);
        emit Touch(msg.sender, msg.sig);
        _;
    }

    function vote(bytes32 slate)
        public controlled
    {
        chief.vote(slate);
    }
    function lock(uint256 wad)
        public controlled
    {
        chief.lock(wad);
    }
    function free(uint256 wad)
        public controlled
    {
        chief.free(wad);
    }
    function release(uint256 wad)
        public controlled
    {
        GOV.push(cold, wad);
    }
}


