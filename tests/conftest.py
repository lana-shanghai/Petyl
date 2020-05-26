
from brownie import accounts, web3, Wei, rpc
from brownie.network.transaction import TransactionReceipt
from brownie.convert import to_address
import pytest
from brownie import Contract
from settings import *

######################################
# Deploy Contracts
######################################

@pytest.fixture(scope='module', autouse=True)
def erc1820_registry(ERC1820Registry):
    # ERC1820Registry contract deployment
    # See https://github.com/ethereum/EIPs/issues/1820 for more details
    raw_transaction = '0xf90a388085174876e800830c35008080b909e5608060405234801561001057600080fd5b506109c5806100206000396000f3fe608060405234801561001057600080fd5b50600436106100a5576000357c010000000000000000000000000000000000000000000000000000000090048063a41e7d5111610078578063a41e7d51146101d4578063aabbb8ca1461020a578063b705676514610236578063f712f3e814610280576100a5565b806329965a1d146100aa5780633d584063146100e25780635df8122f1461012457806365ba36c114610152575b600080fd5b6100e0600480360360608110156100c057600080fd5b50600160a060020a038135811691602081013591604090910135166102b6565b005b610108600480360360208110156100f857600080fd5b5035600160a060020a0316610570565b60408051600160a060020a039092168252519081900360200190f35b6100e06004803603604081101561013a57600080fd5b50600160a060020a03813581169160200135166105bc565b6101c26004803603602081101561016857600080fd5b81019060208101813564010000000081111561018357600080fd5b82018360208201111561019557600080fd5b803590602001918460018302840111640100000000831117156101b757600080fd5b5090925090506106b3565b60408051918252519081900360200190f35b6100e0600480360360408110156101ea57600080fd5b508035600160a060020a03169060200135600160e060020a0319166106ee565b6101086004803603604081101561022057600080fd5b50600160a060020a038135169060200135610778565b61026c6004803603604081101561024c57600080fd5b508035600160a060020a03169060200135600160e060020a0319166107ef565b604080519115158252519081900360200190f35b61026c6004803603604081101561029657600080fd5b508035600160a060020a03169060200135600160e060020a0319166108aa565b6000600160a060020a038416156102cd57836102cf565b335b9050336102db82610570565b600160a060020a031614610339576040805160e560020a62461bcd02815260206004820152600f60248201527f4e6f7420746865206d616e616765720000000000000000000000000000000000604482015290519081900360640190fd5b6103428361092a565b15610397576040805160e560020a62461bcd02815260206004820152601a60248201527f4d757374206e6f7420626520616e204552433136352068617368000000000000604482015290519081900360640190fd5b600160a060020a038216158015906103b85750600160a060020a0382163314155b156104ff5760405160200180807f455243313832305f4143434550545f4d4147494300000000000000000000000081525060140190506040516020818303038152906040528051906020012082600160a060020a031663249cb3fa85846040518363ffffffff167c01000000000000000000000000000000000000000000000000000000000281526004018083815260200182600160a060020a0316600160a060020a031681526020019250505060206040518083038186803b15801561047e57600080fd5b505afa158015610492573d6000803e3d6000fd5b505050506040513d60208110156104a857600080fd5b5051146104ff576040805160e560020a62461bcd02815260206004820181905260248201527f446f6573206e6f7420696d706c656d656e742074686520696e74657266616365604482015290519081900360640190fd5b600160a060020a03818116600081815260208181526040808320888452909152808220805473ffffffffffffffffffffffffffffffffffffffff19169487169485179055518692917f93baa6efbd2244243bfee6ce4cfdd1d04fc4c0e9a786abd3a41313bd352db15391a450505050565b600160a060020a03818116600090815260016020526040812054909116151561059a5750806105b7565b50600160a060020a03808216600090815260016020526040902054165b919050565b336105c683610570565b600160a060020a031614610624576040805160e560020a62461bcd02815260206004820152600f60248201527f4e6f7420746865206d616e616765720000000000000000000000000000000000604482015290519081900360640190fd5b81600160a060020a031681600160a060020a0316146106435780610646565b60005b600160a060020a03838116600081815260016020526040808220805473ffffffffffffffffffffffffffffffffffffffff19169585169590951790945592519184169290917f605c2dbf762e5f7d60a546d42e7205dcb1b011ebc62a61736a57c9089d3a43509190a35050565b600082826040516020018083838082843780830192505050925050506040516020818303038152906040528051906020012090505b92915050565b6106f882826107ef565b610703576000610705565b815b600160a060020a03928316600081815260208181526040808320600160e060020a031996909616808452958252808320805473ffffffffffffffffffffffffffffffffffffffff19169590971694909417909555908152600284528181209281529190925220805460ff19166001179055565b600080600160a060020a038416156107905783610792565b335b905061079d8361092a565b156107c357826107ad82826108aa565b6107b85760006107ba565b815b925050506106e8565b600160a060020a0390811660009081526020818152604080832086845290915290205416905092915050565b6000808061081d857f01ffc9a70000000000000000000000000000000000000000000000000000000061094c565b909250905081158061082d575080155b1561083d576000925050506106e8565b61084f85600160e060020a031961094c565b909250905081158061086057508015155b15610870576000925050506106e8565b61087a858561094c565b909250905060018214801561088f5750806001145b1561089f576001925050506106e8565b506000949350505050565b600160a060020a0382166000908152600260209081526040808320600160e060020a03198516845290915281205460ff1615156108f2576108eb83836107ef565b90506106e8565b50600160a060020a03808316600081815260208181526040808320600160e060020a0319871684529091529020549091161492915050565b7bffffffffffffffffffffffffffffffffffffffffffffffffffffffff161590565b6040517f01ffc9a7000000000000000000000000000000000000000000000000000000008082526004820183905260009182919060208160248189617530fa90519096909550935050505056fea165627a7a72305820377f4a2d4301ede9949f163f319021a6e9c687c292a5e2b2c4734c126b524e6c00291ba01820182018201820182018201820182018201820182018201820182018201820a01820182018201820182018201820182018201820182018201820182018201820'
    abi = [{"constant":False,"inputs":[{"name":"_addr","type":"address"},{"name":"_interfaceHash","type":"bytes32"},{"name":"_implementer","type":"address"}],"name":"setInterfaceImplementer","outputs":[],"payable":False,"stateMutability":"nonpayable","type":"function"},{"constant":True,"inputs":[{"name":"_addr","type":"address"}],"name":"getManager","outputs":[{"name":"","type":"address"}],"payable":False,"stateMutability":"view","type":"function"},{"constant":False,"inputs":[{"name":"_addr","type":"address"},{"name":"_newManager","type":"address"}],"name":"setManager","outputs":[],"payable":False,"stateMutability":"nonpayable","type":"function"},{"constant":True,"inputs":[{"name":"_interfaceName","type":"string"}],"name":"interfaceHash","outputs":[{"name":"","type":"bytes32"}],"payable":False,"stateMutability":"pure","type":"function"},{"constant":False,"inputs":[{"name":"_contract","type":"address"},{"name":"_interfaceId","type":"bytes4"}],"name":"updateERC165Cache","outputs":[],"payable":False,"stateMutability":"nonpayable","type":"function"},{"constant":True,"inputs":[{"name":"_addr","type":"address"},{"name":"_interfaceHash","type":"bytes32"}],"name":"getInterfaceImplementer","outputs":[{"name":"","type":"address"}],"payable":False,"stateMutability":"view","type":"function"},{"constant":True,"inputs":[{"name":"_contract","type":"address"},{"name":"_interfaceId","type":"bytes4"}],"name":"implementsERC165InterfaceNoCache","outputs":[{"name":"","type":"bool"}],"payable":False,"stateMutability":"view","type":"function"},{"constant":True,"inputs":[{"name":"_contract","type":"address"},{"name":"_interfaceId","type":"bytes4"}],"name":"implementsERC165Interface","outputs":[{"name":"","type":"bool"}],"payable":False,"stateMutability":"view","type":"function"},{"anonymous":False,"inputs":[{"indexed":True,"name":"addr","type":"address"},{"indexed":True,"name":"interfaceHash","type":"bytes32"},{"indexed":True,"name":"implementer","type":"address"}],"name":"InterfaceImplementerSet","type":"event"},{"anonymous":False,"inputs":[{"indexed":True,"name":"addr","type":"address"},{"indexed":True,"name":"newManager","type":"address"}],"name":"ManagerChanged","type":"event"}]
    deployment_address = web3.toChecksumAddress('0xa990077c3205cbDf861e17Fa532eeB069cE9fF96')
    funding_amount = Wei("1 ether")

    # Send ether to the registry deployment account
    web3.eth.sendTransaction({
        'from': accounts[0].address,
        'to': deployment_address,
        'value': funding_amount
    })

    # Deploy ERC1820Registry contract
    tx_hash = web3.eth.sendRawTransaction(raw_transaction)

    # Print brownie-style TransactionReceipt
    TransactionReceipt(tx_hash, deployment_address, name='ERC1820Registry.constructor')
    return Contract('ERC1820Registry','0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24', abi)



