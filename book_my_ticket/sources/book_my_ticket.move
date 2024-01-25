module TicketProject::BookMyTicket {

    // Importing required modules
    use std::string::{Self, String};
    use std::vector;
    use std::debug::print;
    use std::string::utf8;
    use sui::table::{Self, Table};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::ed25519;
    use sui::event::emit;
    use sui::vec_map::{Self, VecMap};
    use TicketProjectToken::ticket_token::{TICKET_TOKEN,Check};

    // Error constants
    /// Error code for invalid claimable amount.
    const EINVALID_CLAIMABLE_AMOUNT: u64 = 1;

    /// Error code for invalid length.
    const EINVALID_LENGTH: u64 = 3;

    /// Error code for exceeding the ticket limit.
    const ETICKET_LIMIT_EXCEED: u64 = 4;

    /// Error code for invalid ticket type.
    const EINVALID_TICKET_TYPE: u64 = 5;

    /// Error code for insufficient amount.
    const EINSUFFICIENT_AMOUNT: u64 = 6;

    /// Error code for invalid signature.
    const EINVALID_SIGNATURE: u64 = 7;

    /// Error code for user already being blacklisted.
    const EUSER_ALREADY_BLACKLISTED: u64 = 8;

    /// Error code for user not being blocked when expected.
    const EUSER_NOT_BLOCKED: u64 = 9;

    /// Error code for user being blacklisted when not expected.
    const EUSER_BLACKLISTED: u64 = 10;


    /// Struct representing the owner capabilities
    struct OwnerCap has key, store {
        id: UID,
    }

    /// Struct representing the details of the BookMyTicket platform
    struct BmtPlatformDetails has key, store {
        id: UID,
        owner: address,
        sig_verify_pk: vector<u8>,
        platform_fee: u64,
        profit: Balance<TICKET_TOKEN>,
        user_tickets: Table<address, vector<UserTicketInfo>>,
        ticket_types: VecMap<String, u64>,
        user_blacklist: Table<address, bool>,
        current_ticket_index: u64,
        claim_nonce: u64,
        max_ticket_per_person: u64,
    }

    /// Struct representing a non-fungible ticket (NFT)s
    struct TicketNFT has key, store {
        id: UID,
        ticket_type: String,
        description: vector<u8>,
        ticket_id: u64,
        ticket_claimed: bool,
    }

    /// Struct representing ticket information for a user
    struct UserTicketInfo has copy, drop, store {
        ticket_owner: address,
        ticket_id: u64,
        ticket_type: String,
        amount: u64,
    }

    /// Event emitted when the BookMyTicket platform is initialized.
    struct PlatformInitializedEvent has copy, drop {
        owner: address,
        platform_fee: u64,          
        max_ticket_per_person: u64, 
    }

    /// Event emitted when profits are claimed on the BookMyTicket platform.
    struct ProfitClaimedEvent has copy, drop {
        claimed_address: address,   
        claimed_amount: u64,        
    }

    /// Event emitted when a new ticket type is added on the BookMyTicket platform.
    struct TicketTypeAddedEvent has copy, drop {
        ticket_type: String,        
        ticket_price: u64,          
    }

    /// Event emitted when a ticket is claimed on the BookMyTicket platform.
    struct TicketClaimedEvent has copy, drop {
        ticket_type: String,        
        ticket_id: u64,             
        description: vector<u8>,    
        ticket_claimed: bool,       
    }

    /// Event emitted when a user is blocked or unblocked on the BookMyTicket platform.
    struct BlockUserEvent has copy, drop {
        user_addr: address,         
        Blocked: bool,              
    }

    /// Event emitted when the owner of the BookMyTicket platform is changed.
    struct OwnerChangeEvent has copy, drop {
        old_owner: address,       
        new_owner: address,        
    }

    /// Event emitted when a ticket type is removed from the BookMyTicket platform.
    struct TicketTypeRemovedEvent has copy, drop {
        ticket_type: String,        
        ticket_price: u64,          
    }

    /// Event emitted when a user purchases a ticket on the BookMyTicket platform.
    struct TicketPurchasedEvent has copy, drop {
        ticket_owner: address,     
        ticket_id: u64,             
        ticket_type: String,        
    }


    struct CheckT has key  {  

        id:UID ,
        check: Check,             
             
    }




    // Initialization function for the BookMyTicket platform
    fun init(ctx: &mut TxContext) {
        // Creating initial platform details
        let platform_info = BmtPlatformDetails {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            sig_verify_pk: vector::empty<u8>(),
            platform_fee: 100000,
            profit: balance::zero<TICKET_TOKEN>(),
            user_tickets: table::new(ctx),
            ticket_types: vec_map::empty<String, u64>(),
            user_blacklist: table::new(ctx),
            current_ticket_index: 0,
            claim_nonce: 0,
            max_ticket_per_person: 5,
        };

        // Creating owner capabilities
        let owner_cap = OwnerCap {
            id: object::new(ctx),
        };

        // Transferring platform details and owner capabilities
        transfer::public_share_object(platform_info);
        transfer::public_transfer(owner_cap, tx_context::sender(ctx));

        // Emitting initialization event
        emit(PlatformInitializedEvent {
            owner: tx_context::sender(ctx),
            platform_fee: 100000,
            max_ticket_per_person: 5,
        });
    }

    public entry fun check(check : Check , ctx: &mut TxContext ){
       transfer::transfer(CheckT{
        id: object::new(ctx),
        check
       } , tx_context::sender(ctx))
    }

    // Function to claim profits on the BookMyTicket platform
    public entry fun claim_profit(
        _: &OwnerCap,
        platform_info: &mut BmtPlatformDetails,
        ticket_index: u64,
        claim_nonce: u64,
        signature: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let sender: address = tx_context::sender(ctx);

        // Verifying owner
        assert!(verify_claim_signature(ticket_index, claim_nonce, platform_info.sig_verify_pk, signature), EINVALID_SIGNATURE);

        // Checking claimable amount
        let claimable_amount: u64 = balance::value<TICKET_TOKEN>(&platform_info.profit);
        assert!(claimable_amount > 0, EINVALID_CLAIMABLE_AMOUNT);

        // Taking profits and transferring to owner
        let temp_coin: Coin<TICKET_TOKEN> = coin::take<TICKET_TOKEN>(&mut platform_info.profit, claimable_amount, ctx);
        transfer::public_transfer(temp_coin, sender);

        // Updating claim nonce
        platform_info.claim_nonce = platform_info.claim_nonce + 1;

        // Emitting profit claimed event
        emit(ProfitClaimedEvent {
            claimed_address: sender,
            claimed_amount: claimable_amount,
        });
    }

    // Function to buy tickets on the BookMyTicket platform
    public entry fun buy_tickets(platform_info: &mut BmtPlatformDetails, ticket_amount: Coin<TICKET_TOKEN>, ticket_type: String, ctx: &mut TxContext) {
        let temp_user_list: &mut Table<address, vector<UserTicketInfo>> = &mut platform_info.user_tickets;
        let temp_ticket_list: &VecMap<String, u64> = &platform_info.ticket_types;
        let black_list = &platform_info.user_blacklist;
        let token_required: u64 = *vec_map::get(temp_ticket_list, &ticket_type);
        let sender_addr: address = tx_context::sender(ctx);

        // Checking if user is blacklisted
        assert!(!table::contains(black_list, sender_addr), EUSER_BLACKLISTED);

        // Checking if ticket type is valid
        assert!(vec_map::contains(temp_ticket_list, &ticket_type), EINVALID_TICKET_TYPE);

        // Checking if user has sufficient funds
        assert!(coin::value(&ticket_amount) >= token_required, EINSUFFICIENT_AMOUNT);

        if (table::contains(temp_user_list, sender_addr)) {
            // User exists, checking ticket limit
            let user_ticket_info: &mut vector<UserTicketInfo> = table::borrow_mut(temp_user_list, sender_addr);
            assert!(vector::length(user_ticket_info) <= platform_info.max_ticket_per_person, ETICKET_LIMIT_EXCEED);
            // Purchasing tickets
            purchase_tickets(platform_info, ticket_amount, ticket_type, token_required, ctx);
        } else {
            // User doesn't exist, creating user and purchasing tickets
            table::add(temp_user_list, sender_addr, vector::empty<UserTicketInfo>());
            purchase_tickets(platform_info, ticket_amount, ticket_type, token_required, ctx);
        }
    }

    // Function to handle the actual purchase of tickets
    fun purchase_tickets(platform_info: &mut BmtPlatformDetails, ticket_amount: Coin<TICKET_TOKEN>, ticket_type: String, token_required: u64, ctx: &mut TxContext) {
        let paid_amount = coin::value(&ticket_amount);
        let paid_balance: Balance<TICKET_TOKEN> = coin::into_balance(ticket_amount);
        let sender_addr: address = tx_context::sender(ctx);
        let user_ticket_info: &mut vector<UserTicketInfo> = table::borrow_mut(&mut platform_info.user_tickets, sender_addr);

        // Calculating tokens to return
        let token_to_return: Coin<TICKET_TOKEN> = coin::take(&mut paid_balance, paid_amount - token_required, ctx);
        // Transferring tokens to user
        transfer::public_transfer(token_to_return, sender_addr);

        // Adding paid balance to platform profit
        balance::join(&mut platform_info.profit, paid_balance);

        // Updating current ticket index
        platform_info.current_ticket_index = platform_info.current_ticket_index + 1;

        // Creating and transferring ticket NFT
        transfer::public_transfer(TicketNFT {
            id: object::new(ctx),
            ticket_type,
            description: b"Example",
            ticket_id: platform_info.current_ticket_index,
            ticket_claimed: false,
        }, sender_addr);

        // Adding purchased ticket information
        vector::push_back(user_ticket_info, UserTicketInfo {
            ticket_owner: sender_addr,
            ticket_id: platform_info.current_ticket_index,
            ticket_type,
            amount: paid_amount,
        });

        // Emitting ticket purchased event
        emit(TicketPurchasedEvent {
            ticket_owner: sender_addr,
            ticket_id: platform_info.current_ticket_index,
            ticket_type,
        });
    }

    // Function to claim a ticket
    public entry fun claim_ticket(self: TicketNFT, _: &mut TxContext) {
        let TicketNFT { id, ticket_type, description, ticket_id, ticket_claimed } = self;
        // Deleting the NFT object
        object::delete(id);

        // Emitting ticket claimed event
        emit(TicketClaimedEvent {
            ticket_type,
            ticket_id,
            description,
            ticket_claimed,
        });
    }

    // Function to add new ticket types
    public entry fun add_ticket_types(_: &OwnerCap, platform_info: &mut BmtPlatformDetails, ticket_type: vector<String>, ticket_price: vector<u64>, _: &mut TxContext) {
        let type_len: u64 = vector::length(&ticket_type);
        let price_len: u64 = vector::length(&ticket_price);
        assert!(type_len == price_len, EINVALID_LENGTH);

        let temp_ticket_type: &mut VecMap<String, u64> = &mut platform_info.ticket_types;

        // Adding new ticket types
        while (!vector::is_empty(&ticket_type)) {
            let ticket_type: String = vector::pop_back(&mut ticket_type);
            let ticket_price: u64 = vector::pop_back(&mut ticket_price);

            emit(TicketTypeAddedEvent {
                ticket_type,
                ticket_price,
            });

            vec_map::insert(temp_ticket_type, ticket_type, ticket_price);
        }
    }

    // Function to remove ticket types
    public entry fun remove_ticket_type(_: &OwnerCap, platform_info: &mut BmtPlatformDetails, ticket_type: vector<String>, _: &mut TxContext) {
        let type_len: u64 = vector::length(&ticket_type);
        assert!(type_len > 0, EINVALID_LENGTH);

        let temp_ticket_type: &mut VecMap<String, u64> = &mut platform_info.ticket_types;

        // Removing ticket types
        while (!vector::is_empty(&ticket_type)) {
            let ticket_type: String = vector::pop_back(&mut ticket_type);

            let (ticket_type, ticket_price) = vec_map::remove(temp_ticket_type, &ticket_type);

            emit(TicketTypeRemovedEvent {
                ticket_type,
                ticket_price,
            });
        }
    }

    // Function to get all ticket types
    public entry fun get_all_ticket_types(platform_info: &mut BmtPlatformDetails) : (vector<String>, vector<u64>) {
        let stored_ticket_types: &VecMap<String, u64> = &platform_info.ticket_types;
        let ticket_type_size: u64 = vec_map::size(stored_ticket_types);
        let ticket_types: vector<String> = vector::empty<String>();
        let ticket_price: vector<u64> = vector::empty<u64>();
        let i = 0;

        // Iterating through ticket types
        while (i < ticket_type_size) {
            let (types_temp, price_temp) = vec_map::get_entry_by_idx(stored_ticket_types, i);

            vector::push_back(&mut ticket_types, *types_temp);
            vector::push_back(&mut ticket_price, *price_temp);

            i = i + 1;
        };

        (ticket_types, ticket_price)
    }

    // Function to set the verification public key
    public entry fun set_verify_pk(
        _: &OwnerCap,
        platform_info: &mut BmtPlatformDetails,
        verify_pk_str: String,
    ) {
        platform_info.sig_verify_pk = sui::hex::decode(*string::bytes(&verify_pk_str));
    }

    /// Verifies the signature for claiming profits on the BookMyTicket platform.
    /// This function verifies the signature for claiming profits using the provided ticket index,
    /// claim nonce, verification public key, and signature.
    fun verify_claim_signature(ticket_index: u64, claim_nonce: u64, verify_pk: vector<u8>, signature: vector<u8>): bool {
        // Convert ticket index and claim nonce to bytes
        let ticket_index_bytes = std::bcs::to_bytes(&(ticket_index as u64));
        let nonce_bytes = std::bcs::to_bytes(&(claim_nonce as u64));

        // Append nonce bytes to ticket index bytes
        vector::append(&mut ticket_index_bytes, nonce_bytes);

        // Verify the signature using ed25519
        let verify = ed25519::ed25519_verify(
            &signature, 
            &verify_pk, 
            &ticket_index_bytes
        );

        verify
    }

    /// Blocks a user on the BookMyTicket platform.
    /// This function adds the provided user address to the blacklist, preventing them from buying tickets.
    public entry fun block_user(_: &OwnerCap, platform_info: &mut BmtPlatformDetails, user_addr: address) {
        let black_list = &mut platform_info.user_blacklist;

        // Ensure the user is not already blacklisted
        assert!(!table::contains(black_list, user_addr), EUSER_ALREADY_BLACKLISTED);

        // Add the user to the blacklist
        table::add(black_list, user_addr, true);

        // Emit BlockUserEvent
        emit(BlockUserEvent {
            user_addr: user_addr,
            Blocked: true
        });
    }

    /// Unblocks a user on the BookMyTicket platform.
    /// This function removes the provided user address from the blacklist, allowing them to buy tickets.
    public entry fun unblock_user(_: &OwnerCap, platform_info: &mut BmtPlatformDetails, user_addr: address) {
        let black_list = &mut platform_info.user_blacklist;

        // Ensure the user is already blacklisted
        assert!(table::contains(black_list, user_addr), EUSER_NOT_BLOCKED);

        // Remove the user from the blacklist
        table::remove(black_list, user_addr);

        // Emit BlockUserEvent
        emit(BlockUserEvent {
            user_addr: user_addr,
            Blocked: false
        });
    }

    /// Changes the owner of the BookMyTicket platform.
    /// This function updates the owner address and transfers ownership using a public transfer.
    public entry fun change_owner(owner_cap: OwnerCap, platform_info: &mut BmtPlatformDetails, new_owner: address, ctx: &mut TxContext) {
        // Update the owner address
        platform_info.owner = new_owner;

        // Transfer ownership
        transfer::public_transfer(owner_cap, new_owner);

        // Emit OwnerChangeEvent
        emit(OwnerChangeEvent {
            old_owner: tx_context::sender(ctx),
            new_owner: new_owner
        });
    }


    // public entry fun add_admin(owner_cap : &mut OwnerCap , admin_addr:address , type: bool){
    //     vec_map::insert(&mut owner_cap.list_of_admins , admin_addr , type);
    //     emit(AdminAddedEvent{
    //         admin_addr
    //     })

    // }

// #[test]

// public fun test_check(){

//          use sui::test_scenario;

//         // create test addresses representing users
//         let admin = @0xBABE;
//         let initial_owner = @0xCAFE;
//         let final_owner = @0xFACE;

//         // first transaction to emulate module initialization
//         let scenario_val = test_scenario::begin(admin);
//         let scenario = &mut scenario_val;
//          init(test_scenario::ctx(scenario));

//          add_ticket_types()
       
//         // test_scenario::next_tx(scenario, admin);
//         // {
            
//         // };

//         test_scenario::end(scenario_val);
// }

}
