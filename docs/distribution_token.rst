.. _distribution_token:

===================
Distribution Tokens
===================
Distribution tokens are base tokens with additional functions to both keep track and distribute tokens to holders.
Due to the internal accounting required to keep track of who is owed what amount, dividend tokens must be minted seperately to base tokens. 

Functions
=========
Full list of functions can be found in the Reference docs. 



Deposit Dividends
=================
Accepts up to 5 different ERC20 tokens as well as ETH
Limited to a set number of ERC20 tokens in V1 due to gas constraints and security implications.
Only the owner can add new ERC20 tokens to be accepted and paid out. Non approved tokens are not lock and can be transfered by the contract owner. 

Withdraw Funds
==============
Anyone can pull out the amount of tokens they have earnt over the time of holding a dividend token. 
Transfers are precomputed with dividends owing paid out first before sending to another party.




