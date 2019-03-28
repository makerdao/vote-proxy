pragma solidity >=0.5.6;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-chief/chief.sol";

import "./VoteProxy2Factory.sol";

contract ProxyUser {
    DSChief chief;
    DSToken gov;
    DSToken iou;
    VoteProxy2 public proxy;

    constructor(DSChief chief_, DSToken gov_, DSToken iou_) public {
        chief = chief_;
        gov = gov_;
        iou = iou_;
    }

    function setProxy(VoteProxy2 proxy_) public {
        proxy = proxy_;
    }

    function doChiefLock(uint amt) public {
        chief.lock(amt);
    }

    function doChiefFree(uint amt) public {
        chief.free(amt);
    }

    function doTransferGov(address guy, uint amt) public {
        gov.transfer(guy, amt);
    }

    function doApproveGov(address guy) public {
        gov.approve(guy);
    }

    function doApproveIou(address guy) public {
        iou.approve(guy);
    }

    function doProxyLock(uint wad) public {
        proxy.lock(wad);
    }

    function doProxyFree(uint wad) public {
        proxy.free(wad);
    }

    function doProxyVote(bytes32 slate) public {
        proxy.vote(slate);
    }

    function doProxyRelease(uint wad) public {
        proxy.release(wad);
    }
}

contract VoteProxyTest is DSTest {
    address constant c1 = address(0x1);
    address constant c2 = address(0x2);

    VoteProxy2 proxy;
    ProxyUser cold;
    ProxyUser hot;
    ProxyUser evil;

    DSToken gov;
    DSToken iou;
    DSChief chief;

    function setUp() public {
        gov = new DSToken("GOV");
        iou = new DSToken("IOU");
        chief = new DSChief(gov, iou, 3);
        cold = new ProxyUser(chief, gov, iou);
        hot = new ProxyUser(chief, gov, iou);
        evil = new ProxyUser(chief, gov, iou);
        proxy = new VoteProxy2(chief, address(cold), address(hot));
        cold.setProxy(proxy);
        hot.setProxy(proxy);
        evil.setProxy(proxy);
        gov.mint(address(cold), 100 ether);
        gov.mint(address(hot), 100 ether);
        gov.mint(address(evil), 100 ether);
    }
}