##############################################
# Token Factory
##############################################


@pytest.fixture(scope='module', autouse=True)
def base_token_template(PetylBaseToken, erc1820_registry):
    base_token_template = PetylBaseToken.deploy({'from': accounts[0]})
    return base_token_template


@pytest.fixture(scope='module', autouse=True)
def venture_template(PetylVenture):
    venture_template = PetylVenture.deploy({"from": accounts[0]})
    return venture_template


@pytest.fixture(scope='module', autouse=True)
def petyl_factory(PetylTokenFactory, venture_template, base_token_template):
    petyl_factory = PetylTokenFactory.deploy({"from": accounts[0]})
    petyl_factory.initPetylTokenFactory(venture_template ,base_token_template, 0, {"from": accounts[0]})
    assert petyl_factory.numberOfChildren( {'from': accounts[0]}) == 0 

    return petyl_factory


@pytest.fixture(scope='module', autouse=True)
def base_token(PetylBaseToken, petyl_factory):

    token_owner = accounts[0]
    name = 'BASE TOKEN'
    symbol = 'BTN'
    default_operators = accounts[2:4]
    burn_operator = accounts[4]
    controller = accounts[5]
    initial_supply = '1000 ether'

    tx = petyl_factory.deployBaseToken(token_owner,  name,symbol, default_operators, burn_operator, initial_supply,{'from': accounts[0]})
    base_token = PetylBaseToken.at(tx.return_value)
    base_token.addController(controller, {'from': token_owner})

    return base_token



