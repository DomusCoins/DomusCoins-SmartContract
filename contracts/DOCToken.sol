pragma solidity ^0.4.19;

import "./internal/FinalizableToken.sol";
import "./DOCTokenConfig.sol";

contract DOCToken is FinalizableToken, DOCTokenConfig {

    using SafeMath for uint256;
    event TokensReclaimed(uint256 _amount);
    uint256 dividendPersentage;

    function DOCToken() public
    FinalizableToken(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOKEN_TOTALSUPPLY, PUBLIC_RESERVED, PUBLIC_RESERVED_PERSENTAGE, BOARD_RESERVED, BOARD_RESERVED_PERSENTAGE)
    {

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