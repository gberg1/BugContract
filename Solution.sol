pragma solidity ^0.4.24;

// Accepts contributions from people and then divides the money up
// evenly and distributes it to people.
contract Donations {
  // Bug: Unit for Transfer() and msg.value is Wei, not Eth.
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

    // Bug: Length of beneficiaries array is unbounded, so if it gets too
    // long then the transaction will always run out of gas and no one will
    // be able to get paid.
    // Solution: Withdraw pattern, or provide start/end indices for payout so
    // it can be called multiple times.
    for (uint i = 0; i < beneficiaries.length; i++) {
      // Bug: Address could be a malicious contract that blockse
      // payment, preventing everyone else from getting paid as well.
      // Solution: Withdraw pattern.
      beneficiaries[i].transfer(amountPerBeneficiary);
    }
  }

  // Bug: While MAX_CONTRIBUTION is enforced here, Ethereum addresses
  // are "cheap" (easy to create), so if anyone wanted to get around your
  // contribution limit they could just create another ethereum address,
  // transfer some Ether to the new address, and then transfer it again from
  // the new address to this contract to bypass the MAX_CONTRIBUTION limit. This
  // is less of a code bug, and more of a conceptual bug, and is the kind of thing
  // that you might want to warn your client about in case their expectations are
  // not aligned correctly. Solution: Implement a contributors "whitelist".
  //
  // Bug: Even if you implement a whitelist, you still can't prevent people from
  // sending you ether though because a smart contract cannot reject funds received
  // from the result of a selfdestruct() so a malicious user who wanted to fund this
  // contract could create their own contract, fund it with a lot of there, then
  // selfdestruct() it with the address of this contract and this contract will receive
  // the funds and subsequently distribute them in the payout call and there is nothing
  // you can do to stop that as a Solidity developer (its just how the Ethereum Virtual
  // Machine EVM works).
  //
  // Bug: If msg.value is sufficiently large, then contributions[msg.sender] will overflow
  // and the user will have managed to contribute WAY more than MAX_CONTRIBUTION.
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

  // Bug: Missing onlyOwner modifier.
  function transferOwnership(address _newOwner) public {
    owner = _newOwner;
  }

  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }
}
