from brownie import accounts, web3, Wei, reverts, rpc
from brownie.network.transaction import TransactionReceipt
from brownie.convert import to_address
import pytest
from brownie import Contract
from settings import *


# AG: What if the token is not minable during an auction? Should commit tokens to auction

# reset the chain after every test case
@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass


def test_dutch_auction_erc20_totalTokensCommitted(dutch_auction_erc20):
    assert dutch_auction_erc20.totalTokensCommitted() == 0


def test_dutch_auction_erc20_commitTokens(dutch_auction_erc20, currency_token):
    token_buyer =  accounts[2]
    tokens_to_transfer = 20 * TENPOW18
    currency_token.approve(dutch_auction_erc20, tokens_to_transfer, {'from': token_buyer})
    tx = dutch_auction_erc20.commitTokens(tokens_to_transfer, {'from': token_buyer})
    assert 'AddedCommitment' in tx.events

    
def test_dutch_auction_erc20_tokensClaimable(dutch_auction_erc20, currency_token):
    assert dutch_auction_erc20.tokensClaimable(accounts[2]) == 0
    token_buyer =  accounts[2]
    tokens_to_transfer = 20 * TENPOW18
    currency_token.approve(dutch_auction_erc20, tokens_to_transfer, {'from': token_buyer})
    tx = dutch_auction_erc20.commitTokens(tokens_to_transfer, {'from': token_buyer})
    assert 'AddedCommitment' in tx.events

    rpc.sleep(AUCTION_TIME+100)
    rpc.mine()
    assert dutch_auction_erc20.tokensClaimable(accounts[2]) == "1000 ether"

    
def test_dutch_auction_erc20_twoPurchases(dutch_auction_erc20, currency_token):
    assert dutch_auction_erc20.tokensClaimable(accounts[2]) == 0
    token_buyer_a=  accounts[2]
    token_buyer_b =  accounts[3]

    tokens_a_transfer = 20 * TENPOW18
    tokens_b_transfer = 80 * TENPOW18

    currency_token.approve(dutch_auction_erc20, tokens_a_transfer, {'from': token_buyer_a})
    currency_token.approve(dutch_auction_erc20, tokens_b_transfer, {'from': token_buyer_b})
    tx = dutch_auction_erc20.commitTokens(tokens_a_transfer, {'from': token_buyer_a})
    assert 'AddedCommitment' in tx.events
    tx = dutch_auction_erc20.commitTokens(tokens_b_transfer, {'from': token_buyer_b})
    assert 'AddedCommitment' in tx.events
    assert round(dutch_auction_erc20.tokensClaimable(token_buyer_a) * AUCTION_TOKENS / TENPOW18**2) == 200
    assert round(dutch_auction_erc20.tokensClaimable(token_buyer_b) * AUCTION_TOKENS / TENPOW18**2) == 800


def test_dutch_auction_erc20_tokenPrice(dutch_auction_erc20, currency_token):
    assert dutch_auction_erc20.tokenPrice() == 0
    token_buyer=  accounts[2]
    tokens_to_transfer = 20 * TENPOW18
    currency_token.approve(dutch_auction_erc20, tokens_to_transfer, {'from': token_buyer})
    tx = dutch_auction_erc20.commitTokens(tokens_to_transfer, {'from': token_buyer})
    assert 'AddedCommitment' in tx.events

    assert dutch_auction_erc20.tokenPrice() == tokens_to_transfer * TENPOW18 / AUCTION_TOKENS

def test_dutch_auction_erc20_ended(dutch_auction_erc20):

    assert dutch_auction_erc20.auctionEnded({'from': accounts[0]}) == False
    rpc.sleep(AUCTION_TIME)
    rpc.mine()
    assert dutch_auction_erc20.auctionEnded({'from': accounts[0]}) == True


def test_dutch_auction_erc20_claim(dutch_auction_erc20, currency_token):
    token_buyer = accounts[2]
    tokens_to_transfer = 100 * TENPOW18

    # dutch_auction_erc20.withdrawTokens({'from': accounts[0]})
    
    currency_token.approve(dutch_auction_erc20, tokens_to_transfer, {'from': token_buyer})
    tx = dutch_auction_erc20.commitTokens(tokens_to_transfer, {'from': token_buyer})
    assert 'AddedCommitment' in tx.events

    with reverts():
        dutch_auction_erc20.finaliseAuction({'from': accounts[0]})
    
    rpc.sleep(AUCTION_TIME+100)
    rpc.mine()
    dutch_auction_erc20.withdrawTokens({'from': token_buyer})
    dutch_auction_erc20.withdrawTokens({'from': accounts[0]})
    assert dutch_auction_erc20.auctionSuccessful({'from': accounts[0]}) == True

    dutch_auction_erc20.finaliseAuction({'from': accounts[0]})


def test_dutch_auction_erc20_claim_not_enough(dutch_auction_erc20, currency_token):
    token_buyer = accounts[2]
    tokens_to_transfer = 0.01 * TENPOW18

    currency_token.approve(dutch_auction_erc20, tokens_to_transfer, {'from': token_buyer})
    tx = dutch_auction_erc20.commitTokens(tokens_to_transfer, {'from': token_buyer})
    assert 'AddedCommitment' in tx.events

    rpc.sleep(AUCTION_TIME+100)
    rpc.mine()
    dutch_auction_erc20.withdrawTokens({'from': token_buyer})



def test_dutch_auction_erc20_auctionPrice(dutch_auction_erc20, currency_token):
    rpc.sleep(100)
    rpc.mine()
    assert dutch_auction_erc20.auctionPrice() <= AUCTION_START_PRICE
    assert dutch_auction_erc20.auctionPrice() > AUCTION_RESERVE

    rpc.sleep(AUCTION_TIME)
    rpc.mine()
    assert dutch_auction_erc20.auctionPrice() == AUCTION_RESERVE

