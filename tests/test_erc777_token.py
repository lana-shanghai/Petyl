
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
# ERC777 Tests
######################################

def test_erc777_send(base_token):
    user_data = '20 ether minted to accounts[1]'.encode()

    base_token.send(accounts[1], '20 ether', user_data, {'from': accounts[0]})
    assert base_token.balanceOf(accounts[0]) == '980 ether'
    assert base_token.balanceOf(accounts[1]) == '20 ether'
    base_token.send(accounts[7], '10 ether', user_data, {'from': accounts[1]})
    assert base_token.balanceOf(accounts[1]) == '10 ether'
    assert base_token.balanceOf(accounts[7]) == '10 ether'


def test_erc777_granularity(base_token):
    assert base_token.granularity() == 1

def test_erc777_operator_send(base_token):
    user_data = '20 ether minted to accounts[1]'.encode()
    operator_data = '20 ether minted to accounts[1]'.encode()

    tx = base_token.operatorSend(accounts[0], accounts[1], '15 ether', user_data, operator_data,  {'from': accounts[2]})

    assert base_token.balanceOf(accounts[0]) == '985 ether'
    assert base_token.balanceOf(accounts[1]) == '15 ether'

    assert 'Sent' in tx.events
    assert tx.events['Transfer'] == {'from': accounts[0], 'to': accounts[1], 'amount': '15 ether'}

def test_erc777_operator_send_too_much(base_token):
    user_data = '2000 ether minted to accounts[1]'.encode()
    operator_data = '2000 ether minted to accounts[1]'.encode()

    with reverts('ERC777: caller is not an operator for holder'):
        tx = base_token.operatorSend(accounts[0], accounts[2], '2000 ether', user_data, operator_data,  {'from': accounts[1]})

def test_erc777_not_operator_send(base_token):
    user_data = '15 ether minted to accounts[1]'.encode()
    operator_data = '15 ether minted to accounts[1]'.encode()

    with reverts('ERC777: caller is not an operator for holder'):
        tx = base_token.operatorSend(accounts[0], accounts[2], '15 ether', user_data, operator_data,  {'from': accounts[1]})



######################################
# ERC777 Mint and Burning
######################################

def test_mint_operator(base_token):
    user_data = '500 ether minted to accounts[1]'.encode()
    operator_data = '500 ether minted to accounts[1]'.encode()
    tx = base_token.mint(accounts[1], '500 ether', user_data, operator_data, {'from': accounts[2]})

    # ERC20 Transfer event from 0x0
    assert 'Transfer' in tx.events
    assert tx.events['Transfer'] == {'from': ZERO_ADDRESS, 'to': accounts[1], 'amount': '500 ether'}

    # ERC777 Minted event
    assert 'Minted' in tx.events
    # AG Check minting event outputs
    assert tx.events['Minted'] == {'operator': accounts[2],
                                   'to': accounts[1],
                                   'amount': '500 ether',
                                   'userData': '0x' + user_data.hex(), 
                                   'operatorData': '0x' + operator_data.hex()}

# def test_mint_owner(base_token):

# def test_mint_controller(base_token):
#     user_data = '500 ether minted to accounts[1]'.encode()
#     operator_data = '500 ether minted to accounts[1]'.encode()

#     tx = base_token.mint(accounts[1], '500 ether', user_data, operator_data, {'from': accounts[5]})

#     # ERC20 Transfer event from 0x0
#     assert 'Transfer' in tx.events
#     assert tx.events['Transfer'] == {'from': ZERO_ADDRESS, 'to': accounts[1], 'amount': '500 ether'}

#     # ERC777 Minted event
#     assert 'Minted' in tx.events
#     assert tx.events['Minted'] == {'operator': accounts[5],
#                                    'to': accounts[1],
#                                    'amount': '500 ether',
#                                    'operatorData': '0x' + operator_data.hex()}


# def test_mint_not_controller(base_token):
#     user_data = '500 ether minted to accounts[1]'.encode()
#     operator_data = '500 ether minted to accounts[1]'.encode()
#     with reverts():
#         base_token.mint(accounts[1], '500 ether', user_data, operator_data,  {'from': accounts[1]})


