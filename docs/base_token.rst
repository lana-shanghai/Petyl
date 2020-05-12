
===========
Base Tokens
===========

Base token type is the foundation of the Petyl protocol. It is essentially an ERC20 with some advanced features from the ERC777 standard and some bonus code to make them work with the Petyl contract. 

Functions
=========
Full list of functions can be found in the Referrence docs. 

Send vs Transfer 
================
This is a naming convertion from both ERC20 and ERC777 which is used to distinguish them. We have included both the Transfered and Sent events to comply with both standards. 

Transfer with data 
==================
Certain use cases need addional data to be transfered along with token operations. We have included the transferWithData() function to support additional functionality bothin the sending and receiving of tokens. 

Operators
=========
Token holders can assign an operator for repeated functionality. 
Any base token added to the Petyl contract will act as an operator for that token

ERC1820 Registry
================
This is a key part of the ERC777 standard and used as a hook for aditional functionality within the Petyl protocol