# BookMyTicket Smart Contract

The BookMyTicket smart contract is designed to manage a ticket booking platform on the Move blockchain. It includes functionalities for initializing the platform, buying and claiming tickets, managing ticket types, and handling ownership changes. The contract is implemented in Move, the programming language for the Move blockchain.

## Table of Contents

1. [Introduction](#introduction)
2. [Smart Contract Components](#smart-contract-components)
    - [OwnerCap](#ownercap)
    - [BmtPlatformDetails](#bmtplatformdetails)
    - [TicketNFT](#ticketnft)
    - [UserTicketInfo](#userticketinfo)
3. [Events](#events)
4. [Error Constants](#error-constants)
5. [Initialization](#initialization)
6. [Functionalities](#functionalities)
    - [Claiming Profits](#claiming-profits)
    - [Buying Tickets](#buying-tickets)
    - [Ticket Claim](#ticket-claim)
    - [Managing Ticket Types](#managing-ticket-types)
    - [Ownership Management](#ownership-management)
7. [Testing](#testing)
8. [Usage](#usage)
9. [License](#license)

## Introduction

BookMyTicket is a decentralized ticket booking platform that leverages the Move blockchain's capabilities to ensure secure and transparent transactions. The smart contract is designed to handle ticket purchases, profit claims, and ownership changes. It provides a robust mechanism for adding, removing, and managing various ticket types.

## Smart Contract Components

### OwnerCap

The `OwnerCap` struct represents the owner's capabilities, providing a key for secure access.

### BmtPlatformDetails

The `BmtPlatformDetails` struct contains essential details about the BookMyTicket platform, such as the owner's address, platform parameters, profit information, and user-related data.

### TicketNFT

The `TicketNFT` struct represents a non-fungible ticket, including information like ticket type, description, ticket ID, and claimed status.

### UserTicketInfo

The `UserTicketInfo` struct stores information about tickets owned by a user, including the owner's address, ticket ID, ticket type, and the amount paid.

## Events

- `PlatformInitializedEvent`: Emitted when the BookMyTicket platform is initialized.
- `ProfitClaimedEvent`: Emitted when profits are claimed on the platform.
- `TicketTypeAddedEvent`: Emitted when a new ticket type is added.
- `TicketClaimedEvent`: Emitted when a ticket is claimed.
- `BlockUserEvent`: Emitted when a user is blocked or unblocked.
- `OwnerChangeEvent`: Emitted when the owner of the platform is changed.
- `TicketTypeRemovedEvent`: Emitted when a ticket type is removed.
- `TicketPurchasedEvent`: Emitted when a user purchases a ticket.

## Error Constants

- `EINVALID_CLAIMABLE_AMOUNT`: Invalid claimable amount.
- `EINVALID_LENGTH`: Invalid length.
- `ETICKET_LIMIT_EXCEED`: Exceeding the ticket limit.
- `EINVALID_TICKET_TYPE`: Invalid ticket type.
- `EINSUFFICIENT_AMOUNT`: Insufficient amount.
- `EINVALID_SIGNATURE`: Invalid signature.
- `EUSER_ALREADY_BLACKLISTED`: User already blacklisted.
- `EUSER_NOT_BLOCKED`: User not blocked when expected.
- `EUSER_BLACKLISTED`: User blacklisted when not expected.

## Initialization

The `init` function initializes the BookMyTicket platform, creating initial platform details and owner capabilities. It emits a `PlatformInitializedEvent` to signify the completion of the initialization.

## Functionalities

### Claiming Profits

The `claim_profit` function allows the owner to claim profits from the platform. It verifies the owner's signature, checks the claimable amount, transfers profits to the owner, and updates the claim nonce. It emits a `ProfitClaimedEvent` upon successful execution.

### Buying Tickets

The `buy_tickets` function enables users to buy tickets on the platform. It checks user eligibility, ticket type validity, and user funds. Users can purchase tickets, and the platform updates its profit and ticket information. It emits a `TicketPurchasedEvent` upon successful execution.

### Ticket Claim

The `claim_ticket` function allows users to claim a ticket, marking it as claimed and emitting a `TicketClaimedEvent`.

### Managing Ticket Types

Functions like `add_ticket_types`, `remove_ticket_type`, and `get_all_ticket_types` allow the owner to add, remove, and retrieve information about ticket types.

### Ownership Management

The `change_owner` function facilitates ownership changes, updating the owner's address and emitting an `OwnerChangeEvent`. Additionally, functions like `block_user` and `unblock_user` allow the owner to manage user blacklisting.



## License

This smart contract is released under the [MIT License](LICENSE). Feel free to use, modify, and distribute it as needed.
