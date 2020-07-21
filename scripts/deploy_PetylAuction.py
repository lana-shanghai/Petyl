from brownie import *
import time


TENPOW18 = 10 ** 18
ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'
ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'


AUCTION_TOKENS = 1000 * TENPOW18
AUCTION_DAYS = 2
AUCTION_START_PRICE = 100 * TENPOW18
AUCTION_RESERVE = 0.001 * TENPOW18


AUCTION_START = int(time.time()) + 200   # Few minutes to deploy
AUCTION_END = AUCTION_START + 60 * 60 * 24 * AUCTION_DAYS


# add accounts if active network is ropsten
if network.show_active() == 'ropsten':
    # 0x2A40019ABd4A61d71aBB73968BaB068ab389a636
    accounts.add('4ca89ec18e37683efa18e0434cd9a28c82d461189c477f5622dae974b43baebf')

    # 0x1F3389Fc75Bf55275b03347E4283f24916F402f7
    accounts.add('fa3c06c67426b848e6cef377a2dbd2d832d3718999fbe377236676c9216d8ec0')
    BASE_TOKEN =  '0x60FE4B3DF6A0Ef3F417d498265Be07eb0bC4D237'
    AUCTION_TEMPLATE = '0x392987b469D8845ABA94Ef753457eC668a376B04'
    AUCTION_FACTORY = '0xE736dEe490731ffc201805008469108Ee48C3827'
    USE_EXISTING_CONTRACTS = True



def deploy_auction_token():
    if network.show_active() == 'ropsten' and USE_EXISTING_CONTRACTS:
        auction_token_address = web3.toChecksumAddress(BASE_TOKEN)
        auction_token = PetylBaseToken.at(auction_token_address)
        return auction_token 

    token_owner = accounts[0]
    name = 'PETYL TOKEN'
    symbol = 'PTYL'
    default_operators = [ZERO_ADDRESS]
    burn_operator = ZERO_ADDRESS
    controller = ZERO_ADDRESS
    initial_supply = 0
    auction_token = PetylBaseToken.deploy({'from': accounts[0]})
    auction_token.initBaseToken(accounts[0], name,
                                  symbol,
                                  default_operators,
                                  burn_operator,
                                  initial_supply,
                                  {'from': accounts[0]})

    return auction_token



def deploy_dutch_auction_template():
    if network.show_active() == 'ropsten' and USE_EXISTING_CONTRACTS:
        auction_template_address = web3.toChecksumAddress(AUCTION_TEMPLATE)
        dutch_auction_template = PetylDutchAuction.at(auction_template_address)
        return dutch_auction_template 
    
    dutch_auction_template = PetylDutchAuction.deploy({'from': accounts[0]})
    return dutch_auction_template


def deploy_auction_factory(dutch_auction_template):
    if network.show_active() == 'ropsten' and USE_EXISTING_CONTRACTS:
        auction_factory_address = web3.toChecksumAddress(AUCTION_FACTORY)
        auction_factory = PetylAuctionFactory.at(auction_factory_address)
        return auction_factory 


    auction_factory = PetylAuctionFactory.deploy({"from": accounts[0]})
    auction_factory.initPetylAuctionFactory(dutch_auction_template, 0, {"from": accounts[0]})
    assert auction_factory.numberOfAuctions( {'from': accounts[0]}) == 0 

    return auction_factory


def deploy_dutch_auction(auction_factory, auction_token):
    startDate = AUCTION_START
    endDate = AUCTION_END
    wallet = accounts[1]
    tx = auction_token.mint(accounts[0], AUCTION_TOKENS, '','', {'from': accounts[0]})

    tx = auction_token.approve(auction_factory, AUCTION_TOKENS, {'from': accounts[0]})
    tx = auction_factory.deployDutchAuction(auction_token, AUCTION_TOKENS, AUCTION_START,AUCTION_END,ETH_ADDRESS, AUCTION_START_PRICE, AUCTION_RESERVE, wallet, {"from": accounts[0]})

    dutch_auction = PetylDutchAuction.at(web3.toChecksumAddress(tx.events['DutchAuctionDeployed']['addr']))
    assert dutch_auction.clearingPrice() == AUCTION_START_PRICE
    return dutch_auction




def main():


    auction_token = deploy_auction_token()
    dutch_auction_template =  deploy_dutch_auction_template()
    auction_factory = deploy_auction_factory(dutch_auction_template)
    dutch_auction = deploy_dutch_auction(auction_factory, auction_token)






# Running 'scripts.deploy_PetylAuction.main'...
# Transaction sent: 0x535c3cf185d377f3a83eb379127313a694a29c1f2fcbb0d7bdea8cc978668228
#   Gas price: 1.0 gwei   Gas limit: 3396980
# Waiting for confirmation...
#   PetylBaseToken.constructor confirmed - Block: 8335724   Gas used: 3396980 (100.00%)
#   PetylBaseToken deployed at: 0x60FE4B3DF6A0Ef3F417d498265Be07eb0bC4D237

# Transaction sent: 0x2e95284c5593b8fc4e4114bd0f83b5a9644089616e10c3e3cbb071a5f319eb28
#   Gas price: 1.0 gwei   Gas limit: 265103
# Waiting for confirmation...
#   PetylBaseToken.initBaseToken confirmed - Block: 8335725   Gas used: 265103 (100.00%)

# Transaction sent: 0x153c1a0c50c0c29eea490d7c309569c96ef12d80382340c0d83c5af85ed1dc5d
#   Gas price: 1.0 gwei   Gas limit: 933447
# Waiting for confirmation...
#   PetylDutchAuction.constructor confirmed - Block: 8335727   Gas used: 933447 (100.00%)
#   PetylDutchAuction deployed at: 0x392987b469D8845ABA94Ef753457eC668a376B04

# Transaction sent: 0x0790fca0b8148dea4c1bd0d968c49ea190b9fbfd8ff5718f2cd1eeaa9ba04867
#   Gas price: 1.0 gwei   Gas limit: 734202
# Waiting for confirmation...
#   PetylAuctionFactory.constructor confirmed - Block: 8335729   Gas used: 734202 (100.00%)
#   PetylAuctionFactory deployed at: 0xE736dEe490731ffc201805008469108Ee48C3827

# Transaction sent: 0x283ce85fcf71342614a1f34675bd38cecf5b5711284b9f764a1b7bbf77da0e43
#   Gas price: 1.0 gwei   Gas limit: 68338
# Waiting for confirmation...
#   PetylAuctionFactory.initPetylAuctionFactory confirmed - Block: 8335731   Gas used: 66846 (97.82%)


# Transaction sent: 0xb99d8fd21580e757f2720a97793860724cfcc210d46f44899cd2676478757d67
#   Gas price: 1.0 gwei   Gas limit: 76740
# Waiting for confirmation...
#   PetylBaseToken.mint confirmed - Block: 8335936   Gas used: 76740 (100.00%)

# Transaction sent: 0x7d370ba18e5db981fdfc916a4c666b546b02fd3c543f51ba16237451126b8d12
#   Gas price: 1.0 gwei   Gas limit: 24974
# Waiting for confirmation...
#   PetylBaseToken.approve confirmed - Block: 8335939   Gas used: 24974 (100.00%)

# Transaction sent: 0x22fcefba8d99160e6e7954a147d049ef666a01bc7333334f9dd3d5db422093ba
#   Gas price: 1.0 gwei   Gas limit: 440727
# Waiting for confirmation...
#   PetylAuctionFactory.deployDutchAuction confirmed - Block: 8335944   Gas used: 367245 (83.33%)