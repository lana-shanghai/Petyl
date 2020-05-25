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



def test_petyl_vote_proposeAddMember(petyl_vote):
    memberName = "Daisy"
    memberAddress = accounts[4]

    tx = petyl_vote.proposeAddMember(memberName, memberAddress, {'from': accounts[0]})
    assert 'NewProposal' in tx.events
    proposalId = tx.events['NewProposal']['proposalId']
    tx = petyl_vote.voteYes(proposalId, {'from': accounts[1]})
    assert 'Voted' in tx.events
    assert 'MemberAdded' in tx.events


