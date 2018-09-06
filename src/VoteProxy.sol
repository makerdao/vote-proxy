// VoteProxy - vote w/ a proxy identity

pragma solidity ^0.4.24;

import "ds-token/token.sol";
import "ds-chief/chief.sol";
import "./_polling.sol";


contract VoteProxy {
    address public cold;
    address public hot;
    DSToken public gov;
    DSToken public iou;
    DSChief public chief;
    Polling public polling;

    constructor(DSChief _chief, Polling _polling, address _cold, address _hot) 
      public 
    {
        hot = _hot;
        cold = _cold;
        chief = _chief;
        polling = _polling;
        
        gov = chief.GOV();
        iou = chief.IOU();
        gov.approve(chief, uint256(-1));
        iou.approve(chief, uint256(-1));
        iou.approve(polling, uint256(-1));
    }

    modifier auth() {
        require(msg.sender == hot || msg.sender == cold);
        _;
    }
    
    function lock(uint256 wad, bool _poll) public auth {
        gov.pull(cold, wad);          // mkr from cold 
        chief.lock(wad);              // mkr out, ious in
        if (_poll) polling.lock(wad); // ious out
    }

    function free(uint256 wad, bool _poll) public auth {
        if (_poll) polling.free(wad); // ious in
        chief.free(wad);              // ious out, mkr in
        gov.push(cold, wad);          // mkr to cold
    }

    function join() public auth {
        polling.lock(iou.balanceOf(this));      
    }

    function voteExec(address[] yays) public auth returns (bytes32) {
        return chief.vote(yays);
    }

    function voteExec(bytes32 slate) public auth {
        chief.vote(slate);
    }

    function voteGov(uint256 id, bool yay, bytes _logData) public auth {
        polling.vote(id, yay, _logData);
    }

    function retractGov(uint256 id) public auth {
        polling.unSay(id);
    }
}