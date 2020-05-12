from brownie import accounts, web3, Wei, reverts
from brownie.network.transaction import TransactionReceipt
from brownie.convert import to_address
import pytest
from brownie import Contract


# reset the chain after every test case
@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass

###################################### 
# ERC1400 
######################################

ERC777_INTERFACE_HASH = '0xac7fbab5f54a3ca8194167523c6753bfeb96a445279294b6125b68cce2177054'
ERC1820_ACCEPT_MAGIC = '0xa2ef4600d742022d532d4747cb3547474667d6f13804902513b2ec01c848f4b4'
ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'
ERC20_TOKENS_INTERFACE_HASH = '0xaea199e31a596269b42cdafd93407f14436db6e4cad65417994c2eb37381e05a'


def test_init_erc1400_token(erc1400_token):
    default_partition = erc1400_token.getDefaultPartition()
    assert erc1400_token.name() == 'BASE TOKEN'
    assert erc1400_token.symbol() == 'BTN'
    assert erc1400_token.decimals() == 18

    assert erc1400_token.defaultOperatorsByPartition(default_partition) == accounts[2:4]
    assert erc1400_token.totalSupply() == '1000 ether'
    assert erc1400_token.balanceOfByPartition(default_partition, accounts[0]) == '1000 ether'
    assert erc1400_token.balanceOf(accounts[0]) == '1000 ether'


######################################
# ERC1400 - ERC20 Tests
######################################

def test_erc20_compatibility(erc1400_token, erc1820_registry, base_token):
    # AG: check assignment 
    # assert erc1820_registry.getInterfaceImplementer(erc1400_token, ERC20_TOKENS_INTERFACE_HASH,  {'from': accounts[0]}) == base_token
    assert base_token.decimals() == 18

def test_erc1400_transfer(erc1400_token):
    tx = erc1400_token.transfer(accounts[1], '2 ether', {'from': accounts[0]})

    assert erc1400_token.balanceOf(accounts[0]) == '998 ether'
    assert erc1400_token.balanceOf(accounts[1]) == '2 ether'

    assert 'Transfer' in tx.events
    assert tx.events['Transfer'] == {'from': accounts[0], 'to': accounts[1], 'amount': '2 ether'}

    assert 'Sent' in tx.events
    assert tx.events['Sent'] == {'from': accounts[0],
                                 'to': accounts[1],
                                 'amount': '2 ether',
                                 'operator': erc1400_token,
                                 'data': '0x',
                                 'operatorData': '0x'}


def test_erc1400_transfer_not_enough_funds(erc1400_token):
    with reverts('ERC777: transfer amount exceeds balance'):
        erc1400_token.transfer(accounts[1], '1001 ether', {'from': accounts[0]})

# Breaks coverage
def test_erc1400_balanceOfByPartition(erc1400_token, regulated_token):
    regulated_partition = erc1400_token.getPartition(regulated_token, {'from': accounts[0]})
    assert erc1400_token.balanceOfByPartition(regulated_partition, accounts[0], {'from': accounts[0]}) == '500 ether'

def test_erc1400_setDefaultPartition(erc1400_token, regulated_token):
    regulated_partition = erc1400_token.getPartition(regulated_token, {'from': accounts[0]})
    erc1400_token.setDefaultPartition(regulated_partition, {'from': accounts[0]})
    default_partition = erc1400_token.getDefaultPartition( {'from': accounts[0]})
    assert default_partition == regulated_partition

## Requires delegate call for erc20 approve functions 
def test_erc1400_allowance(erc1400_token):
    assert erc1400_token.allowance(accounts[0], accounts[2], {'from': accounts[0]}) == '0 ether'

## Requires delegate call for erc20 approve functions 

def test_erc1400_approve(erc1400_token):
    tx = erc1400_token.approve(accounts[2], '5 ether', {'from': accounts[0]})
    assert erc1400_token.allowance(accounts[0], accounts[2], {'from': accounts[0]}) == '5 ether'
    assert 'Approval' in tx.events
    assert tx.events['Approval'] == {'owner': accounts[0], 'spender': accounts[2], 'amount': '5 ether'}


def test_erc1400_transfer_from(erc1400_token):
    erc1400_token.approve(accounts[2], '10 ether', {'from': accounts[0]})
    tx = erc1400_token.transferFrom(accounts[0], accounts[1], '5 ether', {'from': accounts[2]})
    assert erc1400_token.balanceOf(accounts[0]) == '995 ether'
    assert erc1400_token.balanceOf(accounts[1]) == '5 ether'
    assert 'Transfer' in tx.events
    assert tx.events['Transfer'] == {'from': accounts[0], 'to': accounts[1], 'amount': '5 ether'}

