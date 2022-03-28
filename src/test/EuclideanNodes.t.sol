// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "forge-std/stdlib.sol";
import "ds-test/test.sol";
import "../EuclideanNodes.sol";
import "charged-particles-universe/interfaces/IChargedSettings.sol";
import "charged-particles-universe/interfaces/IChargedParticles.sol";

interface CheatCodes {
    //sets the next call's msg.sender to the given address
    function prank(address) external;
    //sets blocknumber to given number
    function roll(uint256) external;
}

contract EuclideanNodesTest is DSTest {
    using stdStorage for StdStorage;
    StdStorage stdstore;

    string private _walletManagerId = "generic";
    uint private _carbonTokenAmountPerMint = 5 ether;

    address private chargedSettingsKovanAddress = 0xf6d61222CA3b3416bd0F0347a9AB39cCe0ea76ED;
    address private chargedParticlesKovanAddress = 0x12780d2b6e1865FBEE45B7C6b5Fbe6F7c9e841a1;
    address private chargedStateKovanAddress = 0x11833579D30a5563034e6b26405f832960257099;
    address private carbonTokenKovanAddress = 0x61460874a7196d6a22D1eE4922473664b3E95270;

    address private myAddress = 0x11dc744F9b69b87a1eb19C3900e0fF85B6853990;

    IChargedSettings private _CSettings = IChargedSettings(chargedSettingsKovanAddress);
    IChargedParticles private _CParticles = IChargedParticles(chargedParticlesKovanAddress);
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    EuclideanNodes euclideanNodes;

    //this function is invoked before each test case is run
    function setUp() public {
        //deploy contract
        euclideanNodes = new EuclideanNodes{value: 1 ether}(
            chargedParticlesKovanAddress,
            chargedStateKovanAddress,
            carbonTokenKovanAddress
        );

        //only deployer of the charged-settings contract can set permissions
        //so setting next caller's address to myAddress is necessary.
        cheats.prank(myAddress);
        //setting permission for our nft's to be chargeable
        _CSettings.setPermsForCharge(address(euclideanNodes), true);
        cheats.prank(myAddress);
        //setting permission for our nft's to be timelockable
        _CSettings.setPermsForTimelockSelf(address(euclideanNodes), true);

        //giving contract 100 carbon token
        _writeTokenBalance(address(euclideanNodes), carbonTokenKovanAddress, 100 ether);
    }

    //tests if our contract has necessary whitelists
    function testWhitelist() public {
        (   ,
            bool energizeEnabled,
            ,
            ,
            ,
            ,
        ) = _CSettings.getAssetRequirements(address(euclideanNodes), carbonTokenKovanAddress);
        assertTrue(energizeEnabled);
        
        (   ,
            bool timelockOwn
        ) = _CSettings.getTimelockApprovals(address(euclideanNodes));
        assertTrue(timelockOwn);
    }

    //tests if contract has the correct amount of carbontokens
    function testContractBalance() public {
        uint balance = euclideanNodes.carbonTokenLeft();
        assertEq(balance, 100 ether);
    }

    function testMint() public {
        uint _tokenId = 5;
        cheats.prank(myAddress);
        euclideanNodes.mint{value: 0.01 ether}(_tokenId);
        assertEq(euclideanNodes.ownerOf(_tokenId), myAddress);
        //there should be 95 carbon token left after the minting
        assertEq(euclideanNodes.carbonTokenLeft(), 95 ether);
        //there should be 5 carbon token in the nft
        assertEq(_CParticles.baseParticleMass(address(euclideanNodes), _tokenId, _walletManagerId, carbonTokenKovanAddress), _carbonTokenAmountPerMint);
    }

    //testFail means test expects revert
    function testFailMint() public {
        uint _tokenId = 5;
        //should fail because we are not sending ether
        euclideanNodes.mint(_tokenId);
    }

    function testRelease() public {
        uint _tokenId = 5;
        cheats.prank(myAddress);
        euclideanNodes.mint{value: 0.01 ether}(_tokenId);
        cheats.prank(myAddress);
        cheats.roll(1e11 + 5);
        //should not fail block number is greater than unlockBlock
        _CParticles.releaseParticle(myAddress, address(euclideanNodes), _tokenId, _walletManagerId, carbonTokenKovanAddress);
        assertEq(_CParticles.baseParticleMass(address(euclideanNodes), _tokenId, _walletManagerId, carbonTokenKovanAddress), 0);
    }

    function testFailRelease() public {
        uint _tokenId = 5;
        cheats.prank(myAddress);
        euclideanNodes.mint{value: 0.01 ether}(_tokenId);
        cheats.prank(myAddress);
        //should fail because assets are timelocked
        _CParticles.releaseParticle(myAddress, address(euclideanNodes), _tokenId, _walletManagerId, carbonTokenKovanAddress);
    }

    function testWithdraw() public {
        uint balance = address(this).balance;
        assertEq(address(euclideanNodes).balance, 1 ether);
        euclideanNodes.withdraw();
        assertEq(address(euclideanNodes).balance, 0);
        assertEq(address(this).balance, balance + 1 ether);
    }
    
    function testFailWithdraw() public {
        cheats.prank(myAddress);
        euclideanNodes.withdraw();    
    }

    function testCarbonWithdraw() public {
        euclideanNodes.withdrawCarbonTokenAmount(euclideanNodes.carbonTokenLeft());
        assertEq(euclideanNodes.carbonTokenLeft(), 0);
        assertEq(IERC20(carbonTokenKovanAddress).balanceOf(address(this)), 100 ether);
    }

    function testFailCarbonWithdraw() public {
        cheats.prank(myAddress);
        euclideanNodes.withdrawCarbonTokenAmount(10 ether);
    }

    //It is possible to give any address any amount of any token with this function
    function _writeTokenBalance(address who, address token, uint256 amt) internal {
        stdstore
            .target(token)
            .sig(IERC20(token).balanceOf.selector)
            .with_key(who)
            .checked_write(amt);
    }

    receive() external payable {}
}
