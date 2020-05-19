.. _security_token:

===============
Security Tokens
===============

Security tokens are a broad class of equity tokens used to represent an asset as defined by a certain jurisdicion.
We don't claim to know a specific jurisdiction and its requirements, however a number of classes of security tokens can be build from components of the Petyl protocol.


Components
==========
Full list of functions can be found in the Reference docs. 

Partitions
==========
Different tranches or share classes can be represented by seperate tokens, mapped by partitions in a Petyl venture contract.

Documents
=========
The Petyl venture contract comes built in with Documents. Documents can be raw text, hashes, links to IPFS or external URIs.

Distribution of Proceeds
========================
We have a distribution token type as part of the Petyl protocol. Dividends can be paid to a distribution contract in ETH and/or up to 5 distinct ERC20 contracts as set by the contract owners.

Transfer Restrictions
=====================
These requirements can be met by attaching token rules to either a base token or dividend token.
Different rules can be applied to each partition directly, with different partitions, different juristictions or classes of holders. 

Time based functions within the token rule contracts also allow for token vesting or cooling off periods for certain transactions and conversions. 


