// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/**
 * @title PropertyToken
 * @dev Complete ERC-20 token for real estate fractionalization with marketplace
 */
contract PropertyToken is ERC20, Ownable, ReentrancyGuard {
   
    struct PropertyInfo {
        string title;
        string description;
        uint256 valuation;        // Total property value in wei
        uint256 pricePerToken;    // Price per token in wei
        string ipfsHash;          // IPFS hash for documents
        bool isVerified;          // KYC/legal verification
        uint256 createdAt;        // Creation timestamp
    }
   
    PropertyInfo public propertyInfo;
    address public propertyOwner;
    bool public tokensIssued;
   
    // Marketplace variables
    mapping(address => uint256) public tokensForSale;
    mapping(address => bool) public isKYCApproved;
    mapping(address => uint256) public salePrice;
    mapping(address => bool) public isListed;
   
    // Income distribution
    uint256 public totalIncomeDeposited;
    mapping(address => uint256) public lastClaimBlock;
    mapping(address => uint256) public claimedIncome;
   
    // Events
    event PropertyCreated(address indexed owner, string title, uint256 valuation, uint256 totalSupply, uint256 pricePerToken);
    event TokensMinted(address indexed to, uint256 amount, uint256 timestamp);
    event PropertyVerified(address indexed verifier, bool status, uint256 timestamp);
    event TokensPurchased(address indexed buyer, address indexed seller, uint256 amount, uint256 totalPrice);
    event TokensListed(address indexed seller, uint256 amount, uint256 pricePerToken);
    event IncomeDeposited(address indexed owner, uint256 amount, uint256 timestamp);
    event IncomeClaimed(address indexed investor, uint256 amount, uint256 timestamp);
    event KYCUpdated(address indexed user, bool status, uint256 timestamp);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _title,
        string memory _description,
        uint256 _valuation,
        uint256 _totalSupply,
        uint256 _pricePerToken,
        string memory _ipfsHash,
        address _propertyOwner
    ) ERC20(_name, _symbol) Ownable(_propertyOwner) {
        require(_propertyOwner != address(0), "Invalid property owner address");
        require(_valuation > 0, "Property valuation must be greater than 0");
        require(_totalSupply > 0, "Total supply must be greater than 0");
        require(_pricePerToken > 0, "Price per token must be greater than 0");
        require(bytes(_title).length > 0, "Property title cannot be empty");
       
        propertyInfo = PropertyInfo({
            title: _title,
            description: _description,
            valuation: _valuation,
            pricePerToken: _pricePerToken,
            ipfsHash: _ipfsHash,
            isVerified: false,
            createdAt: block.timestamp
        });
       
        propertyOwner = _propertyOwner;
        // tokensIssued = false;
        _mint(_propertyOwner, _totalSupply); // Mint the full supply immediately
        tokensIssued = true;
       
        // emit PropertyCreated(_propertyOwner, _title, _valuation, _totalSupply, _pricePerToken);
        emit PropertyCreated(_propertyOwner, _title, _valuation, _totalSupply, _pricePerToken);
    }
   
    // ========== DANIEL'S MODULE: Property Fractionalization & Token Issuance ==========
   
    function createProperty() external view returns (bool success) {
        require(bytes(propertyInfo.title).length > 0, "Property not initialized");
        return true;
    }
   
    function mintTokens() external onlyOwner nonReentrant {
        // require(!tokensIssued, "Tokens already minted");
        // require(propertyInfo.isVerified, "Property must be verified before minting");
       
        // uint256 totalTokens = propertyInfo.valuation / propertyInfo.pricePerToken;
        // uint256 totalTokensInWei = totalTokens * (10 ** decimals()); 
        // _mint(propertyOwner, totalTokensInWei); // We mint the corrected, large amount
        // tokensIssued = true;
       
        // emit TokensMinted(propertyOwner, totalTokensInWei, block.timestamp);
        
        require(tokensIssued, "Tokens have already been issued at creation.");
    }
   
    function verifyPropertyOwnership(bool _verified) external onlyOwner {
        propertyInfo.isVerified = _verified;
        emit PropertyVerified(msg.sender, _verified, block.timestamp);
    }
   
    // ========== WONG SHEN HUI'S MODULE: Market Listing & Distribution ==========
    /**
    * @dev Set KYC approval status for a user (only owner)
    * @param user Address to set KYC status for
    * @param status True for approved, false for not approved
    */
    function setKYC(address user, bool status) external onlyOwner {
        require(user != address(0), "Invalid user address");
        isKYCApproved[user] = status;
        emit KYCUpdated(user, status, block.timestamp);
    }

    /**
    * @dev Check if user is KYC approved (getter function)
    * @param user Address to check
    * @return bool KYC approval status
    */
    function getKYCStatus(address user) external view returns (bool) {
        return isKYCApproved[user];
    }

    /**
    * @dev Allow users to self-verify their KYC (for testing purposes)
    */
    function selfVerifyKYC() external {
        isKYCApproved[msg.sender] = true;
        emit KYCUpdated(msg.sender, true, block.timestamp);
    }

    function listTokensForSale(uint256 _amount, uint256 _pricePerToken) external {
        require(tokensIssued, "Tokens not yet issued");
        require(balanceOf(msg.sender) >= _amount, "Insufficient token balance");
        require(_amount > 0, "Amount must be greater than 0");
        require(_pricePerToken > 0, "Price must be greater than 0");

        tokensForSale[msg.sender] = _amount;
        salePrice[msg.sender] = _pricePerToken;
        isListed[msg.sender] = true;

        emit TokensListed(msg.sender, _amount, _pricePerToken);
    }
   
    function purchaseTokens(address _seller, uint256 _amount) external payable nonReentrant {
        if (_seller == propertyOwner) {
            _buyFromOwner(_amount);
        } else {
            _buyFromInvestor(_seller, _amount);
        }
    }

    function _buyFromOwner(uint256 _amount) internal {
        require(tokensIssued, "Tokens not yet issued");
        require(_amount > 0, "Amount must be greater than 0");
        require(balanceOf(propertyOwner) >= _amount, "Not enough tokens available");

        uint256 totalPrice = propertyInfo.pricePerToken * _amount;
        require(msg.value >= totalPrice, "Insufficient payment");

        _transfer(propertyOwner, msg.sender, _amount);
        payable(propertyOwner).transfer(totalPrice);

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        emit TokensPurchased(msg.sender, propertyOwner, _amount, totalPrice);
    }

    function _buyFromInvestor(address _seller, uint256 _amount) internal {
        require(tokensIssued, "Tokens not yet issued");
        require(isListed[_seller], "Seller not listing tokens");
        require(tokensForSale[_seller] >= _amount, "Not enough tokens listed");
        require(_amount > 0, "Amount must be greater than 0");

        uint256 totalPrice = salePrice[_seller] * _amount;
        require(msg.value >= totalPrice, "Insufficient payment");

        tokensForSale[_seller] -= _amount;
        if (tokensForSale[_seller] == 0) {
            isListed[_seller] = false;
        }

        _transfer(_seller, msg.sender, _amount);
        payable(_seller).transfer(totalPrice);

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        emit TokensPurchased(msg.sender, _seller, _amount, totalPrice);
    }
   
    function getAvailableTokens() external view returns (uint256) {
        return balanceOf(propertyOwner);
    }
   
    // ========== ALIA'S MODULE: Transactions, Trading & Records ==========
   
    function transferTokens(address _to, uint256 _amount) external returns (bool) {
        require(tokensIssued, "Tokens not yet issued");
        return transfer(_to, _amount);
    }
   
    function checkBalance(address _investor) external view returns (uint256) {
        return balanceOf(_investor);
    }
   
    // Transaction history is handled by events - frontend can query Transfer events
    function getTransactionHistory(address _investor) external view returns (string memory) {
        // In a real implementation, this would return structured data
        // For now, return a message directing to events
        return "Check Transfer, TokensPurchased events for transaction history";
    }
   
    // ========== INCOME DISTRIBUTION MODULE ==========
   
    function depositIncome() external payable onlyOwner {
        require(msg.value > 0, "Must send income to distribute");
        totalIncomeDeposited += msg.value;
        emit IncomeDeposited(msg.sender, msg.value, block.timestamp);
    }
   
    function calculateShare(address _investor) external view returns (uint256) {
        if (totalSupply() == 0) return 0;
        uint256 investorBalance = balanceOf(_investor);
        uint256 totalIncome = address(this).balance;
        return (totalIncome * investorBalance) / totalSupply();
    }
   
    function claimIncome() external nonReentrant {
        require(balanceOf(msg.sender) > 0, "No tokens owned");
       
        uint256 claimableAmount = this.calculateShare(msg.sender);
        uint256 alreadyClaimed = claimedIncome[msg.sender];
        uint256 newClaim = claimableAmount - alreadyClaimed;
       
        require(newClaim > 0, "No income to claim");
        require(address(this).balance >= newClaim, "Insufficient contract balance");
       
        claimedIncome[msg.sender] = claimableAmount;
        payable(msg.sender).transfer(newClaim);
       
        emit IncomeClaimed(msg.sender, newClaim, block.timestamp);
    }
   
    function getIncomeHistory(address _investor) external view returns (uint256 claimed, uint256 available) {
        claimed = claimedIncome[_investor];
        available = this.calculateShare(_investor) - claimed;
    }
   
    // ========== VIEW FUNCTIONS ==========
   
    function pricePerToken() external view returns (uint256) {
        return propertyInfo.pricePerToken;
    }
   
    function getPropertyInfo() external view returns (PropertyInfo memory) {
        return propertyInfo;
    }
   
    function getListedTokens(address _seller) external view returns (uint256 amount, uint256 price) {
        return (tokensForSale[_seller], salePrice[_seller]);
    }
   
    function areTokensIssued() external view returns (bool) {
        return tokensIssued;
    }
   
    function getPropertyOwner() external view returns (address) {
        return propertyOwner;
    }
   
    // Override transfer to ensure tokens are issued
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
    //    require(tokensIssued, "Tokens not yet issued");
        return super.transfer(to, amount);
    }
   
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
    //    require(tokensIssued, "Tokens not yet issued");
        return super.transferFrom(from, to, amount);
    }


    /**
    * @dev Distribute income to token holders (alias for depositIncome)
    */
    function distributeIncome() external payable onlyOwner {
        require(msg.value > 0, "Must send income to distribute");
        totalIncomeDeposited += msg.value;
        emit IncomeDeposited(msg.sender, msg.value, block.timestamp);
    }
}