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


def test_init_base_token(base_token):
    assert base_token.name() == 'BASE TOKEN'
    assert base_token.symbol() == 'BTN'
    assert base_token.defaultOperators() == accounts[2:4]
    assert base_token.totalSupply() == '1000 ether'
    assert base_token.balanceOf(accounts[0]) == '1000 ether'
    # assert base_token.erc1820Registry() == '0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24'

######################################
# Owned
######################################

def test_base_token_owned(base_token):
    assert base_token.owner({'from': accounts[0]}) == accounts[0]

def test_base_token_transferOwnership(base_token):
    with reverts():
        base_token.transferOwnership(ZERO_ADDRESS, {'from': accounts[0]})
    tx = base_token.transferOwnership(accounts[1], {'from': accounts[0]})
    assert 'OwnershipTransferred' in tx.events
    assert tx.events['OwnershipTransferred'] == {'previousOwner': accounts[0], 'newOwner': accounts[1]}
    with reverts():
        base_token.transferOwnership(accounts[1], {'from': accounts[0]})

######################################
# ERC20 Tests
######################################

# def test_erc20_compatibility(erc1820_registry, base_token):
#     assert erc1820_registry.getInterfaceImplementer(base_token, ERC20_TOKENS_INTERFACE_HASH,  {'from': accounts[0]}) == base_token
#     assert base_token.decimals() == 18


def test_erc20_transfer(base_token):
    tx = base_token.transfer(accounts[1], '2 ether', {'from': accounts[0]})

    assert base_token.balanceOf(accounts[0]) == '998 ether'
    assert base_token.balanceOf(accounts[1]) == '2 ether'

    assert 'Transfer' in tx.events
    assert tx.events['Transfer'] == {'from': accounts[0], 'to': accounts[1], 'amount': '2 ether'}

    assert 'Sent' in tx.events
    assert tx.events['Sent'] == {'from': accounts[0],
                                 'to': accounts[1],
                                 'amount': '2 ether',
                                 'operator': accounts[0],
                                 'data': '0x',
                                 'operatorData': '0x'}


def test_erc20_transfer_not_enough_funds(base_token):
    with reverts('ERC777: transfer amount exceeds balance'):
        base_token.transfer(accounts[1], '1001 ether', {'from': accounts[0]})


def test_erc20_approve(base_token):
    tx = base_token.approve(accounts[2], '5 ether', {'from': accounts[0]})

    assert base_token.allowance(accounts[0], accounts[2]) == '5 ether'

    assert 'Approval' in tx.events
    assert tx.events['Approval'] == {'owner': accounts[0], 'spender': accounts[2], 'amount': '5 ether'}


def test_erc20_transfer_from(base_token):
    base_token.approve(accounts[1], '10 ether', {'from': accounts[0]})

    tx = base_token.transferFrom(accounts[0], accounts[2], '5 ether', {'from': accounts[1]})

    assert base_token.balanceOf(accounts[0]) == '995 ether'
    assert base_token.balanceOf(accounts[2]) == '5 ether'

    assert 'Transfer' in tx.events
    assert tx.events['Transfer'] == {'from': accounts[0], 'to': accounts[2], 'amount': '5 ether'}


def test_erc20_transfer_from_not_enough_funds(base_token):
    base_token.approve(accounts[1], '1001 ether', {'from': accounts[0]})
    with reverts('ERC777: transfer amount exceeds balance'):
        base_token.transferFrom(accounts[0], accounts[2], '1001 ether', {'from': accounts[1]})


def test_disable_erc20( erc1820_registry, base_token):
    tx = base_token.disableERC20Transfers({'from': accounts[0]})

    assert 'ERC20Disabled' in tx.events
    # assert erc1820_registry.getInterfaceImplementer(base_token, ERC20_TOKENS_INTERFACE_HASH, {'from': accounts[0]}) == ZERO_ADDRESS

    with reverts('ERC777: transfer amount exceeds allowance'):
        base_token.transfer(accounts[1], 1,  {'from': accounts[0]})
        base_token.transferFrom(accounts[0], accounts[1], 1, {'from': accounts[0]})
        base_token.approve(accounts[1], 1,  {'from': accounts[0]})

# didnt work with code coverage
def test_disable_erc20_not_owner(base_token):
    with reverts():
        base_token.disableERC20Transfers({'from': accounts[1]})

def test_enable_erc20( base_token, erc1820_registry):
    base_token.disableERC20Transfers({'from': accounts[0]})
    tx = base_token.enableERC20Transfers({'from': accounts[0]})
    # assert erc1820_registry.getInterfaceImplementer(base_token, ERC20_TOKENS_INTERFACE_HASH, {'from': accounts[0]}) == base_token
    assert 'ERC20Enabled' in tx.events


# Successful - but didnt work with code coverage
def test_enable_erc20_not_owner(base_token):
    base_token.disableERC20Transfers({'from': accounts[0]})

    with reverts():
        base_token.enableERC20Transfers({'from': accounts[1]})


