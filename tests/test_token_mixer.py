from brownie import accounts, web3, Wei, reverts
from brownie.network.transaction import TransactionReceipt
from brownie.convert import to_address
import pytest
from brownie import Contract


# reset the chain after every test case
@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass

