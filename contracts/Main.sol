// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Main is ERC721A, Ownable{
    using Strings for uint256;
 
    //Max quantity of mints
    uint256 public constant MAX_PUBLIC_MINT = 5;
    uint256 public constant MAX_WHITELIST_MINT = 3;
    uint256 public constant TOTAL_TEAM_MINT = 200;
    
    //Prices of mints in whitelists
    uint256 public constant OG_WHITELIST_SALE_PRICE = 0.05 ether;
    uint256 public constant WHITELIST_SALE_PRICE = 0.1 ether;

    //Hour of release - Public sale
    uint256 public constant TIMESTAMP_RELEASE = 1664380800;
    
    //URL of metadata
    string private baseURI;
    string private notRevealedUri;
    string public baseExtension = ".json";
    
    //Price and quantity (Setteable) of public sale
    uint256 public tokenPrice = 0.2 ether;
    uint256 public maxSupply = 1000;
    
    //Booleans to start phases
    bool public isRevealed;
    bool public publicSale;
    bool public OG_whiteListSale;
    bool public whiteListSale;
    bool public teamMinted;

    //Merkle tree of addresses in OG and normal whitelist
    bytes32 private OG_whitelistMerkleRoot;
    bytes32 private whitelistMerkleRoot;

    //Mapping of total mints by address
    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    constructor(
        string memory _name, 
        string memory _symbol, 
        string memory _initBaseURI, 
        string memory _initNotRevealedUri, 
        bytes32 _OG_whitelistMerkleRoot, 
        bytes32 _whitelistMerkleRoot
    ) ERC721A(_name, _symbol){
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        OG_whitelistMerkleRoot = _OG_whitelistMerkleRoot;
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "Not active yet.");
        require((totalSupply() + _quantity) <= maxSupply, "Beyond max supply");
        require((totalPublicMint[msg.sender] + _quantity) <= MAX_PUBLIC_MINT, "Already minted 5 times!");
        require(msg.value >= (tokenPrice * _quantity), "Price below");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function OGwhitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser{
        require(OG_whiteListSale, "Minting is on Pause");
        require((totalSupply() + _quantity) <= maxSupply, "Cannot mint beyond max supply");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= MAX_WHITELIST_MINT, "Cannot mint beyond the OG whitelist max mint!");
        require(msg.value >= (OG_WHITELIST_SALE_PRICE * _quantity), "Payment is below the price");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, OG_whitelistMerkleRoot, sender), "You are not whitelisted in the OG");

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser{
        require(whiteListSale, "Minting is on Pause");
        require((totalSupply() + _quantity) <= maxSupply, "Cannot mint beyond max supply");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= MAX_WHITELIST_MINT, "Cannot mint beyond whitelist max mint!");
        require(msg.value >= (WHITELIST_SALE_PRICE * _quantity), "Payment is below the price");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, sender), "You are not whitelisted");

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external onlyOwner{
        require(timestampRelease(15), "The mint schedule has not started yet.");
        require(!teamMinted, "Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, TOTAL_TEAM_MINT);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
       
        uint256 trueId = tokenId + 1;

        if(isRevealed == false) {
            return notRevealedUri;
        }
        
        string memory currentBaseURI = _baseURI();
                return
                bytes(currentBaseURI).length > 0 
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner() {
        baseURI = _newBaseURI;
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function getOG_merkleRoot() external view returns (bytes32){
        return OG_whitelistMerkleRoot;
    }

    function toggleOGwhiteListSale() external onlyOwner{
        OG_whiteListSale = !OG_whiteListSale;
    }

    function getMerkleRoot() external view returns (bytes32){
        return whitelistMerkleRoot;
    }

    function toggleWhiteListSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function getTimestamp() external view returns (uint256){
        return block.timestamp;
    }

    function timestampRelease(uint256 _minutes) public view returns (bool){
        uint256 time = TIMESTAMP_RELEASE - (_minutes * 60);
        if(block.timestamp >= time){
            return true;
        }
        return false;
    }

    function withdraw() external onlyOwner{
        //35% to utility/investors wallet
        //uint256 withdrawAmount_35 = address(this).balance * 35/100;
        //20% to artist (post utility)
        //uint256 withdrawAmount_20 = (address(this).balance - withdrawAmount_35) * 20/100;
        //5% to advisor (post utility)
        //uint256 withdrawAmount_5 = (address(this).balance - withdrawAmount_35) * 5/100;
        //payable(0xF70cE6c33687fCB68B823858766Ae515D4928945).transfer(withdrawAmount_35);
        //payable(0xC44146197386B2b23c11FFbb37D91a004f5bd829).transfer(withdrawAmount_20);
        //payable(0xBD584cE590B7dcdbB93b11e095d9E1D5880B44d9).transfer(withdrawAmount_5);
        //payable(msg.sender).transfer(address(this).balance);
    }
}