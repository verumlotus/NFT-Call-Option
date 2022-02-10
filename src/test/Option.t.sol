// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./base/BaseTest.sol";
import "../Option.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockERC721.sol";

contract OptionTest is BaseTest {
    MockERC20 mockToken;
    MockERC721 mockNft;

    Option option;
    address buyer;
    uint256 tokenId;

    function setUp() public {
        mockToken = new MockERC20();
        mockToken.mint(address(this), 100*10**mockToken.decimals());
        buyer = address(0x1234);
        mockToken.mint(buyer, 100*10**mockToken.decimals());
        mockNft = new MockERC721();
        option = new Option(address(mockToken), 50*10**mockToken.decimals(), 2*10**mockToken.decimals(), block.timestamp + 1 weeks);
        tokenId = 1;
        mockNft.mint(address(this), tokenId);
    }

    function testDeposit() public {
        mockNft.approve(address(option), tokenId);
        option.deposit(address(mockNft), tokenId);
        assertEq(mockNft.ownerOf(tokenId), address(option));
    }

    function testDoubleDeposit() public {
        mockNft.approve(address(option), tokenId);
        option.deposit(address(mockNft), tokenId);
        hevm.expectRevert(bytes("can only deposit once"));
        option.deposit(address(mockNft), tokenId);
    }

    function testOnlySellerDeposit() public {
        hevm.prank(address(0xdead));
        hevm.expectRevert(bytes("only seller"));
        option.deposit(address(mockNft), tokenId);
    }

    function testPurchaseCall() public {
        mockNft.approve(address(option), tokenId);
        option.deposit(address(mockNft), tokenId);

        mockToken.approve(address(option), option.premium());
        option.purchaseCall("");
        assertEq(option.buyer(), address(this));
    }

    function testPurchaseCallOnlyOnce() public {
        mockNft.approve(address(option), tokenId);
        option.deposit(address(mockNft), tokenId);

        mockToken.approve(address(option), option.premium());
        option.purchaseCall("");

        hevm.expectRevert(bytes("option has already been purchased"));
        option.purchaseCall("");
    }

    function testExercise() public {
        mockNft.approve(address(option), tokenId);
        option.deposit(address(mockNft), tokenId);

        hevm.startPrank(buyer);
        mockToken.approve(address(option), option.premium());
        option.purchaseCall("");
        hevm.warp(block.timestamp + 5 days);
        mockToken.approve(address(option), option.strike());
        option.exerciseOption("");
        assertEq(mockNft.ownerOf(tokenId), buyer);
    }
}