def test_erc1400_transfer_from_not_enough_funds(erc1400_token):
    erc1400_token.approve(accounts[1], '1001 ether', {'from': accounts[0]})
    with reverts('ERC777: transfer amount exceeds balance'):
        erc1400_token.transferFrom(accounts[0], accounts[2], '1001 ether', {'from': accounts[1]})


######################################
# ERC1400 - Partitions
######################################

def test_erc1400_partitionsOf(erc1400_token):
    tx = erc1400_token.partitionsOf(accounts[0], {'from': accounts[0]} )
    # AG Add checks

def test_erc1400_getPartitions(erc1400_token):
    tx = erc1400_token.getPartitions( {'from': accounts[0]} )
    # AG Add checks


def test_erc1400_getPartition(erc1400_token, base_token):
    tx = erc1400_token.getPartition(base_token, {'from': accounts[0]} )

def test_erc1400_transferByPartition(erc1400_token):
    default_partition = erc1400_token.getDefaultPartition()

    tx = erc1400_token.transferByPartition(default_partition, accounts[1],  '2 ether','', {'from': accounts[0]})

    assert erc1400_token.balanceOfByPartition(default_partition, accounts[0]) == '998 ether'
    assert erc1400_token.balanceOfByPartition(default_partition, accounts[1]) == '2 ether'

    assert 'Transfer' in tx.events
    assert tx.events['Transfer'] == {'from': accounts[0], 'to': accounts[1], 'amount': '2 ether'}

    assert 'Sent' in tx.events
    assert tx.events['Sent'] == {'from': accounts[0],
                                 'to': accounts[1],
                                 'amount': '2 ether',
                                 'operator': erc1400_token,
                                 'data': '0x',
                                 'operatorData': '0x'}


def test_erc1400_transfer_not_enough_funds(erc1400_token):
    default_partition = erc1400_token.getDefaultPartition()

    with reverts('ERC777: transfer amount exceeds balance'):
        erc1400_token.transferByPartition(default_partition, accounts[1],  '1001 ether','', {'from': accounts[0]})

def test_erc1400_transferWithData(erc1400_token):
    user_data = '15 ether transfered to accounts[1]'.encode()
    tx = erc1400_token.transferWithData( accounts[1], '15 ether', user_data,   {'from': accounts[0]})

    assert erc1400_token.balanceOf( accounts[0]) == '985 ether'
    assert erc1400_token.balanceOf(accounts[1]) == '15 ether'
    assert 'Sent' in tx.events
    assert tx.events['Transfer'] == {'from': accounts[0], 'to': accounts[1], 'amount': '15 ether'}



def test_erc1400_transferFromWithData(erc1400_token):
    operator_data = '15 ether transfered to accounts[1]'.encode()
    erc1400_token.approve(accounts[2], '15 ether', {'from': accounts[0]})
    tx = erc1400_token.transferFromWithData(accounts[0], accounts[1], '15 ether',operator_data, {'from': accounts[2]})
    assert erc1400_token.balanceOf(accounts[0]) == '985 ether'
    assert erc1400_token.balanceOf(accounts[1]) == '15 ether'
    assert 'Transfer' in tx.events
    assert tx.events['Transfer'] == {'from': accounts[0], 'to': accounts[1], 'amount': '15 ether'}


# def test_erc1400_canTransferByPartition(erc1400_token):
# def test_erc1400_resetUserPartitions(erc1400_token):

######################################
# ERC1400 - Owned
######################################

def test_erc1400_owned(erc1400_token):
    assert erc1400_token.owner({'from': accounts[0]}) == accounts[0]

def test_erc1400_transferOwnership(erc1400_token):
    with reverts():
        erc1400_token.transferOwnership(ZERO_ADDRESS, {'from': accounts[0]})
    tx = erc1400_token.transferOwnership(accounts[1], {'from': accounts[0]})
    assert 'OwnershipTransferred' in tx.events
    assert tx.events['OwnershipTransferred'] == {'previousOwner': accounts[0], 'newOwner': accounts[1]}
    with reverts():
        erc1400_token.transferOwnership(accounts[1], {'from': accounts[0]})



######################################
# ERC1400 - Operators
######################################

def test_erc1400_isOperator(erc1400_token):
    assert erc1400_token.isOperator( accounts[3],accounts[6], {'from': accounts[0]}) == True
    assert erc1400_token.isOperator( accounts[6],accounts[7], {'from': accounts[0]}) == False

