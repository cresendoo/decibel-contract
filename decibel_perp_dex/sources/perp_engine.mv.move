module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine {
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x1::big_ordered_map;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market;
    use 0x1::string;
    use 0x1::signer;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::accounts_collateral;
    use 0x1::event;
    use 0x7::order_book_types;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::clearinghouse_perp;
    use 0x7::market_types;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine_types;
    use 0x1::option;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::async_matching_engine;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::builder_code_registry;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_management;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market_config;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::open_interest_tracker;
    use 0x1::vector;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::math;
    use 0x1::error;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::decibel_time;
    use 0x7::order_book;
    use 0x7::single_order_book;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::tp_sl_utils;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::oracle;
    use 0x1::bcs;
    use 0x7::market;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::adl_tracker;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::position_tp_sl_tracker;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::pyth;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::dex_accounts;
    struct DexRegistrationEvent has drop, store {
        dex: object::Object<object::ObjectCore>,
        collateral_asset: object::Object<fungible_asset::Metadata>,
        collateral_balance_decimals: u8,
    }
    struct Global has key {
        extend_ref: object::ExtendRef,
        market_refs: big_ordered_map::BigOrderedMap<object::Object<perp_market::PerpMarket>, object::ExtendRef>,
        is_exchange_open: bool,
    }
    struct MarketRegistrationEvent has drop, store {
        market: object::Object<perp_market::PerpMarket>,
        name: string::String,
        sz_decimals: u8,
        px_decimals: u8,
        max_leverage: u8,
        max_open_interest: u64,
        min_size: u64,
        lot_size: u64,
        ticker_size: u64,
    }
    enum PerpOrderCancelationReason {
        MaxOpenInterestViolation,
    }
    public fun collateral_balance_decimals(): u8 {
        let _t0 = accounts_collateral::collateral_balance_precision();
        math::get_decimals(&_t0)
    }
    friend fun is_exchange_open(): bool
        acquires Global
    {
        *&borrow_global<Global>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).is_exchange_open
    }
    public entry fun initialize(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u8, p3: address) {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 1;
        let _t4 = object::create_named_object(p0, vector[71u8, 108u8, 111u8, 98u8, 97u8, 108u8, 80u8, 101u8, 114u8, 112u8, 69u8, 110u8, 103u8, 105u8, 110u8, 101u8]);
        let _t5 = object::generate_extend_ref(&_t4);
        if (exists<Global>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 2;
        let _t19 = big_ordered_map::new<object::Object<perp_market::PerpMarket>,object::ExtendRef>();
        let _t21 = Global{extend_ref: _t5, market_refs: _t19, is_exchange_open: true};
        move_to<Global>(p0, _t21);
        accounts_collateral::initialize(p0, p1, p2, p3);
        event::emit<DexRegistrationEvent>(DexRegistrationEvent{dex: object::object_from_constructor_ref<object::ObjectCore>(&_t4), collateral_asset: p1, collateral_balance_decimals: p2});
    }
    public fun deposit(p0: &signer, p1: fungible_asset::FungibleAsset)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        let _t2 = &p1;
        let _t6 = fungible_asset::metadata_from_asset(_t2);
        let _t7 = accounts_collateral::collateral_asset_metadata();
        if (!(_t6 == _t7)) abort 9;
        if (!(fungible_asset::amount(_t2) > 0)) abort 8;
        accounts_collateral::deposit(p0, p1);
    }
    public fun get_remaining_size(p0: object::Object<perp_market::PerpMarket>, p1: u128): u64 {
        let _t4 = order_book_types::new_order_id_type(p1);
        perp_market::get_remaining_size(p0, _t4)
    }
    friend fun decrease_order_size(p0: &signer, p1: order_book_types::OrderIdType, p2: object::Object<perp_market::PerpMarket>, p3: u64)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        let _t4 = clearinghouse_perp::market_callbacks(p2);
        let _t12 = &_t4;
        perp_market::decrease_order_size(p2, p0, p1, p3, _t12);
    }
    friend fun place_bulk_order(p0: object::Object<perp_market::PerpMarket>, p1: &signer, p2: vector<u64>, p3: vector<u64>, p4: vector<u64>, p5: vector<u64>): option::Option<order_book_types::OrderIdType>
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        let _t10 = signer::address_of(p1);
        let _t6 = clearinghouse_perp::market_callbacks(p0);
        let _t17 = &_t6;
        let _t18 = perp_market::place_bulk_order(p0, _t10, p2, p3, p4, p5, _t17);
        trigger_matching(p0, 2u32);
        _t18
    }
    public entry fun trigger_matching(p0: object::Object<perp_market::PerpMarket>, p1: u32)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        async_matching_engine::trigger_matching(p0, p1);
    }
    friend fun cancel_order(p0: object::Object<perp_market::PerpMarket>, p1: &signer, p2: order_book_types::OrderIdType)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        let _t3 = clearinghouse_perp::market_callbacks(p0);
        let _t10 = &_t3;
        perp_market::cancel_order(p0, p1, p2, _t10);
        async_matching_engine::trigger_matching(p0, 10u32);
    }
    friend fun place_market_order(p0: object::Object<perp_market::PerpMarket>, p1: &signer, p2: u64, p3: bool, p4: bool, p5: option::Option<u64>, p6: option::Option<u64>, p7: option::Option<u64>, p8: option::Option<u64>, p9: option::Option<u64>, p10: option::Option<u64>, p11: option::Option<builder_code_registry::BuilderCode>): order_book_types::OrderIdType {
        let _t12;
        if (p3) _t12 = 18446744073709551615 else _t12 = 1;
        let _t17 = signer::address_of(p1);
        let _t21 = order_book_types::immediate_or_cancel();
        let _t23 = option::none<order_book_types::OrderIdType>();
        async_matching_engine::place_order(p0, _t17, _t12, p2, p3, _t21, p4, _t23, p5, p6, p7, p8, p9, p10, p11)
    }
    friend fun place_order(p0: object::Object<perp_market::PerpMarket>, p1: &signer, p2: u64, p3: u64, p4: bool, p5: order_book_types::TimeInForce, p6: bool, p7: option::Option<u64>, p8: option::Option<u64>, p9: option::Option<u64>, p10: option::Option<u64>, p11: option::Option<u64>, p12: option::Option<u64>, p13: option::Option<builder_code_registry::BuilderCode>): order_book_types::OrderIdType
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        let _t17 = signer::address_of(p1);
        let _t23 = option::none<order_book_types::OrderIdType>();
        async_matching_engine::place_order(p0, _t17, p2, p3, p4, p5, p6, _t23, p7, p8, p9, p10, p11, p12, p13)
    }
    friend fun cancel_client_order(p0: object::Object<perp_market::PerpMarket>, p1: &signer, p2: u64)
        acquires Global
    {
        cancel_client_order_no_trigger(p0, p1, p2);
        async_matching_engine::trigger_matching(p0, 10u32);
    }
    friend fun cancel_client_order_no_trigger(p0: object::Object<perp_market::PerpMarket>, p1: &signer, p2: u64)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        let _t3 = clearinghouse_perp::market_callbacks(p0);
        let _t10 = &_t3;
        perp_market::cancel_client_order(p0, p1, p2, _t10);
    }
    public fun get_oracle_price(p0: object::Object<perp_market::PerpMarket>): u64 {
        price_management::get_oracle_price(p0)
    }
    public entry fun update_internal_oracle_price(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: u64, p3: vector<address>, p4: bool)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        perp_market_config::update_internal_oracle_price(p0, p1, p2);
        refresh_liquidate_and_trigger(p1, p3, p4);
    }
    friend fun refresh_liquidate_and_trigger(p0: object::Object<perp_market::PerpMarket>, p1: vector<address>, p2: bool)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        refresh_price(p0);
        let _t3 = p1;
        vector::reverse<address>(&mut _t3);
        let _t4 = _t3;
        let _t5 = vector::length<address>(&_t4);
        while (_t5 > 0) {
            async_matching_engine::liquidate_position_with_fill_limit(vector::pop_back<address>(&mut _t4), p0, 0u32);
            _t5 = _t5 - 1
        };
        vector::destroy_empty<address>(_t4);
        if (p2) {
            let _t27 = get_mark_price(p0);
            trigger_position_based_tp_sl(p0, _t27);
            let _t30 = get_mark_price(p0);
            async_matching_engine::trigger_price_based_conditional_orders(p0, _t30);
            async_matching_engine::trigger_twap_orders(p0);
            trigger_matching(p0, 10u32)
        };
    }
    public entry fun update_internal_oracle_updater(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: address)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 1;
        perp_market_config::update_internal_oracle_updater(p1, p2);
    }
    public entry fun delist_market(p0: &signer, p1: object::Object<perp_market::PerpMarket>) {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 1;
        perp_market_config::delist_market(p1);
    }
    public fun get_mark_and_oracle_price(p0: object::Object<perp_market::PerpMarket>): (u64, u64) {
        let (_t2,_t3) = price_management::get_mark_and_oracle_price(p0);
        (_t2, _t3)
    }
    public fun get_mark_price(p0: object::Object<perp_market::PerpMarket>): u64 {
        price_management::get_mark_price(p0)
    }
    public fun backstop_liquidator(): address {
        accounts_collateral::backstop_liquidator()
    }
    public fun market_max_leverage(p0: object::Object<perp_market::PerpMarket>): u8 {
        perp_market_config::get_max_leverage(p0)
    }
    friend fun configure_user_settings_for_market(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: bool, p3: u8)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        perp_positions::configure_user_settings_for_market(p0, p1, p2, p3);
    }
    public fun get_position_is_long(p0: address, p1: object::Object<perp_market::PerpMarket>): bool {
        perp_positions::get_position_is_long(p0, p1)
    }
    public fun get_position_size(p0: address, p1: object::Object<perp_market::PerpMarket>): u64 {
        perp_positions::get_position_size(p0, p1)
    }
    public fun has_position(p0: address, p1: object::Object<perp_market::PerpMarket>): bool {
        perp_positions::has_position(p0, p1)
    }
    friend fun init_user_if_new(p0: &signer, p1: address) {
        perp_positions::init_user_if_new(p0, p1);
    }
    public fun is_position_isolated(p0: address, p1: object::Object<perp_market::PerpMarket>): bool {
        perp_positions::is_position_isolated(p0, p1)
    }
    public fun is_position_liquidatable(p0: address, p1: object::Object<perp_market::PerpMarket>): bool {
        accounts_collateral::is_position_liquidatable(p0, p1, false)
    }
    public fun transfer_margin_to_isolated_position(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: bool, p3: object::Object<fungible_asset::Metadata>, p4: u64)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        if (!(p4 > 0)) abort 8;
        let _t12 = accounts_collateral::collateral_asset_metadata();
        if (!(p3 == _t12)) abort 9;
        accounts_collateral::transfer_margin_fungible_to_isolated_position(signer::address_of(p0), p1, p2, p4);
    }
    public fun deposit_to_isolated_position_margin(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: fungible_asset::FungibleAsset)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        let _t3 = &p2;
        let _t7 = fungible_asset::metadata_from_asset(_t3);
        let _t8 = accounts_collateral::collateral_asset_metadata();
        if (!(_t7 == _t8)) abort 9;
        if (!(fungible_asset::amount(_t3) > 0)) abort 8;
        accounts_collateral::deposit_to_isolated_position_margin(p0, p1, p2);
    }
    public fun get_account_balance_fungible(p0: address): u64 {
        accounts_collateral::get_account_balance_fungible(p0)
    }
    public fun get_isolated_position_margin(p0: address, p1: object::Object<perp_market::PerpMarket>): u64 {
        accounts_collateral::get_isolated_position_margin(p0, p1)
    }
    public fun withdraw_fungible(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u64): fungible_asset::FungibleAsset
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        if (!(p2 > 0)) abort 8;
        let _t11 = accounts_collateral::collateral_asset_metadata();
        if (!(p1 == _t11)) abort 9;
        let _t4 = accounts_collateral::withdraw_fungible(p0, p2);
        let _t18 = fungible_asset::metadata_from_asset(&_t4);
        if (!(p1 == _t18)) abort 7;
        _t4
    }
    public fun get_current_open_interest(p0: object::Object<perp_market::PerpMarket>): u64 {
        open_interest_tracker::get_current_open_interest(p0)
    }
    public entry fun close_delisted_position(p0: address, p1: object::Object<perp_market::PerpMarket>)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        if (!perp_market_config::is_market_delisted(p1)) abort 22;
        clearinghouse_perp::close_delisted_position(p0, p1);
    }
    public entry fun drain_async_queue(p0: &signer, p1: object::Object<perp_market::PerpMarket>)
        acquires Global
    {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 1;
        if (is_exchange_open()) abort 4;
        async_matching_engine::drain_async_queue(p1);
    }
    public entry fun liquidate_position(p0: address, p1: object::Object<perp_market::PerpMarket>)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        async_matching_engine::liquidate_position(p0, p1);
    }
    friend fun cancel_orders(p0: object::Object<perp_market::PerpMarket>, p1: &signer, p2: vector<order_book_types::OrderIdType>)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        let _t3 = p2;
        vector::reverse<order_book_types::OrderIdType>(&mut _t3);
        let _t4 = _t3;
        let _t5 = vector::length<order_book_types::OrderIdType>(&_t4);
        while (_t5 > 0) {
            let _t6 = vector::pop_back<order_book_types::OrderIdType>(&mut _t4);
            let _t7 = clearinghouse_perp::market_callbacks(p0);
            let _t24 = &_t7;
            perp_market::cancel_order(p0, p1, _t6, _t24);
            _t5 = _t5 - 1;
            continue
        };
        vector::destroy_empty<order_book_types::OrderIdType>(_t4);
        async_matching_engine::trigger_matching(p0, 10u32);
    }
    friend fun cancel_tp_sl_order_for_position(p0: object::Object<perp_market::PerpMarket>, p1: &signer, p2: order_book_types::OrderIdType)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        perp_positions::cancel_tp_sl(signer::address_of(p1), p0, p2);
    }
    public entry fun delist_market_with_mark_price(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: u64) {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 1;
        perp_market_config::delist_market(p1);
        price_management::override_mark_price(p1, p2);
    }
    public fun get_best_bid_and_ask_price(p0: object::Object<perp_market::PerpMarket>): (option::Option<u64>, option::Option<u64>) {
        let _t2 = perp_market::best_bid_price(p0);
        let _t4 = perp_market::best_ask_price(p0);
        (_t2, _t4)
    }
    public fun get_max_open_interest_delta(p0: object::Object<perp_market::PerpMarket>): u64 {
        open_interest_tracker::get_max_open_interest_delta_for_market(p0)
    }
    public fun get_position_avg_price(p0: address, p1: object::Object<perp_market::PerpMarket>): u64 {
        let _t5;
        let _t4;
        let _t2 = perp_positions::get_position_entry_px_times_size_sum(p0, p1);
        let _t3 = perp_positions::get_position_size(p0, p1);
        if (_t3 == 0) _t4 = _t2 == 0u128 else _t4 = false;
        if (_t4) _t5 = 0 else {
            let _t10;
            let _t6 = _t2;
            let _t7 = _t3 as u128;
            if (perp_positions::get_position_is_long(p0, p1)) {
                let _t8 = _t6;
                let _t9 = _t7;
                if (_t8 == 0u128) if (_t9 != 0u128) _t10 = 0u128 else {
                    let _t44 = error::invalid_argument(4);
                    abort _t44
                } else _t10 = (_t8 - 1u128) / _t9 + 1u128
            } else _t10 = _t6 / _t7;
            _t5 = _t10 as u64
        };
        _t5
    }
    public fun get_position_entry_price_times_size_sum(p0: address, p1: object::Object<perp_market::PerpMarket>): u128 {
        perp_positions::get_position_entry_px_times_size_sum(p0, p1)
    }
    public fun get_remaining_size_for_order(p0: object::Object<perp_market::PerpMarket>, p1: u128): u64 {
        let _t2 = order_book_types::new_order_id_type(p1);
        perp_market::get_remaining_size(p0, _t2)
    }
    public fun list_markets(): vector<address>
        acquires Global
    {
        let _t0 = vector::empty<address>();
        let _t1 = &borrow_global<Global>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).market_refs;
        let _t10 = big_ordered_map::is_empty<object::Object<perp_market::PerpMarket>,object::ExtendRef>(_t1);
        'l0: loop {
            if (!_t10) {
                let (_t14,_t15) = big_ordered_map::borrow_front<object::Object<perp_market::PerpMarket>,object::ExtendRef>(_t1);
                let _t3 = _t14;
                loop {
                    let _t17 = &mut _t0;
                    let _t19 = object::object_address<perp_market::PerpMarket>(&_t3);
                    vector::push_back<address>(_t17, _t19);
                    let _t21 = &_t3;
                    let _t4 = big_ordered_map::next_key<object::Object<perp_market::PerpMarket>,object::ExtendRef>(_t1, _t21);
                    if (!option::is_some<object::Object<perp_market::PerpMarket>>(&_t4)) break 'l0;
                    _t3 = option::destroy_some<object::Object<perp_market::PerpMarket>>(_t4);
                    continue
                }
            };
            return _t0
        };
        _t0
    }
    public fun market_name(p0: object::Object<perp_market::PerpMarket>): string::String {
        perp_market_config::get_name(p0)
    }
    public fun market_sz_decimals(p0: object::Object<perp_market::PerpMarket>): u8 {
        perp_market_config::get_sz_decimals(p0)
    }
    friend fun place_tp_sl_order_for_position(p0: object::Object<perp_market::PerpMarket>, p1: &signer, p2: option::Option<u64>, p3: option::Option<u64>, p4: option::Option<u64>, p5: option::Option<u64>, p6: option::Option<u64>, p7: option::Option<u64>): (option::Option<order_book_types::OrderIdType>, option::Option<order_book_types::OrderIdType>)
        acquires Global
    {
        let _t8;
        if (!is_exchange_open()) abort 5;
        if (option::is_some<u64>(&p2)) _t8 = true else _t8 = option::is_some<u64>(&p5);
        if (!_t8) abort 6;
        let _t9 = signer::address_of(p1);
        let _t25 = process_tp_sl_order(p0, _t9, p2, p3, p4, true);
        let _t32 = process_tp_sl_order(p0, _t9, p5, p6, p7, false);
        (_t25, _t32)
    }
    fun process_tp_sl_order(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: option::Option<u64>, p3: option::Option<u64>, p4: option::Option<u64>, p5: bool): option::Option<order_book_types::OrderIdType> {
        let _t6;
        if (option::is_some<u64>(&p2)) {
            let _t12 = option::destroy_some<u64>(p2);
            let _t16 = option::none<order_book_types::OrderIdType>();
            _t6 = option::some<order_book_types::OrderIdType>(tp_sl_utils::place_tp_sl_order_for_position_internal(p0, p1, _t12, p3, p4, p5, _t16))
        } else if (option::is_none<u64>(&p3)) if (option::is_none<u64>(&p4)) _t6 = option::none<order_book_types::OrderIdType>() else abort 6 else abort 6;
        _t6
    }
    friend fun place_twap_order(p0: object::Object<perp_market::PerpMarket>, p1: &signer, p2: u64, p3: bool, p4: bool, p5: u64, p6: u64): order_book_types::OrderIdType {
        perp_market_config::validate_size(p0, p2);
        p6 = decibel_time::now_seconds() + p6;
        let _t18 = option::some<perp_engine_types::TwapMetadata>(perp_engine_types::new_twap_metadata(p5, p6));
        let _t19 = option::none<perp_engine_types::ChildTpSlOrder>();
        let _t20 = option::none<perp_engine_types::ChildTpSlOrder>();
        let _t21 = option::none<builder_code_registry::BuilderCode>();
        let _t7 = perp_engine_types::new_order_metadata(p4, _t18, _t19, _t20, _t21);
        let _t8 = perp_market::next_order_id(p0);
        let _t27 = signer::address_of(p1);
        let _t29 = option::none<u64>();
        let _t36 = option::some<order_book_types::TriggerCondition>(order_book_types::new_time_based_trigger_condition(decibel_time::now_seconds()));
        let _t37 = order_book_types::immediate_or_cancel();
        let _t39 = order_book::new_single_order_request<perp_engine_types::OrderMetadata>(_t27, _t8, _t29, 0, p2, p2, p3, _t36, _t37, _t7);
        perp_market::place_maker_order(p0, _t39);
        _t8
    }
    fun refresh_price(p0: object::Object<perp_market::PerpMarket>)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        let _t6 = accounts_collateral::collateral_balance_precision();
        let _t1 = perp_market_config::get_oracle_price(p0, _t6);
        let _t2 = option::destroy_with_default<u64>(perp_market::best_bid_price(p0), _t1);
        let _t3 = option::destroy_with_default<u64>(perp_market::best_ask_price(p0), _t1);
        price_management::update_price(p0, _t1, _t2, _t3);
    }
    friend fun trigger_position_based_tp_sl(p0: object::Object<perp_market::PerpMarket>, p1: u64) {
        trigger_position_based_tp_sl_internal(p0, p1, true);
        trigger_position_based_tp_sl_internal(p0, p1, false);
    }
    friend fun register_market_internal(p0: &signer, p1: string::String, p2: u8, p3: u64, p4: u64, p5: u64, p6: u64, p7: u8, p8: bool, p9: oracle::OracleSource): object::Object<perp_market::PerpMarket>
        acquires Global
    {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 1;
        if (!exists<Global>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 3;
        let _t10 = borrow_global_mut<Global>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95);
        let _t11 = object::generate_signer_for_extending(&_t10.extend_ref);
        let _t27 = &_t11;
        let _t29 = bcs::to_bytes<string::String>(&p1);
        let _t12 = object::create_named_object(_t27, _t29);
        let _t13 = object::generate_signer(&_t12);
        async_matching_engine::register_market(&_t13, p8);
        let _t35 = &_t13;
        let _t36 = &_t11;
        let _t37 = &_t13;
        let _t41 = market::new_market_config(false, true, 5);
        let _t42 = market::new_market<perp_engine_types::OrderMetadata>(_t36, _t37, _t41);
        perp_market::register_market(_t35, _t42);
        adl_tracker::initialize(&_t13);
        open_interest_tracker::register_open_interest_tracker(&_t13, p6);
        perp_market_config::register_market(&_t13, p1, p2, p3, p4, p5, p7, p9);
        position_tp_sl_tracker::register_market(&_t13);
        let _t14 = object::object_from_constructor_ref<perp_market::PerpMarket>(&_t12);
        let _t58 = &mut _t10.market_refs;
        let _t61 = object::generate_extend_ref(&_t12);
        big_ordered_map::add<object::Object<perp_market::PerpMarket>,object::ExtendRef>(_t58, _t14, _t61);
        let _t62 = &_t13;
        let _t64 = accounts_collateral::collateral_balance_precision();
        let _t65 = perp_market_config::get_oracle_price(_t14, _t64);
        let _t67 = perp_market_config::get_size_multiplier(_t14);
        price_management::register_market(_t62, _t65, _t67);
        let _t15 = accounts_collateral::collateral_balance_precision();
        let _t73 = math::get_decimals(&_t15);
        event::emit<MarketRegistrationEvent>(MarketRegistrationEvent{market: _t14, name: p1, sz_decimals: p2, px_decimals: _t73, max_leverage: p7, max_open_interest: p6, min_size: p3, lot_size: p4, ticker_size: p5});
        _t14
    }
    public entry fun register_market_with_internal_oracle(p0: &signer, p1: string::String, p2: u8, p3: u64, p4: u64, p5: u64, p6: u64, p7: u8, p8: bool, p9: u64, p10: address)
        acquires Global
    {
        let _t22 = oracle::new_internal_oracle(p9, p10);
        let _t23 = register_market_internal(p0, p1, p2, p3, p4, p5, p6, p7, p8, _t22);
    }
    public entry fun register_market_with_pyth_oracle(p0: &signer, p1: string::String, p2: u8, p3: u64, p4: u64, p5: u64, p6: u64, p7: u8, p8: bool, p9: vector<u8>, p10: u64, p11: u8)
        acquires Global
    {
        let _t24 = oracle::new_pyth_oracle(p9, p10, p11);
        let _t25 = register_market_internal(p0, p1, p2, p3, p4, p5, p6, p7, p8, _t24);
    }
    public entry fun set_global_exchange_open(p0: &signer, p1: bool)
        acquires Global
    {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 1;
        let _t2 = &mut borrow_global_mut<Global>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).is_exchange_open;
        *_t2 = p1;
    }
    public entry fun set_market_allowlist_only(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: vector<address>) {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 1;
        perp_market_config::allowlist_only(p1, p2);
    }
    public entry fun set_market_halted(p0: &signer, p1: object::Object<perp_market::PerpMarket>) {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 1;
        perp_market_config::halt_market(p1);
    }
    public entry fun set_market_max_leverage(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: u8) {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 1;
        perp_market_config::set_max_leverage(p1, p2);
    }
    public entry fun set_market_open(p0: &signer, p1: object::Object<perp_market::PerpMarket>) {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 1;
        perp_market_config::set_open(p1);
    }
    public entry fun set_market_open_interest(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: u64) {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 1;
        open_interest_tracker::set_max_open_interest(p1, p2);
    }
    public entry fun set_market_reduce_only(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: vector<address>) {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 1;
        perp_market_config::set_reduce_only(p1, p2);
    }
    fun trigger_position_based_tp_sl_internal(p0: object::Object<perp_market::PerpMarket>, p1: u64, p2: bool) {
        let _t3 = perp_positions::take_ready_tp_sl_orders(p0, p1, p2, 10);
        p1 = 0;
        loop {
            let _t9;
            let _t8;
            let _t18 = vector::length<position_tp_sl_tracker::PendingRequest>(&_t3);
            if (!(p1 < _t18)) break;
            let (_t24,_t25,_t26,_t27) = position_tp_sl_tracker::destroy_pending_request(*vector::borrow<position_tp_sl_tracker::PendingRequest>(&_t3, p1));
            let _t4 = _t27;
            let _t5 = _t26;
            let _t7 = _t24;
            p2 = perp_positions::get_position_is_long(_t7, p0);
            if (option::is_some<u64>(&_t5)) _t8 = option::destroy_some<u64>(_t5) else _t8 = price_management::get_mark_price(p0);
            if (option::is_some<u64>(&_t4)) _t9 = option::destroy_some<u64>(_t4) else _t9 = perp_positions::get_position_size(_t7, p0);
            let _t45 = order_book_types::good_till_cancelled();
            let _t48 = option::some<order_book_types::OrderIdType>(_t25);
            let _t49 = option::none<u64>();
            let _t50 = option::none<u64>();
            let _t51 = option::none<u64>();
            let _t52 = option::none<u64>();
            let _t53 = option::none<u64>();
            let _t54 = option::none<u64>();
            let _t55 = option::none<builder_code_registry::BuilderCode>();
            let _t56 = async_matching_engine::place_order(p0, _t7, _t8, _t9, !p2, _t45, true, _t48, _t49, _t50, _t51, _t52, _t53, _t54, _t55);
            p1 = p1 + 1;
            continue
        };
    }
    friend fun update_client_order(p0: &signer, p1: u64, p2: object::Object<perp_market::PerpMarket>, p3: u64, p4: u64, p5: bool, p6: order_book_types::TimeInForce, p7: bool, p8: option::Option<u64>, p9: option::Option<u64>, p10: option::Option<u64>, p11: option::Option<u64>, p12: option::Option<builder_code_registry::BuilderCode>)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        let _t13 = clearinghouse_perp::market_callbacks(p2);
        let _t20 = &_t13;
        perp_market::cancel_client_order(p2, p0, p1, _t20);
        let _t29 = option::some<u64>(p1);
        let _t30 = option::none<u64>();
        let _t36 = place_order(p2, p0, p3, p4, p5, p6, p7, _t29, _t30, p8, p9, p10, p11, p12);
    }
    friend fun update_order(p0: &signer, p1: order_book_types::OrderIdType, p2: object::Object<perp_market::PerpMarket>, p3: u64, p4: u64, p5: bool, p6: order_book_types::TimeInForce, p7: bool, p8: option::Option<u64>, p9: option::Option<u64>, p10: option::Option<u64>, p11: option::Option<u64>, p12: option::Option<builder_code_registry::BuilderCode>)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        let _t13 = clearinghouse_perp::market_callbacks(p2);
        let _t20 = &_t13;
        perp_market::cancel_order(p2, p0, p1, _t20);
        let _t28 = option::none<u64>();
        let _t29 = option::none<u64>();
        let _t35 = place_order(p2, p0, p3, p4, p5, p6, p7, _t28, _t29, p8, p9, p10, p11, p12);
    }
    public entry fun update_pyth_oracle_price(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: vector<vector<u8>>, p3: vector<address>, p4: bool)
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        pyth::update_price_feeds_with_funder(p0, p2);
        refresh_liquidate_and_trigger(p1, p3, p4);
    }
    public fun view_position_status(p0: address, p1: object::Object<perp_market::PerpMarket>): perp_positions::AccountStatusDetailed {
        accounts_collateral::position_status(p0, p1)
    }
    public fun withdraw_from_isolated_position_margin(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: object::Object<fungible_asset::Metadata>, p3: u64): fungible_asset::FungibleAsset
        acquires Global
    {
        if (!is_exchange_open()) abort 5;
        if (!(p3 > 0)) abort 8;
        let _t12 = accounts_collateral::collateral_asset_metadata();
        if (!(p2 == _t12)) abort 9;
        let _t5 = accounts_collateral::withdraw_fungible_from_isolated_position_margin(p0, p1, p3);
        let _t20 = fungible_asset::metadata_from_asset(&_t5);
        if (!(p2 == _t20)) abort 7;
        _t5
    }
}
