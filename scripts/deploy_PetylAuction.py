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


def deploy_auction_token():
    if network.show_active() == 'ropsten':
        auction_token_address = web3.toChecksumAddress('0xeA5d540ed6c45667e942f54e36814172Ab25EE99')
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
    if network.show_active() == 'ropsten':
        auction_template_address = web3.toChecksumAddress('0x95Efabf64e483634314BbC638CD22E749ce4bb05')
        dutch_auction_template = PetylDutchAuction.at(auction_template_address)
        return dutch_auction_template 
    
    dutch_auction_template = PetylDutchAuction.deploy({'from': accounts[0]})
    return dutch_auction_template


def deploy_auction_factory(dutch_auction_template):
    if network.show_active() == 'ropsten':
        auction_factory_address = web3.toChecksumAddress('0x0A75F8dB4084263ed7dd8a3C44881cE279e85340')
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

    tx = auction_factory.deployDutchAuction(auction_token, AUCTION_TOKENS, AUCTION_START,AUCTION_END,ETH_ADDRESS, AUCTION_START_PRICE, AUCTION_RESERVE, wallet, {"from": accounts[0]})


    dutch_auction = PetylDutchAuction.at(web3.toChecksumAddress(tx.events['DutchAuctionDeployed']['addr']))
    auction_token.setMintOperator(dutch_auction, True, {"from": accounts[0]})
    assert dutch_auction.auctionPrice() == AUCTION_START_PRICE
    return dutch_auction




def main():
    # add accounts if active network is ropsten
    if network.show_active() == 'ropsten':
        # 0x2A40019ABd4A61d71aBB73968BaB068ab389a636
        accounts.add('4ca89ec18e37683efa18e0434cd9a28c82d461189c477f5622dae974b43baebf')

        # 0x1F3389Fc75Bf55275b03347E4283f24916F402f7
        accounts.add('fa3c06c67426b848e6cef377a2dbd2d832d3718999fbe377236676c9216d8ec0')


    auction_token = deploy_auction_token()
    dutch_auction_template =  deploy_dutch_auction_template()
    auction_factory = deploy_auction_factory(dutch_auction_template)
    dutch_auction = deploy_dutch_auction(auction_factory, auction_token)







# Running 'scripts.deploy_PetylAuction.main'...
# Transaction sent: 0x942d481d0c659386cfd5720dde22f98833f1c5283d806839a7e11be74a57b222
#   Gas price: 2.0 gwei   Gas limit: 3448087
# Waiting for confirmation...
#   PetylBaseToken.constructor confirmed - Block: 7982673   Gas used: 3448087 (100.00%)
#   PetylBaseToken deployed at: 0xeA5d540ed6c45667e942f54e36814172Ab25EE99

# Transaction sent: 0xeec88a7a18a14d3aaa7e6355a509aec68e248cf6ed4a00a5d49e0d12b24cd19a
#   Gas price: 2.0 gwei   Gas limit: 306993
# Waiting for confirmation...
#   PetylBaseToken.initBaseToken confirmed - Block: 7982674   Gas used: 306993 (100.00%)



# Running 'scripts.deploy_PetylAuction.main'...
# Transaction sent: 0x66ca61bc1518f339158c3c74f70ed4ef1b4be1f4e3800eca8feede6e38594783
#   Gas price: 2.0 gwei   Gas limit: 767956
# Waiting for confirmation...
#   PetylDutchAuction.constructor confirmed - Block: 7982772   Gas used: 767956 (100.00%)
#   PetylDutchAuction deployed at: 0x95Efabf64e483634314BbC638CD22E749ce4bb05

# Transaction sent: 0x99907e87b743730373e24eedb080329bd0c0a81ab296c6ff17860a7f4d225730
#   Gas price: 2.0 gwei   Gas limit: 670160
# Waiting for confirmation...
#   PetylAuctionFactory.constructor confirmed - Block: 7982773   Gas used: 670160 (100.00%)
#   PetylAuctionFactory deployed at: 0x0A75F8dB4084263ed7dd8a3C44881cE279e85340

# Transaction sent: 0xd3b4d92d54fc5ae8f3fa4fda19adc0c4c0ed879f1845bccdfb4219bb76d0c308
#   Gas price: 2.0 gwei   Gas limit: 68338
# Waiting for confirmation...
#   PetylAuctionFactory.initPetylAuctionFactory confirmed - Block: 7982774   Gas used: 66846 (97.82%)

# Running 'scripts.deploy_PetylAuction.main'...
# Transaction sent: 0x948f322ee0cff39fd9b1815997d098d2a777020c7b3265f688b79b24da81f0ed
#   Gas price: 3.0 gwei   Gas limit: 285570
# Waiting for confirmation...
#   PetylAuctionFactory.deployDutchAuction confirmed - Block: 7982823   Gas used: 283421 (99.25%)

# Transaction sent: 0x403c4c997d47eee51d85c6eef0948f15724a3a042903e57e5b350c6c63bed907
#   Gas price: 3.0 gwei   Gas limit: 45568
# Waiting for confirmation...
#   PetylBaseToken.setMintOperator confirmed - Block: 7982824   Gas used: 45568 (100.00%)