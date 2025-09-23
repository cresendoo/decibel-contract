module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::tp_sl_utils {
    use 0x1::object;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market;
    use 0x7::order_book_types;
    use 0x1::option;
    use 0x1::event;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market_config;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine_types;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_management;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::clearinghouse_perp;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::async_matching_engine;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine;
    struct OrderBasedTpSlEvent has copy, drop, store {
        market: object::Object<perp_market::PerpMarket>,
        parent_order_id: order_book_types::OrderIdType,
        status: TpSlStatus,
        trigger_price: u64,
        limit_price: option::Option<u64>,
        size: u64,
        is_tp: bool,
    }
    enum TpSlStatus has copy, drop, store {
        INACTIVE,
        ACTIVE,
    }
    public fun emit_order_based_event(p0: object::Object<perp_market::PerpMarket>, p1: u64, p2: option::Option<u64>, p3: order_book_types::OrderIdType, p4: u64, p5: TpSlStatus, p6: bool) {
        event::emit<OrderBasedTpSlEvent>(OrderBasedTpSlEvent{market: p0, parent_order_id: p3, status: p5, trigger_price: p1, limit_price: p2, size: p4, is_tp: p6});
    }
    public fun get_active_tp_sl_status(): TpSlStatus {
        TpSlStatus::ACTIVE{}
    }
    public fun get_inactive_tp_sl_status(): TpSlStatus {
        TpSlStatus::INACTIVE{}
    }
    friend fun place_tp_sl_order_for_position_internal(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: u64, p3: option::Option<u64>, p4: option::Option<u64>, p5: bool, p6: option::Option<order_book_types::OrderIdType>): order_book_types::OrderIdType {
        let _t9;
        perp_market_config::validate_price(p0, p2);
        let _t13 = option::is_some<u64>(&p4);
        'l1: loop {
            let _t8;
            let _t7;
            'l0: loop {
                loop {
                    if (_t13) {
                        _t7 = option::destroy_some<u64>(p4);
                        if (option::is_some<u64>(&p3)) {
                            let _t21 = *option::borrow<u64>(&p3);
                            perp_market_config::validate_price_and_size(p0, _t21, _t7)
                        } else perp_market_config::validate_size(p0, _t7);
                        _t8 = perp_positions::get_fixed_sized_tp_sl(p1, p0, p5, p2, p3);
                        if (!option::is_some<order_book_types::OrderIdType>(&_t8)) break;
                        break 'l0
                    };
                    if (!option::is_some<u64>(&p3)) break;
                    let _t60 = *option::borrow<u64>(&p3);
                    perp_market_config::validate_price(p0, _t60);
                    break
                };
                if (option::is_none<order_book_types::OrderIdType>(&p6)) {
                    _t9 = perp_market::next_order_id(p0);
                    break 'l1
                };
                _t9 = option::destroy_some<order_book_types::OrderIdType>(p6);
                break 'l1
            };
            perp_positions::increase_tp_sl_size(p1, p0, p2, p3, _t7, p5);
            return option::destroy_some<order_book_types::OrderIdType>(_t8)
        };
        perp_positions::add_tp_sl(p1, p0, _t9, p2, p3, p4, p5);
        _t9
    }
    friend fun validate_and_get_child_tp_sl_orders(p0: object::Object<perp_market::PerpMarket>, p1: order_book_types::OrderIdType, p2: bool, p3: option::Option<u64>, p4: option::Option<u64>, p5: option::Option<u64>, p6: option::Option<u64>): (option::Option<perp_engine_types::ChildTpSlOrder>, option::Option<perp_engine_types::ChildTpSlOrder>) {
        let _t9;
        let _t8;
        let _t7 = price_management::get_mark_price(p0);
        let _t13 = option::is_some<u64>(&p4);
        while (_t13) {
            let _t16 = option::destroy_some<u64>(p4);
            perp_market_config::validate_price(p0, _t16);
            if (!option::is_some<u64>(&p3)) abort 1;
            if (p2) {
                if (option::destroy_some<u64>(p3) > _t7) break;
                abort 1
            };
            if (option::destroy_some<u64>(p3) < _t7) break;
            abort 1
        };
        let _t25 = option::is_some<u64>(&p6);
        while (_t25) {
            let _t28 = option::destroy_some<u64>(p6);
            perp_market_config::validate_price(p0, _t28);
            if (!option::is_some<u64>(&p5)) abort 1;
            if (p2) {
                if (option::destroy_some<u64>(p5) < _t7) break;
                abort 1
            };
            if (option::destroy_some<u64>(p5) > _t7) break;
            abort 1
        };
        if (option::is_some<u64>(&p3)) {
            let _t39 = option::destroy_some<u64>(p3);
            let _t42 = perp_market::next_order_id(p0);
            _t8 = option::some<perp_engine_types::ChildTpSlOrder>(perp_engine_types::new_child_tp_sl_order(_t39, p4, _t42, p1))
        } else _t8 = option::none<perp_engine_types::ChildTpSlOrder>();
        if (option::is_some<u64>(&p5)) {
            let _t49 = option::destroy_some<u64>(p5);
            let _t52 = perp_market::next_order_id(p0);
            _t9 = option::some<perp_engine_types::ChildTpSlOrder>(perp_engine_types::new_child_tp_sl_order(_t49, p6, _t52, p1))
        } else _t9 = option::none<perp_engine_types::ChildTpSlOrder>();
        (_t8, _t9)
    }
}
