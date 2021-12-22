// SPDX-License-Identifier: MIT

/*
 __       __                                ________  __  __  __                  __    __  ________  ________ 
|  \     /  \                              |        \|  \|  \|  \                |  \  |  \|        \|        \
| $$\   /  $$  ______    ______   _______   \$$$$$$$$ \$$| $$| $$  ______        | $$\ | $$| $$$$$$$$ \$$$$$$$$
| $$$\ /  $$$ /      \  /      \ |       \     /  $$ |  \| $$| $$ |      \       | $$$\| $$| $$__       | $$   
| $$$$\  $$$$|  $$$$$$\|  $$$$$$\| $$$$$$$\   /  $$  | $$| $$| $$  \$$$$$$\      | $$$$\ $$| $$  \      | $$   
| $$\$$ $$ $$| $$  | $$| $$  | $$| $$  | $$  /  $$   | $$| $$| $$ /      $$      | $$\$$ $$| $$$$$      | $$   
| $$ \$$$| $$| $$__/ $$| $$__/ $$| $$  | $$ /  $$___ | $$| $$| $$|  $$$$$$$      | $$ \$$$$| $$         | $$   
| $$  \$ | $$ \$$    $$ \$$    $$| $$  | $$|  $$    \| $$| $$| $$ \$$    $$      | $$  \$$$| $$         | $$   
 \$$      \$$  \$$$$$$   \$$$$$$  \$$   \$$ \$$$$$$$$ \$$ \$$ \$$  \$$$$$$$       \$$   \$$ \$$          \$$  

*/

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonZillas is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  uint256 public cost = 0.03 ether;
  uint256 public maxSupply = 10000; // MooNZillas Supply
  uint256 public maxMintAmount = 10; // Max Mint at same time
  uint256 public nftPerAddressLimit = 10; // Max NFT per address
  uint256 public reserved = 200; // Max NFT available to promote project + devteam
  uint256 public publicSale = 1640707200; // December 28th 12PM EST
  bool public paused = false;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  /**
  * Get baseURI
  */
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /**
  * Mint public function
  */
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "Mint is paused");
    require(_mintAmount > 0, "Minimum mint required");
    require(_mintAmount <= maxMintAmount, "Maximum mint exceeded");
    uint256 supply = totalSupply();
    uint256 ownerTokenCount = balanceOf(msg.sender) + _mintAmount; // Quantity of owner if mint suceed
    require(supply + _mintAmount <= maxSupply - reserved); // Prevent minting +10.000
    require(ownerTokenCount <= nftPerAddressLimit, "Sale exceed maximum MoonZillas per address");
    require(block.timestamp >= publicSale, "Sale must be active to mint");
    require(msg.value >= cost * _mintAmount, "Minimum mint price 0.03ETH");
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  /**
  * Mint by owner for devteam and promotional purposes
  */
  function mintReserved(address _to, uint256 _numberOfTokens) external onlyOwner {
      require(_to != address(0), "Invalid address to reserve.");
      uint256 supply = totalSupply();
      require(supply + _numberOfTokens <= maxSupply - reserved); // Prevent minting +10.000
      uint256 ownerTokenCount = balanceOf(_to) + _numberOfTokens; // Quantity of owner if mint suceed
      require(ownerTokenCount <= nftPerAddressLimit, "Sale exceed maximum MoonZillas per address");
      require(reserved >= _numberOfTokens, "Sale exceed maximum MoonZillas per promotional purposes");
      for (uint256 i = 1; i <= _numberOfTokens; i++) {
          _safeMint(_to, supply + i);
          reserved = reserved - 1;
      }
  }
  
  /**
  * Check MoonZillas on wallet
  */
  function checkWallet(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  /**
  * Get tokenURI
  */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: token does not exist"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, "/", tokenId.toString(), ".json"))
        : "";
  }

  /**
  * Set NFT limit per address
  */
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner() {
    nftPerAddressLimit = _limit;
  }
  
  /**
  * Set NFT Cost
  */
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  /**
  * Set max mint amount
  */
  function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner() {
    maxMintAmount = _newMaxMintAmount;
  }

  /**
  * Set public sale date
  */
  function setPublicSale(uint _newPublicSale) public onlyOwner() {
    publicSale = _newPublicSale;
  }
  
  /**
  * Set base URI
  */
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  /**
  * pause minting
  */
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  /**
  * Whitdraw balance
  */
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}