def test_erc1400_isOperatorForPartition(erc1400_token):
    default_partition = erc1400_token.getDefaultPartition()
    assert erc1400_token.isOperatorForPartition( default_partition, accounts[3],accounts[6], {'from': accounts[0]}) == True
    assert erc1400_token.isOperatorForPartition( default_partition, accounts[6],accounts[7], {'from': accounts[0]}) == False


def test_erc1400_operatorTransferByPartition(erc1400_token):
    default_partition = erc1400_token.getDefaultPartition()

    user_data = '15 ether transfered to accounts[1]'.encode()
    operator_data = '15 ether transfered from accounts[0]'.encode()

    tx = erc1400_token.operatorTransferByPartition(default_partition, accounts[0], accounts[1], '15 ether', user_data, operator_data,  {'from': accounts[2]})

    assert erc1400_token.balanceOfByPartition(default_partition, accounts[0]) == '985 ether'
    assert erc1400_token.balanceOfByPartition(default_partition, accounts[1]) == '15 ether'

    assert 'Sent' in tx.events
    assert tx.events['Transfer'] == {'from': accounts[0], 'to': accounts[1], 'amount': '15 ether'}

def test_erc1400_operator_send_too_much(erc1400_token):
    default_partition = erc1400_token.getDefaultPartition()
    user_data = '1500 ether transfered to accounts[1]'.encode()
    operator_data = '1500 ether transfered to accounts[1]'.encode()

    with reverts('ERC777: transfer amount exceeds balance'):
        tx = erc1400_token.operatorTransferByPartition(default_partition, accounts[0], accounts[1], '1500 ether', user_data, operator_data,  {'from': accounts[2]})

def test_erc1400_not_operator_send(erc1400_token):
    default_partition = erc1400_token.getDefaultPartition()

    user_data = '15 ether minted to accounts[1]'.encode()
    operator_data = '15 ether minted to accounts[1]'.encode()

    with reverts('A7 Transfer Blocked, msg.sender is not an operator'):
        tx = erc1400_token.operatorTransferByPartition(default_partition, accounts[0], accounts[1], '15 ether', user_data, operator_data,  {'from': accounts[1]})




# needs to be delegate called to either the main contract or to the user level
# def test_erc1400_authorizeOperator(erc1400_token):
#     assert erc1400_token.isOperator( accounts[7], {'from': accounts[6]}) == False

#     erc1400_token.authorizeOperator( accounts[7], {'from': accounts[6]})
#     assert erc1400_token.isOperator( accounts[6], {'from': accounts[0]}) == True

# def test_erc1400_authorizeOperatorByPartition(erc1400_token):
#     default_partition = erc1400_token.getDefaultPartition()
#     assert erc1400_token.isOperatorForPartition( default_partition, accounts[6],accounts[7], {'from': accounts[0]}) == False
#     erc1400_token.authorizeOperatorByPartition(default_partition, accounts[6])
#     assert erc1400_token.isOperatorForPartition( default_partition, accounts[6],accounts[7], {'from': accounts[0]}) == True


# def test_erc1400_revokeOperator(erc1400_token):
# def test_erc1400_revokeOperatorByPartition(erc1400_token):


######################################
# ERC1400 - Controllers
######################################
def test_erc1400_isController(erc1400_token):
    assert erc1400_token.isController({'from': accounts[0]}) == True 
    assert erc1400_token.isController({'from': accounts[5]}) == False 

def test_erc1400_isControllable(erc1400_token):
    assert erc1400_token.isControllable({'from': accounts[0]}) == True 

def test_addController(erc1400_token):
    erc1400_token.addController(accounts[6], {'from': accounts[0]})
    assert erc1400_token.isController({'from': accounts[6]}) == True

def test_removeController(erc1400_token):
    tx = erc1400_token.addController(accounts[6], {'from': accounts[0]})
    assert 'ControllerAdded' in tx.events
    assert erc1400_token.isController({'from': accounts[6]}) == True
    tx = erc1400_token.removeController(accounts[6], {'from': accounts[0]})
    assert 'ControllerRemoved' in tx.events
    assert erc1400_token.isController({'from': accounts[6]}) == False


def test_erc1400_controllerTransfer(erc1400_token):
    erc1400_token.addController(accounts[6], {'from': accounts[0]})
    user_data = '2 ether transfered to accounts[1]'.encode()
    operator_data = '2 ether transfered from accounts[0]'.encode()

    tx = erc1400_token.controllerTransfer(accounts[0], accounts[1], '2 ether', user_data,operator_data , {'from': accounts[6]})

    assert erc1400_token.balanceOf(accounts[0]) == '998 ether'
    assert erc1400_token.balanceOf(accounts[1]) == '2 ether'
    assert 'ControllerTransfer' in tx.events
    assert tx.events['ControllerTransfer'] == {'_controller':  accounts[6] \
                                , '_from': accounts[0], '_to': accounts[1], '_value':'2 ether' \
                                , '_data': '0x'+user_data.hex(), '_operatorData': '0x'+operator_data.hex()}


