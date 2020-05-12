from brownie import accounts, web3, Wei, reverts
from brownie.network.transaction import TransactionReceipt
from brownie.convert import to_address
import pytest
from brownie import Contract


# reset the chain after every test case
@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass



def test_petyl_token_addNewPartition(security_token, PetylBaseToken):
 
    name = 'INVESTOR TOKEN'
    symbol = 'ITN'
    default_operators = accounts[2:4]
    burn_operator = accounts[4]
    controller = security_token
    initial_supply = '1000 ether'

    tx = security_token.addNewPartition(name, symbol, default_operators, burn_operator, initial_supply, {'from': accounts[0]})
    assert 'AddedNewPartition' in tx.events
    baseToken = PetylBaseToken.at(tx.events['AddedNewPartition']['partitionAddress'])
    baseToken.addController(controller, {'from': accounts[0]})
    assert baseToken.isController({'from': security_token}) == True

