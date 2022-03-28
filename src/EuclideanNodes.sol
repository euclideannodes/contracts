//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "charged-particles-universe/interfaces/IChargedParticles.sol";
import "charged-particles-universe/interfaces/IChargedState.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract EuclideanNodes is ERC721, Ownable {
    uint public maxTokenId = 512;

    uint private _unlockBlock = 1e11; //this value locks the carbon token until practically forever
    uint private _carbonTokenAmountPerMint = 5 ether; //arbitrary number
    address private _carbonTokenAddress;
    
    IChargedParticles private _CP;
    IChargedState private _CS;
    IERC20 private _carbonToken;
    
    mapping(uint256 => address) internal _tokenCreator;

    event MintEN( 
        uint256 _tokenId,
        address minter
    );
    
    constructor(address chargedParticlesAddress, address chargedStateAddress, address carbonTokenAddress) 
        payable ERC721("EuclideanNodes", "EN") 
    {
        _CP = IChargedParticles(chargedParticlesAddress);
        _CS = IChargedState(chargedStateAddress);

        _carbonToken = IERC20(carbonTokenAddress); 

        _carbonTokenAddress = carbonTokenAddress;

        _carbonToken.approve(address(_CP), _carbonTokenAmountPerMint * maxTokenId * 2);
    }
    
    function mint(uint _tokenId) external payable {
        require(carbonTokenLeft() >= _carbonTokenAmountPerMint, "Not enough carbon tokens left");
        require(msg.value >= 0.01 ether, "insufficient payment");
        require (0 <= _tokenId && _tokenId < maxTokenId, "Token: Invalid tokenId");
        
        _safeMint(msg.sender, _tokenId);

        _tokenCreator[_tokenId] = msg.sender;

        _CS.setReleaseTimelock(address(this), _tokenId, _unlockBlock);

        _CP.energizeParticle(
            address(this), 
            _tokenId, 
            "generic", 
            _carbonTokenAddress, 
            _carbonTokenAmountPerMint, 
            address(0x0)
        );

        emit MintEN(_tokenId, msg.sender);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawCarbonTokenAmount(uint amount) external onlyOwner {
        _carbonToken.transfer(msg.sender, amount);
    }

    function creatorOf(uint256 tokenId) external view returns (address) {
        return _tokenCreator[tokenId];
    }

    function carbonTokenLeft() public view returns (uint) {
        return _carbonToken.balanceOf(address(this));
    }
    
    function _baseURI() internal pure override returns (string memory) {
        //to be updated?
        return "ipfs://QmNrgEMcUygbKzZeZgYFosdd27VE9KnWbyUD73bKZJ3bGi/";
    }
}