def test_erc1400_controllerTransferByPartition(erc1400_token):
    default_partition = erc1400_token.getDefaultPartition()
    erc1400_token.addController(accounts[6], {'from': accounts[0]})

    user_data = '15 ether transfered to accounts[1] by controller'.encode()
    operator_data = '15 ether transfered from accounts[0] by controller'.encode()

    tx = erc1400_token.controllerTransferByPartition(default_partition, accounts[0], accounts[1], '15 ether', user_data, operator_data,  {'from': accounts[6]})

    assert erc1400_token.balanceOfByPartition(default_partition, accounts[0]) == '985 ether'
    assert erc1400_token.balanceOfByPartition(default_partition, accounts[1]) == '15 ether'

    assert 'ControllerTransfer' in tx.events
    assert tx.events['ControllerTransfer'] == {'_controller':  accounts[6] \
                                , '_from': accounts[0], '_to': accounts[1], '_value':'15 ether' \
                                , '_data': '0x'+user_data.hex(), '_operatorData': '0x'+operator_data.hex()}


######################################
# ERC1400 - Mint and Burn
######################################

def test_erc1400_isIssuable(erc1400_token):
    assert erc1400_token.isIssuable( {'from': accounts[0]}) == True


# def test_erc1400_issue(erc1400_token):
# def test_erc1400_issueByPartition(erc1400_token):
# def test_erc1400_redeem(erc1400_token):
# def test_erc1400_redeemByPartition(erc1400_token):
# def test_erc1400_redeemFrom(erc1400_token):
# def test_erc1400_operatorRedeemByPartition(erc1400_token):


# def test_erc1400_controllerRedeem(erc1400_token):
# def test_erc1400_controllerRedeemByPartition(erc1400_token):


######################################
# ERC1643 - Documents
######################################

def test_erc1643_setDocument(erc1400_token):
    # AG: Change -  Used dummy bytes32 for now
    _name = ERC777_INTERFACE_HASH
    _uri = 'http://www.petyl.com/url=12'
    _documentHash = ERC1820_ACCEPT_MAGIC
    tx = erc1400_token.setDocument(_name, _uri, _documentHash, {'from': accounts[0]})
    assert 'DocumentUpdated' in tx.events

    # REPLACE WITH OWNER
    # with reverts():
    #     tx = erc1400_token.setDocument(_name, _uri, _documentHash, {'from': accounts[1]})
    with reverts():
        tx = erc1400_token.setDocument(_name, '', _documentHash, {'from': accounts[0]})
    with reverts():
        tx = erc1400_token.setDocument('', _uri, _documentHash, {'from': accounts[0]})

def test_erc1643_getDocument(erc1400_token):
    _name = ERC777_INTERFACE_HASH
    _uri = 'http://www.petyl.com/url=12'
    _documentHash = ERC1820_ACCEPT_MAGIC
    tx = erc1400_token.setDocument(_name, _uri, _documentHash, {'from': accounts[0]})
    assert 'DocumentUpdated' in tx.events
    tx = erc1400_token.getDocument(_name, {'from': accounts[0]})
    assert tx[0] == 'http://www.petyl.com/url=12'

def test_erc1643_getAllDocuments(erc1400_token):
    # AG: Needs to have better conditions
    tx = erc1400_token.getAllDocuments( {'from': accounts[0]})

def test_erc1643_removeDocument(erc1400_token):
    # AG: Change -  Used dummy bytes32 for now
    _name = ERC777_INTERFACE_HASH
    _uri = 'http://www.petyl.com/url=12'
    _documentHash = ERC1820_ACCEPT_MAGIC
    tx1 = erc1400_token.setDocument(_name, _uri, _documentHash, {'from': accounts[0]})
    assert 'DocumentUpdated' in tx1.events
    tx2 = erc1400_token.removeDocument(_name, {'from': accounts[0]})
    assert 'DocumentRemoved' in tx2.events

    with reverts('ERC1643: Document should exist'):
        tx2 = erc1400_token.removeDocument('', {'from': accounts[0]})
    with reverts():
        tx2 = erc1400_token.removeDocument(_name, {'from': accounts[1]})
