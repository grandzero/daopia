// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    /* [3600,200000000000000000,1,0xFD23c55fc75e1eaAdBB5493639C84b54B331A396,0xFD23c55fc75e1eaAdBB5493639C84b54B331A396,0] */

    // Owner address : 0xFD23c55fc75e1eaAdBB5493639C84b54B331A396
    // Contract on callibraion : 0x5f3E5Ec71423380e2E652dafA98E5654a969d2BE

    /**
     * V.0.3
     * - ragisterDao
     * - makePayment
     * - getUser
     * - changeRegistration
     * - changePrice
     * - changePeriod
     * - applyDiscount
     * - getUserExpiration
     * - withdrawDaoBalance
     * - Pay with token/ether
     * - Withdraw ether/token instanly or use as vault
     * - Discount logic
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
    // Used for tracking user discounts
    mapping(address => mapping(address => uint256)) public userDiscounts;
    // Used for tracking users payments
    // Dao registration address  => user address => last payment
    mapping(address => mapping(address => uint256)) public lastPayment;

    /**
     * @notice Registers a new DAO with the given details.
     *
     * @dev This function can only be called once per DAO; subsequent calls will revert.
     * Ensures that the vault address matches the sender address to maintain secure registrations.
     *
     * @param registrationDetails The details of the DAO to register, including the vault address which should match the sender's address.
     *
     * This function does not return a value; it reverts if the DAO cannot be registered.
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

        // Check if user has discount
        if (userDiscounts[selectedDao][msg.sender] > 0) {
            require(
                msg.value >=
                    daoDetails[selectedDao].price -
                        userDiscounts[selectedDao][msg.sender],
                "Insufficient payment"
            );
        } else {
            require(
                msg.value >= daoDetails[selectedDao].price,
                "Insufficient payment"
            );
        }
        require(
            msg.value >= daoDetails[selectedDao].price,
            "Insufficient payment"
        );

        makeAnyPayment(
            selectedDao,
            msg.value,
            daoDetails[selectedDao].isBalanceLocked
        );
        lastPayment[selectedDao][msg.sender] = block.timestamp;
    }

    /**
     * @notice Retrieves the user status from a specific DAO.
     *
     * @dev The function considers a user as active if the sum of the last payment time and the DAO period is greater than the current block timestamp. It returns 1 for active users and 0 for inactive users.
     *
     * @param user The address of the user whose status is to be retrieved.
     * @param dao The address of the DAO from which to retrieve the user's status.
     *
     * @return uint256 The user status: 1 for active users and 0 for inactive users.
     */
    function getUser(address user, address dao) public view returns (uint256) {
        return
            lastPayment[dao][user] + daoDetails[dao].period < block.timestamp
                ? 0
                : 1;
    }

    /**
     * @notice Updates the registration status of the caller's DAO.
     *
     * @dev The function can only be called by a registered DAO; otherwise, it reverts with a "Dao not registered" error message. It uses the `nonReentrant` modifier to prevent reentrancy attacks.
     *
     * @param status The new registration status to be set for the DAO.
     *
     * This function doesn't return a value; it updates the state of a DAO registration status.
     */
    function changeRegistration(RegistrationStatus status) public nonReentrant {
        require(
            daoDetails[msg.sender].vault != address(0),
            "Dao not registered"
        );

        daoDetails[msg.sender].registrationStatus = status;
    }

    /**
     * @notice Updates the price parameter of the caller's DAO.
     *
     * @dev Can only be called by registered DAOs; it will revert with a "DAO not registered" error message if called by an unregistered DAO. It uses the `nonReentrant` modifier to prevent reentrancy attacks.
     *
     * @param newPrice The new price value to be set for the DAO.
     */
    function changePrice(uint256 newPrice) public nonReentrant {
        require(
            daoDetails[msg.sender].vault != address(0),
            "Dao not registered"
        );

        daoDetails[msg.sender].price = newPrice;
    }

    /**
     * @notice Updates the period parameter of the caller's DAO.
     *
     * @dev Can only be called by registered DAOs; it will revert with a "DAO not registered" error message if called by an unregistered DAO. It uses the `nonReentrant` modifier to prevent reentrancy attacks.
     *
     * @param newPeriod The new period value to be set for the DAO.
     */
    function changePeriod(uint256 newPeriod) public nonReentrant {
        require(
            daoDetails[msg.sender].vault != address(0),
            "Dao not registered"
        );

        daoDetails[msg.sender].period = newPeriod;
    }

    /**
     * @notice Sets a new discount value for a specified contributor in the caller's DAO.
     *
     * @dev Can only be called by registered DAOs; it will revert with a "DAO not registered" error message if the DAO is not registered. Moreover, it ensures the discount does not exceed the current DAO price, reverting with a "Can't apply discount more than price" error if it does. Utilizes the `nonReentrant` modifier to prevent reentrancy attacks.
     *
     * @param contributer The address of the contributor for whom the discount is being set.
     * @param newDiscount The new discount value to be applied to the contributor; it should be less than or equal to the DAO's current price.
     */
    function applyDiscount(
        address contributer,
        uint256 newDiscount
    ) public nonReentrant {
        require(
            daoDetails[msg.sender].vault != address(0),
            "Dao not registered"
        );
        require(
            daoDetails[msg.sender].price >= newDiscount,
            "Can't apply discount more then price"
        );
        userDiscounts[msg.sender][contributer] = newDiscount;
    }

    /**
     * @notice Retrieves the expiration timestamp for a specific user in a given DAO.
     *
     * @dev Calculates the expiration timestamp by adding the DAO's period to the user's last payment timestamp.
     *
     * @param user The address of the user whose expiration timestamp is to be retrieved.
     * @param dao The address of the DAO from which to retrieve the expiration timestamp.
     *
     * @return uint256 The expiration timestamp for the user in the specified DAO.
     */
    function getUserExpiration(
        address user,
        address dao
    ) public view returns (uint256) {
        return lastPayment[dao][user] + daoDetails[dao].period;
    }

    /**
     * @notice Allows the DAO to withdraw its entire balance.
     *
     * @dev The function can only be called by a registered DAO where the vault address matches the sender's address. It will revert if there is no balance to withdraw or if the DAO is not registered or if the vault address does not match the sender's address. The function uses the `nonReentrant` modifier to prevent reentrancy attacks.
     *
     * Note that this function sets the DAO's balance to zero before attempting the transfer, resulting in a permanent loss of all funds if the transfer fails.
     *
     */
    function withdrawDaoBalance() public nonReentrant {
        require(
            daoDetails[msg.sender].vault != address(0),
            "Dao not registered"
        );
        require(
            daoDetails[msg.sender].vault == msg.sender,
            "Vault can't be different from sender"
        );
        require(daoBalances[msg.sender] > 0, "No balance to withdraw");
        daoBalances[msg.sender] = 0;
        daoDetails[msg.sender].vault.transfer(daoBalances[msg.sender]);
    }

    /**
     * @notice Handles payments, with a discount applied, either to the DAO's vault or the contract itself based on the `isLocked` parameter.
     *
     * @dev A private function that carries out payment transfers, handling both Ether and ERC20 token payments. If the payment is in tokens, it leverages the ERC20 `transferFrom` method to transfer tokens from the sender to the recipient, applying any user-specific discount. It resets the user's discount to zero after the payment. If the token transfer fails, it reverts with a "Transfer failed" error message.
     *
     * @param dao The address of the DAO involved in the transaction.
     * @param amount The original payment amount before any discount is applied.
     * @param isLocked Determines the recipient of the payment: if true, the payment goes to the DAO's vault; if false, it goes to this contract's address.
     */
    function makeAnyPayment(
        address dao,
        uint256 amount,
        bool isLocked
    ) private nonReentrant {
        address payable to_address = isLocked
            ? daoDetails[dao].vault
            : payable(address(this));

        if (daoDetails[dao].paymentType == PaymentType.Ether) {
            to_address.transfer(amount - userDiscounts[dao][msg.sender]);
        } else {
            require(daoDetails[dao].paymentContract != address(0), "No token");
            IERC20 paymentToken = IERC20(daoDetails[dao].paymentContract);
            bool success = paymentToken.transferFrom(
                msg.sender,
                to_address,
                amount - userDiscounts[dao][msg.sender]
            );
            require(success, "Transfer failed");
        }

        userDiscounts[dao][msg.sender] = 0;
    }
}
