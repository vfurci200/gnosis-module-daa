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


@pytest.fixture(autouse=True)
def def_setters(baseContract, accounts):
    # set contracts
    pass

###############

@pytest.mark.skip(reason="In")
def test(accounts, usdc):
    # test stuff
    pass
