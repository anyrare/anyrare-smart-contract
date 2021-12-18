pragma solidity ^0.8.0;

contract Governance {
    struct Manager {
        address addr;
        uint32 controlWeight;
    }

    struct Auditor {
        bool approve;
    }

    struct Custodian {
        bool approve;
    }

    uint32 public divisor;
    uint32 public collateralWeight;
    uint32 public managementWeight;
    uint32 public buybackWeight;
    uint32 public auctionFee;
    uint32 public collectionFee;
    uint32 public mintFee;
    uint32 public referralFee;
    uint8 public totalManager;


    mapping(uint8 => Manager) public managers;
    mapping(address => Auditor) public auditors;
    mapping(address => Custodian) public custodians;
}
