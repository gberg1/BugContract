pragma solidity ^0.4.24;

// Accepts contributions from people and then divides the money up
// evenly and distributes it to people.
contract Donations {
  // Maximum contribution per address is 100 Eth.
  uint constant MAX_CONTRIBUTION = 100;

  address owner;

  address[] beneficiaries;
  mapping(address => uint) contributions;

  constructor() public {
    owner = msg.sender;
  }

  function addBeneficiary(address _beneficiary) onlyOwner public {
    beneficiaries.push(_beneficiary);
  }

  function payout() public {
    uint amountPerBeneficiary = address(this).balance / beneficiaries.length;
    require(amountPerBeneficiary > 0);

    for (uint i = 0; i < beneficiaries.length; i++) {
      beneficiaries[i].transfer(amountPerBeneficiary);
    }
  }

  function contribute() payable public {
    contributions[msg.sender] += msg.value;
    require(contributions[msg.sender] <= MAX_CONTRIBUTION);
  }

  // Explicitly reject contributions that don't go through the contribute
  // function to prevent people from bypassing it. Technically in newer
  // versions of Solidity, this is not required, as the contract will reject
  // and transactions with no data if no fallback function is defined.
  function() payable public {
    revert();
  }

  function transferOwnership(address _newOwner) public {
    owner = _newOwner;
  }

  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }
}
