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


######################################
# Owned
######################################

def test_rules_owned(token_rules):
    assert token_rules.owner({'from': accounts[0]}) == accounts[0]

def test_rules_transferOwnership(token_rules):
    with reverts():
        token_rules.transferOwnership(ZERO_ADDRESS, {'from': accounts[0]})
    tx = token_rules.transferOwnership(accounts[1], {'from': accounts[0]})
    assert 'OwnershipTransferred' in tx.events
    assert tx.events['OwnershipTransferred'] == {'previousOwner': accounts[0], 'newOwner': accounts[1]}
    with reverts():
        token_rules.transferOwnership(accounts[1], {'from': accounts[0]})


######################################
# ERC 1820 
######################################

# def test_can_implement_interface(base_token):
#     assert base_token.canImplementInterfaceForAddress(ERC20_TOKENS_INTERFACE_HASH,base_token, {'from': accounts[0]}) == ERC1820_ACCEPT_MAGIC
#     assert base_token.canImplementInterfaceForAddress(ERC777_INTERFACE_HASH,base_token, {'from': accounts[0]}) == ERC1820_ACCEPT_MAGIC
#     assert base_token.canImplementInterfaceForAddress(ERC777_INTERFACE_HASH,ZERO_ADDRESS, {'from': accounts[0]}) != ERC1820_ACCEPT_MAGIC



###################################### 
# TokenRules
######################################



def test_regulated_token_send(regulated_token):
    user_data = '20 ether minted to accounts[1]'.encode()
    regulated_token.send(accounts[1], '20 ether', user_data, {'from': accounts[0]})
    assert regulated_token.balanceOf(accounts[0]) == '480 ether'
    assert regulated_token.balanceOf(accounts[1]) == '20 ether'


def test_rules_canSend(token_rules):
    _partition = ''
    _from = accounts[0]
    _to = accounts[3]
    _value = 10

    assert token_rules.canSend(_partition, _from, _to, _value, "", "", {'from': accounts[0]})

def test_rules_canReceive(token_rules):   
    _partition = ''
    _from = accounts[0]
    _to = accounts[3]
    _value = 10
    assert token_rules.canReceive(_partition, _from, _to, _value, "", "", {'from': accounts[0]})

def test_rules_canTransfer(token_rules):   
    _partition = ''
    _from = accounts[0]
    _to = accounts[3]
    _value = 10
    assert token_rules.canTransfer(_partition, _from, _to, _value, "", "", {'from': accounts[0]})


# def test_rules_acceptTokensToTransfer(token_rules):
# def test_rules_canImplementInterfaceForAddress(token_rules):
# def test_rules_canTransfer(token_rules):
# def test_rules_rejectTokensToTransfer(token_rules):
# def test_rules_tokensReceived(token_rules):
# def test_rules_tokensToSend(token_rules):
# def test_rules_tokensToTransfer(token_rules):






