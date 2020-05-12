from brownie import accounts, web3, Wei, reverts
from brownie.network.transaction import TransactionReceipt
from brownie.convert import to_address
import pytest
from brownie import Contract

ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'


# reset the chain after every test case
@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass


######################################
# Owned
######################################

def test_white_list_owned(white_list):
    assert white_list.owner({'from': accounts[0]}) == accounts[0]

def test_white_list_transferOwnership(white_list):
    with reverts():
        white_list.transferOwnership(ZERO_ADDRESS, {'from': accounts[0]})
    tx = white_list.transferOwnership(accounts[1], {'from': accounts[0]})
    assert 'OwnershipTransferred' in tx.events
    assert tx.events['OwnershipTransferred'] == {'previousOwner': accounts[0], 'newOwner': accounts[1]}
    with reverts():
        white_list.transferOwnership(accounts[1], {'from': accounts[0]})


######################################
# WhiteList Tests
######################################


def test_white_list_add_remove(white_list):
    employees = accounts[6]
    tx = white_list.addWhiteList([employees], {'from': accounts[0]})
    assert 'AccountListed' in tx.events
    assert white_list.isInWhiteList(accounts[0]) == True
    assert white_list.isInWhiteList(accounts[6]) == True
    assert white_list.isInWhiteList(accounts[7]) == False

    tx = white_list.removeWhiteList([employees], {'from': accounts[0]})
    assert 'AccountListed' in tx.events
    assert white_list.isInWhiteList(accounts[6]) == False

def test_white_list_add_none(white_list):
    with reverts():
        white_list.addWhiteList([], {'from': accounts[0]})
    with reverts():
        white_list.removeWhiteList([], {'from': accounts[0]})
    with reverts():
        white_list.addWhiteList([ZERO_ADDRESS], {'from': accounts[0]})
    tx = white_list.removeWhiteList([accounts[6]], {'from': accounts[0]})
    assert 'AccountListed' not in tx.events


# def test_white_list_add_not_controller(white_list):