##############################################
# White List
##############################################


@pytest.fixture(scope='module', autouse=True)
def white_list_template(WhiteList):
    white_list_template = WhiteList.deploy({"from": accounts[0]})
    return white_list_template



@pytest.fixture(scope='module', autouse=True)
def whitelist_factory(WhiteListFactory,white_list_template):
    whitelist_factory = WhiteListFactory.deploy({"from": accounts[0]})
    whitelist_factory.initWhiteListFactory( white_list_template, 0, {"from": accounts[0]})
    assert whitelist_factory.numberOfChildren( {'from': accounts[0]}) == 0 
    return whitelist_factory

@pytest.fixture(scope='module', autouse=True)
def white_list(whitelist_factory, WhiteList):
    tx = whitelist_factory.deployWhiteList(accounts[0], [accounts[0]], {'from': accounts[0]})
    white_list = WhiteList.at(tx.return_value)
    return white_list



##############################################
# Venture
##############################################


@pytest.fixture(scope='module', autouse=True)
def token_rules(PetylTokenRules, base_token, erc1820_registry):
    token_rules = PetylTokenRules.deploy({'from': accounts[0]})
    tx = token_rules.registerToken(base_token, {'from': accounts[0]}) 
    return token_rules


@pytest.fixture(scope='module', autouse=True)
def regulated_token(PetylBaseToken, petyl_factory, token_rules):
    token_owner = accounts[0]
    name = 'REGULATED TOKEN'
    symbol = 'RTN'
    default_operators = accounts[2:4]
    burn_operator = accounts[4]
    controller = accounts[5]
    initial_supply = '500 ether'

    tx = petyl_factory.deployBaseToken(token_owner,  name, symbol, default_operators, burn_operator, initial_supply,{'from': accounts[0]})
    regulated_token = PetylBaseToken.at(tx.return_value)

    regulated_token.addController(controller, {'from': accounts[0]})
    tx = token_rules.registerToken(regulated_token, {'from': accounts[0]}) 
    tx = regulated_token.setTokenRules(token_rules, {'from': accounts[0]})
    assert 'SetTokenRules' in tx.events
    assert tx.events['SetTokenRules'] == {'controller': accounts[0], 'rules': token_rules}
    return regulated_token


@pytest.fixture(scope='module', autouse=True)
def erc1400_token(PetylVenture, base_token, regulated_token):
    erc1400_token = PetylVenture.deploy({"from": accounts[0]})
    erc1400_token.initPetylVenture(accounts[0], base_token, {"from": accounts[0]})
    base_token.authorizeOperator(erc1400_token, {'from': accounts[0]})
    tx = erc1400_token.addPartition(regulated_token, {"from": accounts[0]})
    assert 'AddedPartition' in tx.events
    return erc1400_token


@pytest.fixture(scope='module', autouse=True)
def token_converter(PetylTokenConverter):
    token_converter = PetylTokenConverter.deploy( {"from": accounts[0]})
    return token_converter


@pytest.fixture(scope='module', autouse=True)
def petyl_venture(petyl_factory, regulated_token, PetylVenture):
    token_owner = accounts[0]
    name = 'BASE TOKEN'
    symbol = 'BTN'
    default_operators = accounts[2:4]
    burn_operator = accounts[4]
    controller = accounts[5]
    initial_supply = '1000 ether'

    tx = petyl_factory.deployPetylContract(token_owner, name,  symbol, default_operators, burn_operator, initial_supply,{'from': accounts[0]})
    assert 'PetylDeployed' in tx.events
    petyl_venture = PetylVenture.at(tx.return_value)

    # base_token.authorizeOperator(petyl_venture, {'from': accounts[0]})
    tx = petyl_venture.addPartition(regulated_token, {"from": accounts[0]})
    assert 'AddedPartition' in tx.events
    return petyl_venture




