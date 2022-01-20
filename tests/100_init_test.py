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
    yield interface.IERC20Minimal('0x2791bca1f2de4661ed88a30c99a7a9449aa84174')

# get random safe
@pytest.fixture(scope="session")
def gnosisSafe(interface):
    yield interface.IGnosisSafe('0x5E89f8d81C74E311458277EA1Be3d3247c7cd7D1')


@pytest.fixture(autouse=True)
def def_setters( accounts):
    # set contracts
    pass

###############


def test_init(accounts, daaModule,gnosisSafe):
    assert accounts[0] == daaModule._whitelisted()
    assert gnosisSafe == daaModule._safe()

def test_spend(accounts,usdc, daaModule,gnosisSafe):
    gnosisSafe.enableModule(daaModule, {'from': gnosisSafe})
    whitelisted = daaModule._whitelisted()
    daaModule.executeTransfer(usdc,whitelisted,10)
    pass
    
