
==========
Partitions
==========

The Petyl protocol is a framework for building hybrid tokens. One such token type is the Hybrid token. 

Hybrid tokens
=============
A hybrid token is a combination of distinct assets, like an ERC721, and fungible assets such as an ERC20.
One common example is for company shares, where they all relate to ownership of the company, but different classes of shares, say founder shares have diffrerent conditions than regular shares.

We can build hybrid tokens with a main contract, the Petyl contract, with one or many partitions. 
Partitions are seperate tokens which relate to the same underlying asset but distinct from the different partitions. 


Token types
===========

Both the base token type and the dividend tokens can be added as partitions within the main Petyl contract.


Partitions ID
=============

Each base token within the petyl protocol has a Partition ID when created.
This is based on a hash and unique to each token deployed.