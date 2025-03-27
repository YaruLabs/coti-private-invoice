// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@coti-io/coti-contracts/contracts/utils/mpc/MpcCore.sol";

/**
 * @title PrivateInvoicing
 * @dev A privacy-focused invoicing system using COTI's MPC technology
 * @notice This contract allows businesses to create invoices with encrypted details
 */
contract PrivateInvoicing {
    // Invoice status enum
    enum InvoiceStatus { Pending, Paid, Late }
    
    // Invoice structure with encrypted fields
    struct Invoice {
        bytes32 id;
        address sender;
        address recipient;
        utString encryptedAmount;    // Private amount using COTI's privacy types
        utString encryptedDueDate;   // Private due date
        utString encryptedNotes;     // Private notes
        uint256 createdAt;
        InvoiceStatus status;
        bool exists;
    }
    
    // Mapping from invoice ID to Invoice
    mapping(bytes32 => Invoice) private invoices;
    
    // Mapping from address to array of invoice IDs (sent)
    mapping(address => bytes32[]) private sentInvoices;
    
    // Mapping from address to array of invoice IDs (received)
    mapping(address => bytes32[]) private receivedInvoices;
    
    // Events
    event InvoiceCreated(bytes32 indexed id, address indexed sender, address indexed recipient);
    event InvoicePaid(bytes32 indexed id, address indexed payer);
    event InvoiceMarkedLate(bytes32 indexed id);
    
    /**
     * @dev Create a new invoice with encrypted data
     * @param recipient The address of the invoice recipient
     * @param amountValue The encrypted amount value
     * @param dueDateValue The encrypted due date value
     * @param notesValue The encrypted notes value
     * @return id The ID of the created invoice
     */
    function createInvoice(
        address recipient, 
        itString calldata amountValue,
        itString calldata dueDateValue,
        itString calldata notesValue
    ) external returns (bytes32) {
        require(recipient != address(0), "Invalid recipient address");
        require(recipient != msg.sender, "Cannot send invoice to yourself");
        
        // Validate and process the encrypted inputs
        gtString memory amount = MpcCore.validateCiphertext(amountValue);
        gtString memory dueDate = MpcCore.validateCiphertext(dueDateValue);
        gtString memory notes = MpcCore.validateCiphertext(notesValue);
        
        // Generate a unique invoice ID
        bytes32 invoiceId = keccak256(abi.encodePacked(
            msg.sender,
            recipient,
            block.timestamp,
            block.number
        ));
        
        // Ensure invoice ID is unique
        require(!invoices[invoiceId].exists, "Invoice ID collision, please try again");
        
        // Create and store the invoice with encrypted data
        Invoice storage newInvoice = invoices[invoiceId];
        newInvoice.id = invoiceId;
        newInvoice.sender = msg.sender;
        newInvoice.recipient = recipient;
        newInvoice.encryptedAmount = MpcCore.offBoardCombined(amount, msg.sender);
        newInvoice.encryptedDueDate = MpcCore.offBoardCombined(dueDate, msg.sender);
        newInvoice.encryptedNotes = MpcCore.offBoardCombined(notes, msg.sender);
        newInvoice.createdAt = block.timestamp;
        newInvoice.status = InvoiceStatus.Pending;
        newInvoice.exists = true;
        
        // Add to sender's and recipient's invoice lists
        sentInvoices[msg.sender].push(invoiceId);
        receivedInvoices[recipient].push(invoiceId);
        
        // Emit event
        emit InvoiceCreated(invoiceId, msg.sender, recipient);
        
        return invoiceId;
    }    
    
    /**
     * @dev Pay an invoice
     * @param invoiceId The ID of the invoice to pay
     */
    function payInvoice(bytes32 invoiceId) external payable {
        Invoice storage invoice = invoices[invoiceId];

        // Validate invoice
        require(invoice.exists, "Invoice does not exist");
        require(invoice.recipient == msg.sender, "Only the recipient can pay this invoice");
        require(invoice.status == InvoiceStatus.Pending, "Invoice is not in pending status");

        // Update invoice status
        invoice.status = InvoiceStatus.Paid;

        // Transfer payment to the sender
        (bool success, ) = invoice.sender.call{value: msg.value}("");
        require(success, "Payment transfer failed");
        
        // Emit event
        emit InvoicePaid(invoiceId, msg.sender);
    }
    
    /**
     * @dev Mark an invoice as late (can only be called by the sender)
     * @param invoiceId The ID of the invoice to mark as late
     */
    function markInvoiceLate(bytes32 invoiceId) external {
        Invoice storage invoice = invoices[invoiceId];
        
        // Validate invoice
        require(invoice.exists, "Invoice does not exist");
        require(invoice.sender == msg.sender, "Only the sender can mark this invoice as late");
        require(invoice.status == InvoiceStatus.Pending, "Invoice is not in pending status");
        
        // Update invoice status
        invoice.status = InvoiceStatus.Late;
        
        // Emit event
        emit InvoiceMarkedLate(invoiceId);
    }
    
    /**
     * @dev Get invoice details
     * @param invoiceId The ID of the invoice to retrieve
     * @return sender The address of the invoice sender
     * @return recipient The address of the invoice recipient
     * @return amountCiphertext The encrypted amount (only decryptable by sender/recipient)
     * @return dueDateCiphertext The encrypted due date (only decryptable by sender/recipient)
     * @return notesCiphertext The encrypted notes (only decryptable by sender/recipient)
     * @return createdAt The timestamp when the invoice was created
     * @return status The current status of the invoice
     */
    function getInvoice(bytes32 invoiceId) external view returns (
        address sender,
        address recipient,
        ctString memory amountCiphertext,
        ctString memory dueDateCiphertext,
        ctString memory notesCiphertext,
        uint256 createdAt,
        InvoiceStatus status
    ) {
        Invoice storage invoice = invoices[invoiceId];
        require(invoice.exists, "Invoice does not exist");
        
        // Only sender or recipient can view the invoice
        require(
            invoice.sender == msg.sender || invoice.recipient == msg.sender,
            "Not authorized to view this invoice"
        );
        
        return (
            invoice.sender,
            invoice.recipient,
            invoice.encryptedAmount.userCiphertext,
            invoice.encryptedDueDate.userCiphertext,
            invoice.encryptedNotes.userCiphertext,
            invoice.createdAt,
            invoice.status
        );
    }
    
    /**
     * @dev Get all invoice IDs sent by the caller
     * @return Array of invoice IDs
     */
    function getSentInvoices() external view returns (bytes32[] memory) {
        return sentInvoices[msg.sender];
    }
    
    /**
     * @dev Get all invoice IDs received by the caller
     * @return Array of invoice IDs
     */
    function getReceivedInvoices() external view returns (bytes32[] memory) {
        return receivedInvoices[msg.sender];
    }
}