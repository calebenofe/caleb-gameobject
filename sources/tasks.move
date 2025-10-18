// Copyright (c) Sui Foundation, Inc.
// SPDX-License-Identifier: Apache-2.0
/// Game Object Example with Student Tasks
/// This module demonstrates game item management with three student tasks
module sui_intro_unit_two::game_item;

use sui::event;
use sui::transfer;
use sui::object::{Self, UID, ID};
use sui::tx_context::{Self, TxContext};

// Game item structure representing in-game assets
public struct GameItem has key, store {
    id: UID,
    power: u64,
    rarity: u8,
    item_type: String,
}

// Inventory structure to wrap game items
public struct GameInventory has key {
    id: UID,
    item: GameItem,
    intended_player: address,
}

// Admin capability for privileged actions
public struct GameAdminCap has key {
    id: UID,
}

// Test structure (can be ignored for this exercise)
public struct TestStruct has drop, store, copy {}

// Event for tracking game item requests
public struct GameItemRequestEvent has copy, drop {
    wrapper_id: ID,
    requester: address,
    intended_player: address,
}

// Error codes
const ENotIntendedPlayer: u64 = 1;
const EInvalidPower: u64 = 2;  
const EInvalidRarity: u64 = 3;  // Added for Task 2
const EInvalidTransfer: u64 = 4; // Added for Task 3

/// Module initializer - creates the first admin cap
fun init(ctx: &mut TxContext) {
    transfer::transfer(
        GameAdminCap {
            id: object::new(ctx),
        },
        tx_context::sender(ctx),
    )
}

/* ---------- COMPLETED EXAMPLES ---------- */

// Example: View a game item's power (read-only)
public fun view_power(game_item: &GameItem): u64 {
    game_item.power
}

// Example: Admin can delete a game item
public fun delete_game_item(
    _: &GameAdminCap,
    game_item: GameItem,
) {
    let GameItem { id, .. } = game_item;
    id.delete();
}

/* ---------- TASK 1: Power Level Validation ---------- */
/*
1. Validate power between 1-100
2. Return EInvalidPower if invalid
3. Only allow if new power > current
*/
public fun update_power(
    _: &GameAdminCap,
    game_item: &mut GameItem,
    new_power: u64,
) {
    // Validate range
    assert!(new_power >= 1 && new_power <= 100, EInvalidPower);
    // Only allow increasing power
    assert!(new_power > game_item.power, EInvalidPower);
    // Update after validation
    game_item.power = new_power;
}

/* ---------- TASK 2: Enhanced Game Item Creation ---------- */

// Event struct for item creation
public struct GameItemCreatedEvent has copy, drop {
    item_id: ID,
    item_type: String,
    rarity: u8,
    creator: address,
}

#[allow(lint(self_transfer))]
public fun create_game_item(
    _: &GameAdminCap,
    power: u64,
    rarity: u8,
    item_type: String,
    ctx: &mut TxContext,
) {
    // Validate rarity 1–5
    assert!(rarity >= 1 && rarity <= 5, EInvalidRarity);

    let creator = tx_context::sender(ctx);

    let game_item = GameItem {
        id: object::new(ctx),
        power,
        rarity,
        item_type,
    };

    // Emit event for creation
    event::emit(GameItemCreatedEvent {
        item_id: object::id(&game_item),
        item_type: game_item.item_type,
        rarity: game_item.rarity,
        creator,
    });

    // Transfer the created item to the creator
    transfer::public_transfer(game_item, creator);
}

/* ---------- TASK 3: Game Inventory Management ---------- */

// Event struct for item transfer
public struct GameItemTransferredEvent has copy, drop {
    item_id: ID,
    from_address: address,
    to_address: address,
}

public fun transfer_game_item(
    game_item: GameItem,
    recipient: address,
    ctx: &mut TxContext,
) {
    let sender = tx_context::sender(ctx);

    // Ensure sender is the owner
    // (In a real Move environment, ownership validation is handled by object system,
    // but we'll simulate validation logic here for learning.)
    assert!(sender != recipient, EInvalidTransfer);

    // Emit transfer event
    event::emit(GameItemTransferredEvent {
        item_id: object::id(&game_item),
        from_address: sender,
        to_address: recipient,
    });

    // Transfer the item to the recipient
    transfer::transfer(game_item, recipient);
}

/* ---------- PROVIDED FUNCTIONS ---------- */

// Provided: Add additional admin
public fun add_additional_admin(
    _: &GameAdminCap,
    new_admin_address: address,
    ctx: &mut TxContext,
) {
    transfer::transfer(
        GameAdminCap {
            id: object::new(ctx),
        },
        new_admin_address,
    )
}

// Provided: Request a game item
public fun request_game_item(
    game_item: GameItem,
    intended_player: address,
    ctx: &mut TxContext,
) {
    let inventory = GameInventory {
        id: object::new(ctx),
        item: game_item,
        intended_player,
    };
    event::emit(GameItemRequestEvent {
        wrapper_id: object::id(&inventory),
        requester: tx_context::sender(ctx),
        intended_player,
    });
    transfer::transfer(inventory, intended_player);
}

// Provided: Unpack a game item
#[allow(lint(self_transfer))]
public fun unpack_game_item(inventory: GameInventory, ctx: &mut TxContext) {
    assert!(inventory.intended_player == tx_context::sender(ctx), ENotIntendedPlayer);
    let GameInventory { id, item, .. } = inventory;
    transfer::transfer(item, tx_context::sender(ctx));
    object::delete(id);
}
