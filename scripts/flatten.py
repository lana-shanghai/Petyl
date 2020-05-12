
import subprocess

# run  `python scripts/flatten.py`

CONTRACT_DIR = "contracts/"

def flatten(mainsol, outputsol):
    pipe = subprocess.call("scripts/solidityFlattener.pl --contractsdir={} --mainsol={} --outputsol={} --verbose"
                           .format(CONTRACT_DIR, mainsol, outputsol), shell=True)
    print(pipe)

def flatten_contracts():
    flatten("PetylSecurityToken/BaseToken.sol", "flattened/BaseToken_flattened.sol")
    flatten("ERCs/ERC777.sol", "flattened/ERC777_flattened.sol")
    flatten("ERCs/ERC1400.sol", "flattened/ERC1400_flattened.sol")
    flatten("PetylSecurityToken/PetylBaseToken.sol", "flattened/PetylBaseToken_flattened.sol")
    flatten("PetylSecurityToken/PetylSecurityToken.sol", "flattened/PetylSecurityToken_flattened.sol")
    flatten("PetylSecurityToken/PetylTokenFactory.sol", "flattened/PetylTokenFactory_flattened.sol")
    flatten("PetylSecurityToken/WhiteListFactory.sol", "flattened/WhiteListFactory_flattened.sol")
    flatten("PetylSecurityToken/WhiteList.sol", "flattened/WhiteList_flattened.sol")

flatten_contracts()