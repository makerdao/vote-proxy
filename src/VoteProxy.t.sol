pragma solidity ^0.4.21;

import "ds-test/test.sol";

import "./VoteProxy.sol";

contract VoteProxyTest is DSTest {
    VoteProxy proxy;

    function setUp() public {
        proxy = new VoteProxy();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
