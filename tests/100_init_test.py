from brownie import accounts, Contract, DaaModule, chain
from brownie.test import given, strategy
import pytest


# @given(amount=strategy('uint256', max_value=10**18))

###############
@pytest.fixture(autouse=True)
def doSomething( accounts):
    pass

# get usdc
@pytest.fixture(scope="session")
def usdc(interface):
    yield interface.IERC20Minimal('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48')

# get 1inch
@pytest.fixture(scope="session")
def oneinchToken(interface):
    yield interface.IERC20Minimal('0x111111111117dc0aa78b770fa6a738034120c302')


# get random safe
@pytest.fixture(scope="session")
def gnosisSafe(interface):
    yield interface.IGnosisSafe('0x5E89f8d81C74E311458277EA1Be3d3247c7cd7D1')

# get random NFT contract
@pytest.fixture(scope="session")
def boredApes(interface):
    yield interface.IERC721('0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D')

# get random ERC1155 contract
@pytest.fixture(scope="session")
def erc1155s(interface):
    yield interface.IERC1155('0x495f947276749Ce646f68AC8c248420045cb7b5e')


@pytest.fixture(autouse=True)
def def_setters( accounts):
    # set contracts
    pass

###############


def test_init(accounts, daaModule,gnosisSafe):
    assert accounts[0] == daaModule._whitelisted()
    assert gnosisSafe == daaModule._safe()

def test_spendERC20(accounts,oneinchToken, daaModule,gnosisSafe):
    gnosisSafe.enableModule(daaModule, {'from': gnosisSafe})
    whitelisted = daaModule._whitelisted()
    spenders = gnosisSafe.getOwners()
    balancePre = oneinchToken.balanceOf(whitelisted)
    daaModule.executeTransfer(oneinchToken,10*10**6,{'from': spenders[0]})
    assert balancePre < oneinchToken.balanceOf(whitelisted)
    
def test_spendETH(accounts,oneinchToken, daaModule,gnosisSafe):
    gnosisSafe.enableModule(daaModule, {'from': gnosisSafe})
    whitelisted = accounts.at(daaModule._whitelisted())
    spenders = gnosisSafe.getOwners()
    # give safe some eth
    accounts[1].transfer(gnosisSafe, '5 ether')
    balancePre = whitelisted.balance()
    daaModule.executeTransfer("0x0000000000000000000000000000000000000000",'1 ether',{'from': spenders[0]})
    assert balancePre < whitelisted.balance()
    assert whitelisted.balance() == (balancePre + "1 ether") 


def test_spendNFT(accounts,boredApes, daaModule,gnosisSafe):
    gnosisSafe.enableModule(daaModule, {'from': gnosisSafe})
    whitelisted = daaModule._whitelisted()
    spenders = gnosisSafe.getOwners()
    nftOwner = boredApes.ownerOf(3650)
    boredApes.transferFrom(nftOwner,gnosisSafe,3650,{'from': nftOwner})
    daaModule.executeTransferNFT(boredApes,3650,{'from': spenders[0]})
    assert boredApes.ownerOf(3650) == whitelisted

# this will fail should erc1155 token id ownership change -> in that case change owner address 
def test_spendERC1155(accounts,erc1155s, daaModule,gnosisSafe):
    gnosisSafe.enableModule(daaModule, {'from': gnosisSafe})
    whitelisted = daaModule._whitelisted()
    spenders = gnosisSafe.getOwners()
    nftOwner = "0xb8f0f88edb25717acaab9ee86ab837a3a6307919"
    balancePre = erc1155s.balanceOf(nftOwner,4162610359126309372267704129311350541016535808838210995016752466896109961217)
    erc1155s.safeTransferFrom(nftOwner,gnosisSafe,4162610359126309372267704129311350541016535808838210995016752466896109961217,1,"0x0",{'from': nftOwner})
    daaModule.executeTransferERC1155(erc1155s,4162610359126309372267704129311350541016535808838210995016752466896109961217,1,{'from': spenders[0]})
    balancePost = erc1155s.balanceOf(nftOwner,4162610359126309372267704129311350541016535808838210995016752466896109961217)
    assert balancePost == balancePre -1
    assert erc1155s.balanceOf(whitelisted,4162610359126309372267704129311350541016535808838210995016752466896109961217) == 1
   
    
# revert: sender not safe owner
@pytest.mark.xfail
def test_spendFailNonOwner(accounts,oneinchToken, daaModule,gnosisSafe):
    gnosisSafe.enableModule(daaModule, {'from': gnosisSafe})
    whitelisted = accounts.at(daaModule._whitelisted())
    spenders = gnosisSafe.getOwners()
    # give safe some eth
    accounts[1].transfer(gnosisSafe, '5 ether')
    balancePre = whitelisted.balance()
    daaModule.executeTransfer("0x0000000000000000000000000000000000000000",'1 ether',{'from': accounts[0]})
    assert balancePre < whitelisted.balance()
    assert whitelisted.balance() == (balancePre + "1 ether") 


