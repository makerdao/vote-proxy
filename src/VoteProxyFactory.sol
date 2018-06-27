pragma solidity ^0.4.21;

import "./VoteProxy.sol";

contract VoteProxyFactory {
    DSChief public chief;
    DSToken public gov;
    DSToken public iou;
    mapping(address=>VoteProxy) public hotMap;
    mapping(address=>VoteProxy) public coldMap;
    
    constructor(DSChief chief_) public {
        chief = chief_;
        gov = chief.GOV();
        iou = chief.IOU();
    }
    
    function newVoteProxy(address cold_, address hot_) public returns (VoteProxy voteProxy) {
        require(cold_ == msg.sender, "Vote Proxy must be created by cold wallet");
        require(
            coldMap[cold_] == address(0) && hotMap[cold_] == address(0), 
            "Cold wallet cannot already have a Vote Proxy associated with it"
            );
       require(
            coldMap[hot_] == address(0) && hotMap[hot_] == address(0), 
            "Hot wallet cannot already have a Vote Proxy associated with it"
            );
        voteProxy = new VoteProxy(gov, chief, iou, cold_, hot_);
        hotMap[hot_] = voteProxy;
        coldMap[cold_] = voteProxy;
    }
}