##############################################
# Voting
##############################################


@pytest.fixture(scope='module', autouse=True)
def petyl_token(PetylBaseToken, petyl_factory):

    token_owner = accounts[0]
    name = 'PETYL TOKEN'
    symbol = 'PTYL'
    default_operators = [ZERO_ADDRESS]
    burn_operator = ZERO_ADDRESS
    controller = ZERO_ADDRESS
    initial_supply = 0

    tx = petyl_factory.deployBaseToken(token_owner,  name,symbol, default_operators, burn_operator, initial_supply,{'from': accounts[0]})
    petyl_token = PetylBaseToken.at(tx.return_value)
    petyl_token.addController(controller, {'from': token_owner})

    return petyl_token


@pytest.fixture(scope='module', autouse=True)
def proposals_lib(Proposals):
    proposals_lib = Proposals.deploy({'from': accounts[0]})
    return proposals_lib

@pytest.fixture(scope='module', autouse=True)
def members_lib(Members):
    members_lib = Members.deploy({'from': accounts[0]})
    return members_lib

@pytest.fixture(scope='module', autouse=True)
def petyl_vote(PetylVote, members_lib, proposals_lib, petyl_token):
    petyl_vote = PetylVote.deploy({"from": accounts[0]})
    petyl_token.setMintOperator(petyl_vote, True, {"from": accounts[0]})

    petyl_vote.initPetylVote(petyl_token,"Flowers",VOTE_TOKENS, {"from": accounts[0]})
    petyl_vote.initAddMember("Rose", accounts[0], {"from": accounts[0]})
    petyl_vote.initAddMember("Tulip", accounts[1], {"from": accounts[0]})
    petyl_vote.initialisationComplete({"from": accounts[0]})
    return petyl_vote


# @pytest.fixture(scope='module', autouse=True)
# def vote_token(PetylBaseToken, petyl_factory):

#     token_owner = accounts[0]
#     name = 'PETYL TOKEN'
#     symbol = 'PTYL'
#     default_operators = [ZERO_ADDRESS]
#     burn_operator = ZERO_ADDRESS
#     controller = ZERO_ADDRESS
#     initial_supply = 0

#     tx = petyl_factory.deployBaseToken(token_owner,  name,symbol, default_operators, burn_operator, initial_supply,{'from': accounts[0]})
#     vote_token = PetylBaseToken.at(tx.return_value)
#     vote_token.addController(controller, {'from': token_owner})

#     return vote_token


# @pytest.fixture(scope='module', autouse=True)
# def token_vote(PetylTokenVote, members_lib, proposals_lib, vote_token):
#     token_vote = PetylTokenVote.deploy({"from": accounts[0]})
#     vote_token.setMintOperator(token_vote, True, {"from": accounts[0]})

#     token_vote.initPetylVote(vote_token,"Flowers",VOTE_TOKENS, VOTE_TOKENS, {"from": accounts[0]})
#     token_vote.initAddMember("Rose", accounts[0], {"from": accounts[0]})
#     token_vote.initAddMember("Tulip", accounts[1], {"from": accounts[0]})
#     token_vote.initialisationComplete({"from": accounts[0]})
#     return token_vote


##############################################
# Auction
##############################################

@pytest.fixture(scope='module', autouse=True)
def auction_token(PetylBaseToken, petyl_factory):

    token_owner = accounts[0]
    name = 'PETYL TOKEN'
    symbol = 'PTYL'
    default_operators = [ZERO_ADDRESS]
    burn_operator = ZERO_ADDRESS
    controller = ZERO_ADDRESS
    initial_supply = 0

    tx = petyl_factory.deployBaseToken(token_owner,  name,symbol, default_operators, burn_operator, initial_supply,{'from': accounts[0]})
    auction_token = PetylBaseToken.at(tx.return_value)
    auction_token.addController(controller, {'from': token_owner})

    return auction_token



@pytest.fixture(scope='module', autouse=True)
def dutch_auction(PetylDutchAuction, auction_token):
    startDate = rpc.time() +10
    endDate = startDate + AUCTION_TIME
    wallet = accounts[1]

    dutch_auction = PetylDutchAuction.deploy({'from': accounts[0]})
    dutch_auction.initDutchAuction(auction_token, AUCTION_TOKENS, startDate, endDate, AUCTION_START_PRICE, AUCTION_RESERVE, wallet, {"from": accounts[0]})
    auction_token.setMintOperator(dutch_auction, True, {"from": accounts[0]})
    assert dutch_auction.auctionPrice() == AUCTION_START_PRICE
    rpc.sleep(10)
    return dutch_auction
