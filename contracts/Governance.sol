pragma solidity ^ 0.8.0;

contract Governance {
  struct Manager {
    address addr;
    uint64 controlWeight;
  }

  struct Auditor {
    bool approve;
  }

  struct Custodian {
    bool approve;
  }

  struct Policy {
    uint32 weight;
    uint32 weightDivisor;
    uint64 voteDurationInSecond;
    uint64 minimumTokenRatioToOpenVote;
    uint64 minimumTokenRatioToValidVote;
    uint64 minimumTokenRatioToAcceptVote;
    uint64 voteDivisor;
  }

  Policy public collateralWeight;
  Policy public managementWeight;
  Policy public buybackWeight;
  Policy public auctionFee;
  Policy public collectionFee;
  Policy public mintFee;
  Policy public redeemFee;
  Policy public referralFee;
  Policy public totalManager;

  address public memberContract;
  address public auctionContract;
  address public collectionContract;
  address public ARATokenContract;

  mapping(uint64 => Manager) public managers;
  mapping(address => Auditor) public auditors;
  mapping(address => Custodian) public custodians;

  constructor() public {
    collateralWeight.weight = 10000;
  }

  function getCollateralWeight() public view returns (uint32) {
    return collateralWeight.weight;
  }

  function getMemberContract() public view returns (address) {
    return memberContract;
  }
}
