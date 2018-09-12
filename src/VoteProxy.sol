// VoteProxy - vote w/ a hot or cold wallet using a proxy identity
pragma solidity ^0.4.24;

import "ds-token/token.sol";
import "ds-chief/chief.sol";

contract VoteProxy {
    address public cold;
    address public hot;
    DSToken public gov;
    DSToken public iou;
    DSChief public chief;

    constructor(DSChief _chief, address _cold, address _hot) public {
        chief = _chief;
        cold = _cold;
        hot = _hot;
        
        gov = chief.GOV();
        iou = chief.IOU();
        gov.approve(chief, uint256(-1));
        iou.approve(chief, uint256(-1));
    }

    modifier auth() {
        require(msg.sender == hot || msg.sender == cold, "Sender must be a Cold or Hot Wallet");
        _;
    }
    
    function lock(uint256 wad) public auth {
        gov.pull(cold, wad);   // mkr from cold
        chief.lock(wad);       // mkr out, ious in
    }

    function free(uint256 wad) public auth {
        chief.free(wad);       // ious out, mkr in
        gov.push(cold, wad);   // mkr to cold
    }

    function freeAll() public auth {
        chief.free(chief.deposits(this));            
        gov.push(cold, gov.balanceOf(this)); 
    }

    function vote(address[] yays) public auth returns (bytes32) {
        return chief.vote(yays);
    }

    function vote(bytes32 slate) public auth {
        chief.vote(slate);
    }
}
