pragma solidity ^0.4.19;

import "./Owned.sol";
import "./SafeMath.sol";

contract TokenTransfer {
    // minimal subset of ERC20
    function transfer(address _to, uint256 _value) public returns (bool success);
    function decimals() public view returns (uint8 tokenDecimals);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract FlexibleTokenSale is  Owned {

    using SafeMath for uint256;

    //
    // Lifecycle
    //
    bool public suspended;

    //
    // Pricing
    //
    uint256 public tokenPrice;
    uint256 public tokenPerEther;
    uint256 public contributionMin;
    uint256 public tokenConversionFactor;

    //
    // Wallets
    //
    address public walletAddress;

    //
    // Token
    //
    TokenTransfer token;


    //
    // Counters
    //
    uint256 public totalTokensSold;
    uint256 public totalEtherCollected;

    //
    // Price Update Address
    //
    address public priceUpdateAddress;

    //
    // Events
    //
    event Initialized();
    event TokenPriceUpdated(uint256 _newValue);
    event TokenPerEtherUpdated(uint256 _newValue);
    event TokenMinUpdated(uint256 _newValue);
    event WalletAddressUpdated(address indexed _newAddress);
    event SaleSuspended();
    event SaleResumed();
    event TokensPurchased(address indexed _beneficiary, uint256 _cost, uint256 _tokens);
    event TokensReclaimed(uint256 _amount);
    event PriceAddressUpdated(address indexed _newAddress);

    function FlexibleTokenSale(address _tokenAddress,address _walletAddress,uint _tokenPerEther,address _priceUpdateAddress) public
    Owned()
    {

        require(_walletAddress != address(0));
        require(_walletAddress != address(this));
        require(address(token) == address(0));
        require(address(_tokenAddress) != address(0));
        require(address(_tokenAddress) != address(this));
        require(address(_tokenAddress) != address(walletAddress));

        walletAddress = _walletAddress;
        priceUpdateAddress = _priceUpdateAddress;
        token = TokenTransfer(_tokenAddress);
        suspended = false;
        tokenPrice = 100;
        tokenPerEther = _tokenPerEther;
        contributionMin     = 5 * 10**18;//minimum 5 DOC token
        totalTokensSold     = 0;
        totalEtherCollected = 0;
        // This factor is used when converting cost <-> tokens.
       // 18 is because of the ETH -> Wei conversion.
      // 2 because toekn price  and etherPerToken Price are expressed as 100 for $1.00  and 100000 for $1000.00 (with 2 decimals).
       tokenConversionFactor = 10**(uint256(18).sub(token.decimals()).add(2));
        assert(tokenConversionFactor > 0);
    }


    //
    // Owner Configuation
    //

    // Allows the owner to change the wallet address which is used for collecting
    // ether received during the token sale.
    function setWalletAddress(address _walletAddress) external onlyOwner returns(bool) {
        require(_walletAddress != address(0));
        require(_walletAddress != address(this));
        require(_walletAddress != address(token));
        require(isOwner(_walletAddress) == false);

        walletAddress = _walletAddress;

        WalletAddressUpdated(_walletAddress);

        return true;
    }

    //set token price in between $1 to $1000, pass 111 for $1.11, 100000 for $1000
    function setTokenPrice(uint _tokenPrice) external onlyOwner returns (bool) {
        require(_tokenPrice >= 100 && _tokenPrice <= 100000);

        tokenPrice=_tokenPrice;

        TokenPriceUpdated(_tokenPrice);
        return true;
    }

    function setMinToken(uint256 _minToken) external onlyOwner returns(bool) {
        require(_minToken > 0);

        contributionMin = _minToken;

        TokenMinUpdated(_minToken);

        return true;
    }

    // Allows the owner to suspend the sale until it is manually resumed at a later time.
    function suspend() external onlyOwner returns(bool) {
        if (suspended == true) {
            return false;
        }

        suspended = true;

        SaleSuspended();

        return true;
    }

    // Allows the owner to resume the sale.
    function resume() external onlyOwner returns(bool) {
        if (suspended == false) {
            return false;
        }

        suspended = false;

        SaleResumed();

        return true;
    }


    //
    // Contributions
    //

    // Default payable function which can be used to purchase tokens.
    function () payable public {
        buyTokens(msg.sender);
    }


    // Allows the caller to purchase tokens for a specific beneficiary (proxy purchase).
    function buyTokens(address _beneficiary) public payable returns (uint256) {
        require(!suspended);

        require(address(token) !=  address(0));
        require(_beneficiary != address(0));
        require(_beneficiary != address(this));
        require(_beneficiary != address(token));


        // We don't want to allow the wallet collecting ETH to
        // directly be used to purchase tokens.
        require(msg.sender != address(walletAddress));

        // Check how many tokens are still available for sale.
        uint256 saleBalance = token.balanceOf(address(this));
        assert(saleBalance > 0);


        return buyTokensInternal(_beneficiary);
    }

    function updateTokenPerEther(uint _etherPrice) public returns(bool){
        require(_etherPrice > 0);
        require(msg.sender == priceUpdateAddress || msg.sender == owner);
        tokenPerEther=_etherPrice;
        TokenPerEtherUpdated(_etherPrice);
        return true;
    }

    function updatePriceAddress(address _newAddress) public onlyOwner returns(bool){
        require(_newAddress != address(0));
        priceUpdateAddress=_newAddress;
        PriceAddressUpdated(_newAddress);
        return true;
    }


    function buyTokensInternal(address _beneficiary) internal returns (uint256) {

        // Calculate how many tokens the contributor could purchase based on ETH received.
        uint256 tokens =msg.value.mul(tokenPerEther.mul(100).div(tokenPrice)).div(tokenConversionFactor);
        require(tokens >= contributionMin);

        // This is the actual amount of ETH that can be sent to the wallet.
        uint256 contribution =msg.value;
        walletAddress.transfer(contribution);
        totalEtherCollected = totalEtherCollected.add(contribution);

        // Update our stats counters.
        totalTokensSold = totalTokensSold.add(tokens);

        // Transfer tokens to the beneficiary.
        require(token.transfer(_beneficiary, tokens));

        TokensPurchased(_beneficiary, msg.value, tokens);

        return tokens;
    }


    // Allows the owner to take back the tokens that are assigned to the sale contract.
    function reclaimTokens() external onlyOwner returns (bool) {

        uint256 tokens = token.balanceOf(address(this));

        if (tokens == 0) {
            return false;
        }

        require(token.transfer(owner, tokens));

        TokensReclaimed(tokens);

        return true;
    }
}
