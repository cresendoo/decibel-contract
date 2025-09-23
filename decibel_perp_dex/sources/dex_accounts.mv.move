module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::dex_accounts {
    use 0x1::option;
    use 0x1::object;
    use 0x1::ordered_map;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine;
    use 0x1::fungible_asset;
    use 0x1::primary_fungible_store;
    use 0x7::order_book_types;
    use 0x1::signer;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::builder_code_registry;
    use 0x1::event;
    enum Delegation has copy, drop, store {
        TradingAllowed,
    }
    struct DelegationChangedEvent has drop, store {
        subaccount: address,
        delegated_account: address,
        delegation: option::Option<Delegation>,
    }
    struct Subaccount has key {
        extend_ref: object::ExtendRef,
        delegated_trading: ordered_map::OrderedMap<address, Delegation>,
    }
    struct SubaccountCreatedEvent has drop, store {
        subaccount: address,
        owner: address,
        is_primary: bool,
    }
    public entry fun configure_user_settings_for_market(p0: &signer, p1: object::Object<Subaccount>, p2: object::Object<perp_market::PerpMarket>, p3: bool, p4: u8)
        acquires Subaccount
    {
        let _t5 = get_subaccount_signer_if_owner_or_delegate(p0, p1);
        perp_engine::configure_user_settings_for_market(&_t5, p2, p3, p4);
    }
    fun get_subaccount_signer_if_owner_or_delegate(p0: &signer, p1: object::Object<Subaccount>): signer
        acquires Subaccount
    {
        let _t4;
        let _t2 = p1;
        let _t12 = signer::address_of(p0);
        if (object::owns<Subaccount>(_t2, _t12)) _t4 = true else {
            let _t6 = signer::address_of(p0);
            let _t7 = _t2;
            let _t28 = object::object_address<Subaccount>(&_t7);
            let _t30 = &borrow_global<Subaccount>(_t28).delegated_trading;
            let _t31 = &_t6;
            _t4 = ordered_map::contains<address,Delegation>(_t30, _t31)
        };
        if (!_t4) abort 8;
        let _t5 = p1;
        let _t19 = object::object_address<Subaccount>(&_t5);
        object::generate_signer_for_extending(&borrow_global<Subaccount>(_t19).extend_ref)
    }
    public entry fun transfer_margin_to_isolated_position(p0: &signer, p1: object::Object<Subaccount>, p2: object::Object<perp_market::PerpMarket>, p3: bool, p4: object::Object<fungible_asset::Metadata>, p5: u64)
        acquires Subaccount
    {
        let _t6 = get_subaccount_signer_if_owner(p0, p1);
        perp_engine::transfer_margin_to_isolated_position(&_t6, p2, p3, p4, p5);
    }
    fun get_subaccount_signer_if_owner(p0: &signer, p1: object::Object<Subaccount>): signer
        acquires Subaccount
    {
        let _t5 = signer::address_of(p0);
        if (!object::owns<Subaccount>(p1, _t5)) abort 1;
        let _t2 = p1;
        let _t9 = object::object_address<Subaccount>(&_t2);
        object::generate_signer_for_extending(&borrow_global<Subaccount>(_t9).extend_ref)
    }
    public entry fun deposit_to_isolated_position_margin(p0: &signer, p1: object::Object<Subaccount>, p2: object::Object<perp_market::PerpMarket>, p3: object::Object<fungible_asset::Metadata>, p4: u64)
        acquires Subaccount
    {
        let _t5 = primary_fungible_store::withdraw<fungible_asset::Metadata>(p0, p3, p4);
        let _t6 = get_subaccount_signer_if_owner(p0, p1);
        perp_engine::deposit_to_isolated_position_margin(&_t6, p2, _t5);
    }
    entry fun cancel_tp_sl_order_for_position(p0: &signer, p1: object::Object<Subaccount>, p2: object::Object<perp_market::PerpMarket>, p3: u128)
        acquires Subaccount
    {
        let _t4 = get_subaccount_signer_if_owner_or_delegate(p0, p1);
        let _t9 = &_t4;
        let _t11 = order_book_types::new_order_id_type(p3);
        perp_engine::cancel_tp_sl_order_for_position(p2, _t9, _t11);
    }
    entry fun place_tp_sl_order_for_position(p0: &signer, p1: object::Object<Subaccount>, p2: object::Object<perp_market::PerpMarket>, p3: option::Option<u64>, p4: option::Option<u64>, p5: option::Option<u64>, p6: option::Option<u64>, p7: option::Option<u64>, p8: option::Option<u64>)
        acquires Subaccount
    {
        let _t9 = get_subaccount_signer_if_owner_or_delegate(p0, p1);
        let _t14 = &_t9;
        let (_t21,_t22) = perp_engine::place_tp_sl_order_for_position(p2, _t14, p3, p4, p5, p6, p7, p8);
    }
    public entry fun withdraw_from_isolated_position_margin(p0: &signer, p1: object::Object<Subaccount>, p2: object::Object<perp_market::PerpMarket>, p3: object::Object<fungible_asset::Metadata>, p4: u64)
        acquires Subaccount
    {
        let _t5 = get_subaccount_signer_if_owner(p0, p1);
        let _t6 = perp_engine::withdraw_from_isolated_position_margin(&_t5, p2, p3, p4);
        primary_fungible_store::deposit(signer::address_of(p0), _t6);
    }
    public entry fun add_delegated_trader_and_deposit(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u64, p3: address)
        acquires Subaccount
    {
        deposit_to_subaccount(p0, p1, p2);
        delegate_trading_to(p0, p3);
    }
    public entry fun deposit_to_subaccount(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u64)
        acquires Subaccount
    {
        let _t3 = ensure_primary_subaccount_exists(p0);
        deposit_to_subaccount_at(p0, _t3, p1, p2);
    }
    public entry fun delegate_trading_to(p0: &signer, p1: address)
        acquires Subaccount
    {
        let _t2 = ensure_primary_subaccount_exists(p0);
        let _t3 = _t2;
        let _t8 = object::object_address<Subaccount>(&_t3);
        let _t10 = &mut borrow_global_mut<Subaccount>(_t8).delegated_trading;
        let _t12 = Delegation::TradingAllowed{};
        let _t13 = ordered_map::upsert<address,Delegation>(_t10, p1, _t12);
        let _t15 = object::object_address<Subaccount>(&_t2);
        let _t18 = option::some<Delegation>(Delegation::TradingAllowed{});
        event::emit<DelegationChangedEvent>(DelegationChangedEvent{subaccount: _t15, delegated_account: p1, delegation: _t18});
    }
    public entry fun add_delegated_trader_and_deposit_to_subaccount(p0: &signer, p1: object::Object<Subaccount>, p2: object::Object<fungible_asset::Metadata>, p3: u64, p4: address)
        acquires Subaccount
    {
        deposit_to_subaccount_at(p0, p1, p2, p3);
        delegate_trading_to_for_subaccount(p0, p1, p4);
    }
    public entry fun deposit_to_subaccount_at(p0: &signer, p1: object::Object<Subaccount>, p2: object::Object<fungible_asset::Metadata>, p3: u64)
        acquires Subaccount
    {
        let _t4 = primary_fungible_store::withdraw<fungible_asset::Metadata>(p0, p2, p3);
        let _t5 = get_subaccount_signer_if_owner(p0, p1);
        perp_engine::deposit(&_t5, _t4);
    }
    public entry fun delegate_trading_to_for_subaccount(p0: &signer, p1: object::Object<Subaccount>, p2: address)
        acquires Subaccount
    {
        let _t8 = signer::address_of(p0);
        if (!object::owns<Subaccount>(p1, _t8)) abort 1;
        let _t3 = p1;
        let _t4 = p2;
        let _t5 = _t3;
        let _t14 = object::object_address<Subaccount>(&_t5);
        let _t16 = &mut borrow_global_mut<Subaccount>(_t14).delegated_trading;
        let _t18 = Delegation::TradingAllowed{};
        let _t19 = ordered_map::upsert<address,Delegation>(_t16, _t4, _t18);
        let _t21 = object::object_address<Subaccount>(&_t3);
        let _t24 = option::some<Delegation>(Delegation::TradingAllowed{});
        event::emit<DelegationChangedEvent>(DelegationChangedEvent{subaccount: _t21, delegated_account: _t4, delegation: _t24});
    }
    entry fun approve_max_builder_fee_for_subaccount(p0: &signer, p1: object::Object<Subaccount>, p2: address, p3: u64)
        acquires Subaccount
    {
        let _t4 = get_subaccount_signer_if_owner(p0, p1);
        builder_code_registry::approve_max_fee(&_t4, p2, p3);
    }
    entry fun bulk_cancel_client_and_place_order_to_subaccount(p0: &signer, p1: object::Object<Subaccount>, p2: object::Object<perp_market::PerpMarket>, p3: vector<u64>, p4: vector<u64>, p5: vector<u64>, p6: vector<bool>, p7: u8, p8: bool, p9: vector<u64>, p10: option::Option<address>, p11: option::Option<u64>)
        acquires Subaccount
    {
        let _t21;
        let _t12 = get_subaccount_signer_if_owner_or_delegate(p0, p1);
        let _t14 = 0x1::vector::length<u64>(&p4);
        let _t33 = 0x1::vector::length<bool>(&p6);
        if (!(_t14 == _t33)) abort 11;
        let _t37 = 0x1::vector::length<u64>(&p5);
        if (!(_t14 == _t37)) abort 11;
        let _t41 = 0x1::vector::length<u64>(&p9);
        if (!(_t14 == _t41)) abort 11;
        let _t13 = &p3;
        let _t15 = 0;
        let _t16 = 0x1::vector::length<u64>(_t13);
        while (_t15 < _t16) {
            let _t17 = 0x1::vector::borrow<u64>(_t13, _t15);
            let _t54 = &_t12;
            let _t56 = *_t17;
            perp_engine::cancel_client_order_no_trigger(p2, _t54, _t56);
            _t15 = _t15 + 1;
            continue
        };
        let _t18 = order_book_types::time_in_force_from_index(p7);
        let _t19 = p10;
        if (option::is_some<address>(&_t19)) {
            let _t68 = option::destroy_some<address>(_t19);
            let _t70 = option::destroy_some<u64>(p11);
            _t21 = option::some<builder_code_registry::BuilderCode>(builder_code_registry::new_builder_code(_t68, _t70))
        } else _t21 = option::none<builder_code_registry::BuilderCode>();
        _t15 = 0;
        _t16 = 0x1::vector::length<u64>(&p4);
        while (_t15 < _t16) {
            let _t22 = *0x1::vector::borrow<u64>(&p4, _t15);
            let _t23 = *0x1::vector::borrow<u64>(&p5, _t15);
            let _t24 = *0x1::vector::borrow<bool>(&p6, _t15);
            let _t25 = *0x1::vector::borrow<u64>(&p9, _t15);
            let _t96 = &_t12;
            let _t103 = option::some<u64>(_t25);
            let _t104 = option::none<u64>();
            let _t105 = option::none<u64>();
            let _t106 = option::none<u64>();
            let _t107 = option::none<u64>();
            let _t108 = option::none<u64>();
            let _t110 = perp_engine::place_order(p2, _t96, _t22, _t23, _t24, _t18, p8, _t103, _t104, _t105, _t106, _t107, _t108, _t21);
            _t15 = _t15 + 1;
            continue
        };
        perp_engine::trigger_matching(p2, 2u32);
    }
    entry fun cancel_client_order_to_subaccount(p0: &signer, p1: object::Object<Subaccount>, p2: u64, p3: object::Object<perp_market::PerpMarket>)
        acquires Subaccount
    {
        let _t4 = get_subaccount_signer_if_owner_or_delegate(p0, p1);
        let _t9 = &_t4;
        perp_engine::cancel_client_order(p3, _t9, p2);
    }
    entry fun cancel_order_to_subaccount(p0: &signer, p1: object::Object<Subaccount>, p2: u128, p3: object::Object<perp_market::PerpMarket>)
        acquires Subaccount
    {
        let _t4 = get_subaccount_signer_if_owner_or_delegate(p0, p1);
        let _t9 = &_t4;
        let _t11 = order_book_types::new_order_id_type(p2);
        perp_engine::cancel_order(p3, _t9, _t11);
    }
    public entry fun create_new_subaccount(p0: &signer) {
        let _t3 = create_subaccount_internal(p0, false);
    }
    fun create_subaccount_internal(p0: &signer, p1: bool): object::Object<Subaccount> {
        let _t2;
        if (p1) _t2 = object::create_named_object(p0, vector[100u8, 101u8, 99u8, 105u8, 98u8, 101u8, 108u8, 95u8, 100u8, 101u8, 120u8, 95u8, 112u8, 114u8, 105u8, 109u8, 97u8, 114u8, 121u8]) else _t2 = object::create_object(signer::address_of(p0));
        let _t3 = object::generate_extend_ref(&_t2);
        let _t4 = object::generate_signer_for_extending(&_t3);
        let _t5 = object::address_from_constructor_ref(&_t2);
        let _t16 = &_t4;
        let _t18 = ordered_map::new<address,Delegation>();
        let _t19 = Subaccount{extend_ref: _t3, delegated_trading: _t18};
        move_to<Subaccount>(_t16, _t19);
        object::set_untransferable(&_t2);
        let _t21 = &_t4;
        let _t23 = signer::address_of(p0);
        perp_engine::init_user_if_new(_t21, _t23);
        let _t26 = signer::address_of(p0);
        event::emit<SubaccountCreatedEvent>(SubaccountCreatedEvent{subaccount: _t5, owner: _t26, is_primary: p1});
        object::address_to_object<Subaccount>(_t5)
    }
    fun ensure_primary_subaccount_exists(p0: &signer): object::Object<Subaccount> {
        let _t2;
        let _t1 = primary_subaccount(signer::address_of(p0));
        if (exists<Subaccount>(_t1)) _t2 = object::address_to_object<Subaccount>(_t1) else _t2 = create_subaccount_internal(p0, true);
        _t2
    }
    public fun primary_subaccount(p0: address): address {
        object::create_object_address(&p0, vector[100u8, 101u8, 99u8, 105u8, 98u8, 101u8, 108u8, 95u8, 100u8, 101u8, 120u8, 95u8, 112u8, 114u8, 105u8, 109u8, 97u8, 114u8, 121u8])
    }
    entry fun place_bulk_orders_to_subaccount(p0: &signer, p1: object::Object<Subaccount>, p2: object::Object<perp_market::PerpMarket>, p3: vector<u64>, p4: vector<u64>, p5: vector<u64>, p6: vector<u64>)
        acquires Subaccount
    {
        let _t7 = get_subaccount_signer_if_owner_or_delegate(p0, p1);
        let _t12 = &_t7;
        let _t17 = perp_engine::place_bulk_order(p2, _t12, p3, p4, p5, p6);
    }
    entry fun place_market_order_to_subaccount(p0: &signer, p1: object::Object<Subaccount>, p2: object::Object<perp_market::PerpMarket>, p3: u64, p4: bool, p5: bool, p6: option::Option<u64>, p7: option::Option<u64>, p8: option::Option<u64>, p9: option::Option<u64>, p10: option::Option<u64>, p11: option::Option<u64>, p12: option::Option<address>, p13: option::Option<u64>)
        acquires Subaccount
    {
        let _t15;
        let _t14 = p12;
        if (option::is_some<address>(&_t14)) {
            let _t21 = option::destroy_some<address>(_t14);
            let _t23 = option::destroy_some<u64>(p13);
            _t15 = option::some<builder_code_registry::BuilderCode>(builder_code_registry::new_builder_code(_t21, _t23))
        } else _t15 = option::none<builder_code_registry::BuilderCode>();
        let _t16 = get_subaccount_signer_if_owner_or_delegate(p0, p1);
        let _t30 = &_t16;
        let _t41 = perp_engine::place_market_order(p2, _t30, p3, p4, p5, p6, p7, p8, p9, p10, p11, _t15);
    }
    entry fun place_order_to_subaccount(p0: &signer, p1: object::Object<Subaccount>, p2: object::Object<perp_market::PerpMarket>, p3: u64, p4: u64, p5: bool, p6: u8, p7: bool, p8: option::Option<u64>, p9: option::Option<u64>, p10: option::Option<u64>, p11: option::Option<u64>, p12: option::Option<u64>, p13: option::Option<u64>, p14: option::Option<address>, p15: option::Option<u64>)
        acquires Subaccount
    {
        let _t17;
        let _t16 = p14;
        if (option::is_some<address>(&_t16)) {
            let _t23 = option::destroy_some<address>(_t16);
            let _t25 = option::destroy_some<u64>(p15);
            _t17 = option::some<builder_code_registry::BuilderCode>(builder_code_registry::new_builder_code(_t23, _t25))
        } else _t17 = option::none<builder_code_registry::BuilderCode>();
        let _t18 = get_subaccount_signer_if_owner_or_delegate(p0, p1);
        let _t32 = &_t18;
        let _t37 = order_book_types::time_in_force_from_index(p6);
        let _t46 = perp_engine::place_order(p2, _t32, p3, p4, p5, _t37, p7, p8, p9, p10, p11, p12, p13, _t17);
    }
    entry fun place_twap_order_to_subaccount(p0: &signer, p1: object::Object<Subaccount>, p2: object::Object<perp_market::PerpMarket>, p3: u64, p4: bool, p5: bool, p6: u64, p7: u64)
        acquires Subaccount
    {
        let _t8 = get_subaccount_signer_if_owner_or_delegate(p0, p1);
        let _t13 = &_t8;
        let _t19 = perp_engine::place_twap_order(p2, _t13, p3, p4, p5, p6, p7);
    }
    public entry fun revoke_delegation(p0: &signer, p1: object::Object<Subaccount>, p2: address)
        acquires Subaccount
    {
        let _t6 = signer::address_of(p0);
        if (!object::owns<Subaccount>(p1, _t6)) abort 1;
        let _t3 = p1;
        let _t10 = object::object_address<Subaccount>(&_t3);
        let _t12 = &mut borrow_global_mut<Subaccount>(_t10).delegated_trading;
        let _t13 = &p2;
        let _t14 = ordered_map::remove<address,Delegation>(_t12, _t13);
        let _t16 = object::object_address<Subaccount>(&p1);
        let _t18 = option::none<Delegation>();
        event::emit<DelegationChangedEvent>(DelegationChangedEvent{subaccount: _t16, delegated_account: p2, delegation: _t18});
    }
    entry fun revoke_max_builder_fee_for_subaccount(p0: &signer, p1: object::Object<Subaccount>, p2: address)
        acquires Subaccount
    {
        let _t3 = get_subaccount_signer_if_owner(p0, p1);
        builder_code_registry::revoke_max_fee(&_t3, p2);
    }
    entry fun update_client_order_to_subaccount(p0: &signer, p1: object::Object<Subaccount>, p2: u64, p3: object::Object<perp_market::PerpMarket>, p4: u64, p5: u64, p6: bool, p7: u8, p8: bool, p9: option::Option<u64>, p10: option::Option<u64>, p11: option::Option<u64>, p12: option::Option<u64>, p13: option::Option<address>, p14: option::Option<u64>)
        acquires Subaccount
    {
        let _t16;
        let _t15 = p13;
        if (option::is_some<address>(&_t15)) {
            let _t22 = option::destroy_some<address>(_t15);
            let _t24 = option::destroy_some<u64>(p14);
            _t16 = option::some<builder_code_registry::BuilderCode>(builder_code_registry::new_builder_code(_t22, _t24))
        } else _t16 = option::none<builder_code_registry::BuilderCode>();
        let _t17 = get_subaccount_signer_if_owner_or_delegate(p0, p1);
        let _t30 = &_t17;
        let _t37 = order_book_types::time_in_force_from_index(p7);
        perp_engine::update_client_order(_t30, p2, p3, p4, p5, p6, _t37, p8, p9, p10, p11, p12, _t16);
    }
    entry fun update_order_to_subaccount(p0: &signer, p1: object::Object<Subaccount>, p2: u128, p3: object::Object<perp_market::PerpMarket>, p4: u64, p5: u64, p6: bool, p7: u8, p8: bool, p9: option::Option<u64>, p10: option::Option<u64>, p11: option::Option<u64>, p12: option::Option<u64>, p13: option::Option<address>, p14: option::Option<u64>)
        acquires Subaccount
    {
        let _t16;
        let _t15 = p13;
        if (option::is_some<address>(&_t15)) {
            let _t22 = option::destroy_some<address>(_t15);
            let _t24 = option::destroy_some<u64>(p14);
            _t16 = option::some<builder_code_registry::BuilderCode>(builder_code_registry::new_builder_code(_t22, _t24))
        } else _t16 = option::none<builder_code_registry::BuilderCode>();
        let _t17 = get_subaccount_signer_if_owner_or_delegate(p0, p1);
        let _t30 = &_t17;
        let _t32 = order_book_types::new_order_id_type(p2);
        let _t38 = order_book_types::time_in_force_from_index(p7);
        perp_engine::update_order(_t30, _t32, p3, p4, p5, p6, _t38, p8, p9, p10, p11, p12, _t16);
    }
    entry fun update_tp_sl_order_for_position(p0: &signer, p1: object::Object<Subaccount>, p2: u128, p3: object::Object<perp_market::PerpMarket>, p4: option::Option<u64>, p5: option::Option<u64>, p6: option::Option<u64>, p7: option::Option<u64>, p8: option::Option<u64>, p9: option::Option<u64>)
        acquires Subaccount
    {
        let _t10 = get_subaccount_signer_if_owner_or_delegate(p0, p1);
        let _t16 = &_t10;
        let _t18 = order_book_types::new_order_id_type(p2);
        perp_engine::cancel_tp_sl_order_for_position(p3, _t16, _t18);
        let _t11 = get_subaccount_signer_if_owner_or_delegate(p0, p1);
        let _t23 = &_t11;
        let (_t30,_t31) = perp_engine::place_tp_sl_order_for_position(p3, _t23, p4, p5, p6, p7, p8, p9);
    }
    public entry fun withdraw_from_subaccount(p0: &signer, p1: object::Object<Subaccount>, p2: object::Object<fungible_asset::Metadata>, p3: u64)
        acquires Subaccount
    {
        let _t4 = get_subaccount_signer_if_owner(p0, p1);
        let _t5 = perp_engine::withdraw_fungible(&_t4, p2, p3);
        primary_fungible_store::deposit(signer::address_of(p0), _t5);
    }
}
