pragma solidity ^0.4.24;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-chief/chief.sol";

import "./VoteProxy2.sol";

contract Voter {
    DSChief chief;
    DSToken gov;
    DSToken iou;
    VoteProxy2 public proxy;

    constructor(DSChief chief_, DSToken gov_, DSToken iou_) public {
        chief = chief_;
        gov = gov_;
        iou = iou_;
    }

    function setProxy(VoteProxy proxy_) public {
        proxy = proxy_;
    }

    function doChiefLock(uint amt) public {
        chief.lock(amt);
    }

    function doChiefFree(uint amt) public {
        chief.free(amt);
    }

    function doTransfer(address guy, uint amt) public {
        gov.transfer(guy, amt);
    }

    function approveGov(address guy) public {
        gov.approve(guy);
    }

    function approveIou(address guy) public {
        iou.approve(guy);
    }

    function doProxyLock(uint wad) public {
        proxy.lock(wad);
    }

    function doProxyFree(uint wad) public {
        proxy.free(wad);
    }

    function doProxyVote(bytes32 slate) public {
        proxy.vote(wad);
    }

    function doProxyRelease(bytes32 slate) public {
        proxy.release(wad);
    }
}
