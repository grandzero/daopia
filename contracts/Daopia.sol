// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";
import "@tableland/evm/contracts/utils/SQLHelpers.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./DealStatus.sol";
contract Daopia is ReentrancyGuard, ERC721Holder {
    /*
     * Dao details :
     * Struct [...DealDetails, Period, Price, PaymentType, PaymentContract, Owner/Vault, Registration status, Discount]
     */
    /*
     * Dao => Address => LastPayment
     * Dao => Price
     *
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

    struct DealDetails{
        uint256 repair_treshold; 
        uint256 renew_treshold;
        uint256 num_copies;
    }

    struct ProposalDetails{
        address contributer;
        string cid; 
        string description;
        uint256 status;
    }

    struct DaoFrontend{
        string name;
        string description;
        string logoUrl;
        string communication;
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

    // Daos can use this to automate renewals/replications
    mapping(address => DealDetails) public dealDetails;
    // Used for tracking Dao's table ids
    uint256 public proposalsTableId;
    uint256 public proposalCounter;
    address private owner;
    DealStatus public dealStatus;
    string private constant _TABLE_PREFIX = "daopia";
    DaoFrontend[] public daoFrontends;

    
    /**
    * @notice Creates a new table in the TablelandDeployments contract with a specific schema to hold DAO proposals.
    *
    * @dev A private function that initializes a new table through the TablelandDeployments contract, with columns to store details about proposals including the contributor address, DAO address, content identifier, description, and approval status. The created table will be identified using `daoTableId`.
    */
    function crateProposalTable() private {
        proposalsTableId = TablelandDeployments.get().create(
            address(this),
            SQLHelpers.toCreateFromSchema(
                "id integer primary key,"
                "contributer text," // Notice the trailing comma
                "dao text,"
                "cid text,"
                "description text,"
                "status integer",
                _TABLE_PREFIX
            )
            
        );
    }

    constructor() {
        owner = msg.sender;
        dealStatus = new DealStatus();
        crateProposalTable();
    }


    /**
    * @notice Inserts proposal details into the proposals table created in the TablelandDeployments contract.
    *
    * @dev A private function that stores a new proposal's details into the DAO's proposal table, using the TablelandDeployments contract to facilitate the insert operation with specified details.
    *
    * @param details A struct containing the details of the proposal to be inserted, including contributor address, content identifier (cid), description, and approval status.
    * @param dao The address of the DAO to which the proposal is being made.
    */
    function insertProposalTable(ProposalDetails memory details, address dao) private{
        string memory status = SQLHelpers.quote(Strings.toString(details.status));
        TablelandDeployments.get().mutate(
            address(this),
            proposalsTableId,
            SQLHelpers.toInsert(
                _TABLE_PREFIX,
                proposalsTableId,
                "id,contributer,dao,cid,description,status",
                string.concat(
                    SQLHelpers.quote(Strings.toString(++proposalCounter)),
                     ",",
                    SQLHelpers.quote(Strings.toHexString(details.contributer)),
                    ",",
                    SQLHelpers.quote(Strings.toHexString(dao)),
                    ",",
                    SQLHelpers.quote(details.cid),
                    ",",
                    SQLHelpers.quote(details.description),
                    ",",
                    status
                )
            )
        );
    }
    /**
    * @notice Updates the proposal details in the proposals table of the TablelandDeployments contract, setting the "approved" field to true.
    *
    * @dev A private function that updates the approval status of proposals associated with a specific DAO in the proposals table. It constructs an SQL update query using SQLHelpers to set the "approved" column to true for the matching DAO address. The function operates on the table identified by `proposalsTableId`.
    *
    * @param id The address of the DAO to which the proposal pertains.
    * @param dao The address of the DAO to which the proposal pertains.
    */
    
    function approveProposalTable(uint256 id, address dao) private{
        uint256 _tableId = proposalsTableId;
        string memory setters = string.concat(
            "status=",
            SQLHelpers.quote("1") // Wrap strings in single quotes
        );
        // Only update the row with the matching `id`
        string memory filters = string.concat("id=", SQLHelpers.quote(Strings.toString(id)),"AND ", "dao=", SQLHelpers.quote(Strings.toHexString(dao)));
        /*  Under the hood, SQL helpers formulates:
         *
         *  UPDATE {prefix}_{chainId}_{tableId} SET val=<myVal> WHERE id=<id>
         */
        TablelandDeployments.get().mutate(
            address(this),
            _tableId,
            SQLHelpers.toUpdate(_TABLE_PREFIX, _tableId, setters, filters)
        );
    }

     /**
    * @notice Updates the proposal details in the proposals table of the TablelandDeployments contract, setting the "approved" field to true.
    *
    * @dev A private function that updates the approval status of proposals associated with a specific DAO in the proposals table. It constructs an SQL update query using SQLHelpers to set the "approved" column to true for the matching DAO address. The function operates on the table identified by `proposalsTableId`.
    *
    * @param dao The address of the DAO to which the proposal pertains.
    * @param cid The content identifier of the proposal to be approved.
    * @param id The id of the proposal to be approved.
    */
    function changeCidOnProposalTable(address dao, string memory cid, uint256 id) external{
        require(msg.sender == owner, "Only owner can change cid");
        uint256 _tableId = proposalsTableId;
        string memory setters = string.concat(
            "cid=",
            SQLHelpers.quote(cid) // Wrap strings in single quotes
        );
        // Only update the row with the matching `id`
         string memory filters = string.concat("id=", SQLHelpers.quote(Strings.toString(id)),"AND ", "dao=", SQLHelpers.quote(Strings.toHexString(dao)));
        /*  Under the hood, SQL helpers formulates:
         *
         *  UPDATE {prefix}_{chainId}_{tableId} SET val=<myVal> WHERE id=<id>
         */
        TablelandDeployments.get().mutate(
            address(this),
            _tableId,
            SQLHelpers.toUpdate(_TABLE_PREFIX, _tableId, setters, filters)
        );
    }


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
        DaoDetails memory registrationDetails,
        DealDetails memory details,
        DaoFrontend memory frontend
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
        require(details.num_copies <=3 , "Max 3 copies allowed");
        dealDetails[msg.sender] = details;
        daoFrontends.push(frontend);
    }

    /**
    * @notice Allows the caller to update the details of their DAO in the contract's storage.
    *
    * @dev A public function that enables the sender to update the details associated with their DAO. It requires that the DAO is already registered, i.e., the vault address is not the zero address. The details are passed in as a DaoDetails struct, and are stored in the mapping directly, overwriting the existing details.
    *
    * @param details A struct holding the new details to update for the DAO associated with the message sender.
    */
    function changeDaoDetails(DaoDetails memory details) public{
        require(
            daoDetails[msg.sender].vault != address(0),
            "Dao not registered"
        );
        daoDetails[msg.sender] = details;
    }

    function getDaoList() public view returns(DaoFrontend[] memory){
        DaoFrontend[] memory daoArray = new DaoFrontend[](daoFrontends.length);
        for (uint i = 0; i < daoFrontends.length; i++) {
            daoArray[i] = daoFrontends[i];
        }
        return daoArray;
    }



    /**
    * @notice Facilitates payment to a selected DAO, accounting for any applicable user discounts.
    *
    * @dev A public function that requires the selected DAO to be registered and open for registration. It checks if the user has any discount and adjusts the required payment accordingly. The function also calls `makeAnyPayment` to handle the actual payment transfer, passing in the DAO's lock status for the balance. Finally, it updates the last payment timestamp for the user in context of the selected DAO. It uses the `nonReentrant` modifier to prevent reentrancy attacks.
    *
    * @param selectedDao The address of the DAO to which the payment is being made.
    */
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
    ) private {
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

    /**
     * @notice Allows a user to make a proposal to a DAO by providing necessary details including a content identifier and a description.
     *
     * @dev The function can only be called when the DAO is registered and has a registration status of "Permissioned". It interacts with an external contract `TablelandDeployments` to mutate a data table with the proposal details. It uses the `nonReentrant` modifier to prevent reentrancy attacks. The function reverts with appropriate error messages if the DAO is not registered or if the DAO registration status is not "Permissioned".
     *
     * @param dao The address of the DAO where the proposal is being made.
    
     * @param description A descriptive text providing details about the proposal.
     */
    function makeProposalToDao(
        address dao,
        string memory description
    ) public nonReentrant {
        require(daoDetails[dao].vault != address(0), "Dao not registered");
        require(
            daoDetails[dao].registrationStatus ==
                RegistrationStatus.Open,
            "Dao registration closed"
        );
       insertProposalTable(ProposalDetails(msg.sender, "cid", description, 0), dao);
    }

    /**
     * @notice Allows the approval of a specific proposal in a DAO.
     *
     * @dev The function can be invoked only when the DAO is registered and its registration status is "Permissioned". It updates the proposal's approval status in the DAO's associated table in the TablelandDeployments contract. The function uses the `nonReentrant` modifier to prevent reentrancy attacks and reverts with error messages if the DAO is not registered or if it is not in the "Permissioned" registration status.
     *
     */
    function approveProposal(string memory _cid, uint256 id, uint256 jobType) public nonReentrant {
        address dao = msg.sender;
        require(daoDetails[dao].vault != address(0), "Dao not registered");
        require(
            daoDetails[dao].registrationStatus ==
                RegistrationStatus.Open,
            "Dao registration closed"
        );
        require(daoDetails[dao].vault == msg.sender, "Only dao can approve");
        approveProposalTable(id,dao);
        dealStatus.approvedByDao(bytes(_cid),jobType, dao);
    }

     receive() external payable{}
}
