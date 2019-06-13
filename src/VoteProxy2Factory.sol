pragma solidity >=0.5.6;

import './VoteProxy2.sol';


contract VoteProxy2Factory {

    event Make(address indexed sender, address indexed cold, address indexed hot);

    function make(DSChief chief, address cold, address hot)
        public returns (VoteProxy2)
    {
        emit Make(msg.sender, cold, hot);
        return new VoteProxy2(chief, cold, hot);
    }
}
