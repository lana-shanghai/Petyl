from brownie import accounts, web3, Wei, reverts
from brownie.network.transaction import TransactionReceipt
from brownie.convert import to_address
import pytest
from brownie import Contract
from settings import *


# reset the chain after every test case
@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass



def test_dutch_auction_currentDemand(dutch_auction):
    assert dutch_auction.currentDemand() == 0



def test_dutch_auction_commitEth(dutch_auction):
    token_buyer =  accounts[2]
    eth_to_transfer = 20 * TENPOW18
    tx = token_buyer.transfer(dutch_auction, eth_to_transfer)
    assert 'AddedCommitment' in tx.events

    
def test_dutch_auction_tokensClaimable(dutch_auction):
    assert dutch_auction.tokensClaimable(accounts[2]) == 0
    token_buyer =  accounts[2]
    eth_to_transfer = 20 * TENPOW18
    tx = token_buyer.transfer(dutch_auction, eth_to_transfer)
    assert 'AddedCommitment' in tx.events
    assert dutch_auction.tokensClaimable(accounts[2]) == "1000000 ether"


    
def test_dutch_auction_twoPurchases(dutch_auction):
    assert dutch_auction.tokensClaimable(accounts[2]) == 0
    token_buyer_a=  accounts[2]
    token_buyer_b =  accounts[3]

    eth_to_transfer = 20 * TENPOW18
    tx = token_buyer_a.transfer(dutch_auction, 20 * TENPOW18)
    assert 'AddedCommitment' in tx.events
    tx = token_buyer_b.transfer(dutch_auction, 80 * TENPOW18)
    assert 'AddedCommitment' in tx.events
    assert dutch_auction.tokensClaimable(token_buyer_a) == "200000 ether"
    assert dutch_auction.tokensClaimable(token_buyer_b) == "800000 ether"


def test_dutch_auction_tokenPrice(dutch_auction):
    assert dutch_auction.tokenPrice() == 0
    token_buyer=  accounts[2]
    eth_to_transfer = 20 * TENPOW18
    tx = token_buyer.transfer(dutch_auction, 20 * TENPOW18)
    assert 'AddedCommitment' in tx.events
    assert dutch_auction.tokenPrice() == eth_to_transfer * TENPOW18 / AUCTION_TOKENS