def test_burn(base_token):
    data = 'Burn 990 ether from accounts[0]'.encode()
    tx = base_token.burn('990 ether', data, {'from': accounts[0]})

    assert base_token.balanceOf(accounts[0]) == '10 ether'
    assert base_token.totalSupply() == '10 ether'

    # ERC20 Transfer event to 0x0
    assert 'Transfer' in tx.events
    assert tx.events['Transfer'] == {'from': accounts[0], 'to': ZERO_ADDRESS, 'amount': '990 ether'}

    # ERC777 Burned event
    assert 'Burned' in tx.events
    assert tx.events['Burned'] == {'operator': accounts[0],
                                   'from': accounts[0],
                                   'amount': '990 ether',
                                   'data': '0x' + data.hex(),
                                   'operatorData': '0x'}


def test_burn_not_enough_funds(base_token):
    with reverts('ERC777: burn amount exceeds balance'):
        base_token.burn('1001 ether', 'Burn 990 ether from accounts[0]'.encode(), {'from': accounts[0]})


def test_burn_operator(base_token):
    data = 'Burn 990 ether from accounts[0]'.encode()
    operator_data = 'Burn 990 ether from accounts[0] via operator accounts[4]'.encode()
    tx = base_token.setBurnOperator(accounts[4], True, {'from': accounts[0]})

    tx = base_token.operatorBurn(accounts[0], '990 ether', data, operator_data, {'from': accounts[4]})

    assert base_token.balanceOf(accounts[0]) == '10 ether'
    assert base_token.totalSupply() == '10 ether'

    # ERC20 Transfer event to 0x0
    assert 'Transfer' in tx.events
    assert tx.events['Transfer'] == {'from': accounts[0], 'to': ZERO_ADDRESS, 'amount': '990 ether'}

    # ERC777 Burned event
    assert 'Burned' in tx.events
    assert tx.events['Burned'] == {'operator': accounts[4],
                                   'from': accounts[0],
                                   'amount': '990 ether',
                                   'data': '0x' + data.hex(),
                                   'operatorData': '0x' + operator_data.hex()}


def test_burn_operator_not_enough_funds(base_token):
    data = 'Burn 990 ether from accounts[0]'.encode()
    operator_data = 'Burn 990 ether from accounts[0] via operator accounts[4]'.encode()

    with reverts():
        base_token.operatorBurn(accounts[0], '1001 ether', data, operator_data, {'from': accounts[4]})


def test_default_operator_add(base_token):
    base_token.addDefaultOperators(accounts[1], {'from': accounts[0]})

    assert base_token.defaultOperators() == accounts[2:4] + [accounts[1]]


def test_default_operator_add_not_owner(base_token):
    with reverts():
        base_token.addDefaultOperators(accounts[1], {'from': accounts[1]})



###################################### 
# Permissioning
######################################

def test_transfer_ownership(base_token):
    assert base_token.isOwner({'from': accounts[0]}) == True
    assert base_token.isOwner({'from': accounts[5]}) == False
    assert base_token.owner({'from': accounts[0]}) == accounts[0]
    with reverts():
        base_token.transferOwnership(ZERO_ADDRESS, {'from': accounts[0]})
    base_token.transferOwnership(accounts[5], {'from': accounts[0]})
    with reverts():
        base_token.transferOwnership(accounts[4], {'from': accounts[0]})
    assert base_token.isOwner({'from': accounts[5]}) == True

def test_controllable(base_token):
    assert base_token.isControllable({'from': accounts[5]}) == True
    assert base_token.isControllable({'from': accounts[1]}) == False

def test_add_controller(base_token):
    base_token.addController(accounts[6], {'from': accounts[0]})
    assert base_token.isControllable({'from': accounts[6]}) == True

def test_remove_controller(base_token):
    base_token.addController(accounts[6], {'from': accounts[0]})
    assert base_token.isControllable({'from': accounts[6]}) == True
    base_token.removeController(accounts[6], {'from': accounts[0]})
    assert base_token.isControllable({'from': accounts[6]}) == False
