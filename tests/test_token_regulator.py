from brownie import accounts, web3, Wei, reverts
from brownie.network.transaction import TransactionReceipt
from brownie.convert import to_address
import pytest
from brownie import Contract

ERC777_INTERFACE_HASH = '0xac7fbab5f54a3ca8194167523c6753bfeb96a445279294b6125b68cce2177054'
ERC20_TOKENS_INTERFACE_HASH = '0xaea199e31a596269b42cdafd93407f14436db6e4cad65417994c2eb37381e05a'
ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'
ERC1820_ACCEPT_MAGIC = '0xa2ef4600d742022d532d4747cb3547474667d6f13804902513b2ec01c848f4b4'

# reset the chain after every test case
@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass


######################################
# Owned
######################################

def test_regulator_owned(token_regulator):
    assert token_regulator.owner({'from': accounts[0]}) == accounts[0]

def test_regulator_transferOwnership(token_regulator):
    with reverts():
        token_regulator.transferOwnership(ZERO_ADDRESS, {'from': accounts[0]})
    tx = token_regulator.transferOwnership(accounts[1], {'from': accounts[0]})
    assert 'OwnershipTransferred' in tx.events
    assert tx.events['OwnershipTransferred'] == {'previousOwner': accounts[0], 'newOwner': accounts[1]}
    with reverts():
        token_regulator.transferOwnership(accounts[1], {'from': accounts[0]})


######################################
# ERC 1820 
######################################

def test_can_implement_interface(base_token):
    assert base_token.canImplementInterfaceForAddress(ERC20_TOKENS_INTERFACE_HASH,base_token, {'from': accounts[0]}) == ERC1820_ACCEPT_MAGIC
    assert base_token.canImplementInterfaceForAddress(ERC777_INTERFACE_HASH,base_token, {'from': accounts[0]}) == ERC1820_ACCEPT_MAGIC
    assert base_token.canImplementInterfaceForAddress(ERC777_INTERFACE_HASH,ZERO_ADDRESS, {'from': accounts[0]}) != ERC1820_ACCEPT_MAGIC



###################################### 
# Regulator
######################################



def test_regulated_token_send(regulated_token):
    user_data = '20 ether minted to accounts[1]'.encode()
    regulated_token.send(accounts[1], '20 ether', user_data, {'from': accounts[0]})
    assert regulated_token.balanceOf(accounts[0]) == '480 ether'
    assert regulated_token.balanceOf(accounts[1]) == '20 ether'


def test_regulator_canSend(token_regulator):
    _partition = ''
    _from = accounts[0]
    _to = accounts[3]
    _value = 10

    assert token_regulator.canSend(_partition, _from, _to, _value, "", "", {'from': accounts[0]})

def test_regulator_canReceive(token_regulator):   
    _partition = ''
    _from = accounts[0]
    _to = accounts[3]
    _value = 10
    assert token_regulator.canReceive(_partition, _from, _to, _value, "", "", {'from': accounts[0]})

def test_regulator_canTransfer(token_regulator):   
    _partition = ''
    _from = accounts[0]
    _to = accounts[3]
    _value = 10
    assert token_regulator.canTransfer(_partition, _from, _to, _value, "", "", {'from': accounts[0]})


# def test_regulator_acceptTokensToTransfer(token_regulator):
# def test_regulator_canImplementInterfaceForAddress(token_regulator):
# def test_regulator_canTransfer(token_regulator):
# def test_regulator_rejectTokensToTransfer(token_regulator):
# def test_regulator_tokensReceived(token_regulator):
# def test_regulator_tokensToSend(token_regulator):
# def test_regulator_tokensToTransfer(token_regulator):






