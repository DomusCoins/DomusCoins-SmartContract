pragma solidity ^0.4.19;

import "./internal/FinalizableToken.sol";
import "./DOCTokenConfig.sol";

contract DOCToken is FinalizableToken, DOCTokenConfig {

    using Math for uint256;
    event TokensReclaimed(uint256 _amount);
    uint256 dividendPersentage;

    function DOCToken() public
    FinalizableToken(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOKEN_TOTALSUPPLY, PUBLIC_RESERVED, PUBLIC_RESERVED_PERSENTAGE, BOARD_RESERVED, BOARD_RESERVED_PERSENTAGE)
    {

    }

    //get dividend tokens
    function claimDividendTokens(address _userAddress) public  onlyOwner returns (bool) {
        uint256 dividendBalance = balanceOf(address(this));
        require(dividendBalance > 0);
        uint256 tokens = balances[_userAddress];
        uint256 dividendToken = tokens.mul(dividendPersentage).div(tokenConversionFactor);
        require(transfer(_userAddress, dividendToken));
        return true;
    }

    //set dividend tokens persentage in between 1.00 % to 99.9 %, pass 111 for 1.11 %
    function setDividendPersentage(uint _dividendPersentage) public onlyOwner returns (bool) {
        require(_dividendPersentage >= 100 && _dividendPersentage <= 999);
        dividendPersentage=_dividendPersentage;
        return true;
    }


    // Allows the owner to reclaim tokens that have been sent to the token address itself.
    function reclaimTokens() public onlyOwner returns (bool) {

        address account = address(this);
        uint256 amount  = balanceOf(account);

        if (amount == 0) {
            return false;
        }

        balances[account] = balances[account].sub(amount);
        balances[owner] = balances[owner].add(amount);

        Transfer(account, owner, amount);

        TokensReclaimed(amount);

        return true;
    }
}