// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DaoTaxer is ReentrancyGuard {
    /*
     * Dao details :
     * Struct [...DealDetails, Period, Price, PaymentType, PaymentContract, Owner/Vault, Registration status, Discount]
     */
    /*
     * Dao => Address => LastPayment
     * Dao => Price
     *
     */

    /* [86400,200000000000000000,0,1,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0] */

    // Owner address : 0xFD23c55fc75e1eaAdBB5493639C84b54B331A396
    // Contract on callibraion : 0x5f3E5Ec71423380e2E652dafA98E5654a969d2BE

    /**
     * V.0 : Dao registration, user registration if dao register is open, user pay, get user availability, get user expiration time
     */
    enum PaymentType {
        Token,
        Ether,
        Contribution,
        Other
    }
    enum RegistrationStatus {
        Open,
        Closed,
        Permissioned,
        Other
    }
    struct DaoDetails {
        uint256 period;
        uint256 price;
        uint256 discount;
        bool isBalanceLocked;
        PaymentType paymentType;
        address payable paymentContract;
        address payable vault;
        RegistrationStatus registrationStatus;
    }

    // Used for registration, Dao's can use this to register their details
    mapping(address => DaoDetails) public daoDetails;
    // Used for tracking Dao's balances (if active)
    mapping(address => uint256) public daoBalances;
    // Used for tracking users payments
    // Dao registration address  => user address => last payment
    mapping(address => mapping(address => uint256)) public lastPayment;

    /**
     * Functions :
     * Register DAO
     * Update DAO
     * Make Payment
     * Get Expiration Time
     * Get User Availability
     */

    function registerDao(
        DaoDetails memory registrationDetails
    ) public nonReentrant {
        // Check if dao is already registered
        require(
            daoDetails[msg.sender].vault == address(0),
            "Dao already registered"
        );
        require(
            registrationDetails.vault == msg.sender,
            "Vault can't be different from sender"
        );
        // Register Dao
        daoDetails[msg.sender] = registrationDetails;
    }

    function sampleDaoDetails() public pure returns (DaoDetails memory x) {
        x = DaoDetails(
            1 days,
            0.2 ether,
            0,
            false,
            PaymentType.Ether,
            payable(address(0)),
            payable(address(0)),
            RegistrationStatus.Open
        );
        return x;
    }

    function makePayment(address selectedDao) public payable nonReentrant {
        require(
            daoDetails[selectedDao].vault != address(0),
            "Dao not registered"
        );
        require(
            daoDetails[selectedDao].registrationStatus ==
                RegistrationStatus.Open,
            "Dao registration closed"
        );
        require(
            daoDetails[selectedDao].paymentType == PaymentType.Ether,
            "Dao payment type not supported"
        );

        require(
            msg.value >= daoDetails[selectedDao].price,
            "Insufficient payment"
        );
        lastPayment[selectedDao][msg.sender] = block.timestamp;
        daoBalances[selectedDao] += msg.value;
    }

    function getUser(address user, address dao) public view returns (uint256) {
        return
            lastPayment[dao][user] + daoDetails[dao].period < block.timestamp
                ? 0
                : 1;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
