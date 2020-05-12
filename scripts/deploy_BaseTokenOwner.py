from brownie import accounts, web3, Wei, Contract
from brownie.network.transaction import TransactionReceipt


# PetylBaseToken contract deployment

def main():
    tokenAddress = 0x01926b87815b3252a0178dde809e52a2b1444cf8

    newOwner = 0x181188a7ED60ceCC1f88181E9C7bA2e6e1f5e4E6
    base_token = PetylBaseToken.at(tokenAddress, {'from': accounts[0]})
    base_token.initBaseToken(newOwner, {'from': accounts[0]})

    # base_token.addController(controller, {'from': accounts[0]})

    return base_token
