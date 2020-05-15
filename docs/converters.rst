.. _converters:

==========
Converters
==========

Converters can be connected to the main petyl contract. 
Depending on the tokens, the converter is able to mint and burn from one or more token contracts. 
This allows for both the creation and conversion of tokens. 

Use Cases
=========

- Founder tokens that vest over time.
- Migrating exisiting ERC20 tokens and converting them into Petyl tokens.
- Converting base tokens into dividend tokens


Adding Converters
=================

Main contract owner can assign new converters for any of its underlying tokens.
Only the Main Contract summoner is only able to add token converters. This is to ensure the security of the system. 
Testing is available for basic checks on token converters to ensure a 1 to 1 converting of tokens is kept true. 


Converting Tokens
=================


