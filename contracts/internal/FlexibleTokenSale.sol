pragma solidity ^0.4.0;

import "./Owned.sol";
import "../oraclize/oraclizeAPI.sol";
import "./Math.sol";
import "./FinalizableToken.sol";

contract FlexibleTokenSale is  Owned, usingOraclize {

    using Math for uint256;

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
    FinalizableToken public token;
    uint256 public totalToken;

    //
    // Counters
    //
    uint256 public totalTokensSold;
    uint256 public totalEtherCollected;

    bool public updatePrice = true;



    //
    // Events
    //
    event Initialized();
    event TokenPriceUpdated(uint256 _newValue);
    event TokenPerEtherUpdated(bytes32 ID,uint256 _newValue);
    event TokenMinUpdated(uint256 _newValue);
    event TotalTokenUpdated(uint256 _newValue);
    event WalletAddressUpdated(address _newAddress);
    event SaleSuspended();
    event SaleResumed();
    event TokensPurchased(address _beneficiary, uint256 _cost, uint256 _tokens);
    event TokensReclaimed(uint256 _amount);


    function FlexibleTokenSale(address _walletAddress,uint _tokenPerEther) public
    Owned()
    {

        require(_walletAddress != address(0));
        require(_walletAddress != address(this));

        walletAddress = _walletAddress;

        suspended = false;
        tokenPrice = 100;
        tokenPerEther = _tokenPerEther;
        contributionMin     = 5 * 10**18;
        totalTokensSold     = 0;
        totalEtherCollected = 0;
    }

    // Initialize should be called by the owner as part of the deployment + setup phase.
    // It will associate the sale contract with the token contract and perform basic checks.
    function initialize(FinalizableToken _token) external onlyOwner returns(bool) {
        require(address(token) == address(0));
        require(address(_token) != address(0));
        require(address(_token) != address(this));
        require(address(_token) != address(walletAddress));
        require(isOwner(address(_token)) == false);
        tokenConversionFactor = 10**(uint256(18).sub(_token.decimals()).add(4).add(2));
        require(tokenConversionFactor > 0);
        token = _token;

        Initialized();

        return true;
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

    //set token price in between $1.0 to $99.9, pass 111 for $1.11, 100000 for $1000
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

    //count total token for sale added in ICO address
    function setTotalToken(uint256 _token) external  returns(bool) {
        require(msg.sender == address(token) && _token > 0);

        totalToken = totalToken.add(_token);

        TokenMinUpdated(_token);

        return true;
    }

    function getSoldTokenCount() view external  returns(uint256) {
        return totalTokensSold;
    }

    function getTotalTokenCount() view external  returns(uint256) {
        return totalToken;
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


        require(_beneficiary != address(0));
        require(_beneficiary != address(this));
        require(_beneficiary != address(token));

        // We don't want to allow the wallet collecting ETH to
        // directly be used to purchase tokens.
        require(msg.sender != address(walletAddress));

        // Check how many tokens are still available for sale.
        uint256 saleBalance = token.balanceOf(address(this));
        require(saleBalance > 0);


        return buyTokensInternal(_beneficiary);
    }

    function startStopUpdateTokenPerEther(bool _value) public onlyOwner returns(bool){
        updatePrice = _value;

        return true;
    }

    function updateTokenPerEther() public payable {
        require(msg.sender == oraclize_cbAddress() || msg.sender == owner);
        oraclize_query(7200,"URL","json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD");
    }

    function __callback(bytes32 myid, string result) public  {
        require(msg.sender == oraclize_cbAddress());
        tokenPerEther=stringToUint(result);
        TokenPerEtherUpdated(myid,tokenPerEther);
        if(updatePrice)
        updateTokenPerEther();
    }


    function buyTokensInternal(address _beneficiary) internal returns (uint256) {

        // Calculate how many tokens the contributor could purchase based on ETH received.

        uint256 tokens =msg.value.mul(tokenPerEther.mul(100).div(tokenPrice)).mul(10000).div(tokenConversionFactor);
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



    function getUserTokenBalance(address _beneficiary) internal view returns (uint256) {
        return token.balanceOf(_beneficiary);
    }


    // Allows the owner to take back the tokens that are assigned to the sale contract.
    function reclaimTokens() external onlyOwner returns (bool) {
        uint256 tokens = token.balanceOf(address(this));

        if (tokens == 0) {
            return false;
        }

        address tokenOwner = token.owner();
        require(tokenOwner != address(0));

        totalToken = totalToken.sub(tokens);

        require(token.transfer(tokenOwner, tokens));

        TokensReclaimed(tokens);

        return true;
    }

    //Below function will convert string to integer removing decimal
    function stringToUint(string s) pure internal returns (uint) {
        bytes memory b = bytes(s);
        uint i;
        uint result1 = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if(c == 46)
            {
                // Do nothing --this will skip the decimal
            }
            else if (c >= 48 && c <= 57) {
                result1 = result1 * 10 + (c - 48);
            }
        }
        return result1;
    }
}