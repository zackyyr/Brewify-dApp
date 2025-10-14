// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CoffeeBatchNFT is ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    enum Status {
        Unknown,
        Harvested,
        Processed,
        Packed,
        Shipped,
        Delivered
    }

    mapping(uint256 => Status) public tokenStatus;
    uint256 private _nextId = 1;

    event BatchMinted(address indexed to, uint256 indexed tokenId, string uri);
    event StatusUpdated(uint256 indexed tokenId, Status newStatus);

    constructor() ERC721("Brewify Coffee Batch", "BREW") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mintBatch(address to, string memory uri)
        external
        onlyRole(MINTER_ROLE)
    {
        uint256 tokenId = _nextId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        tokenStatus[tokenId] = Status.Harvested;
        emit BatchMinted(to, tokenId, uri);
    }

    function updateStatus(uint256 tokenId, Status newStatus)
        external
        onlyRole(MINTER_ROLE)
    {
        _requireOwned(tokenId); // <- pengganti _exists di OZ v5
        tokenStatus[tokenId] = newStatus;
        emit StatusUpdated(tokenId, newStatus);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
