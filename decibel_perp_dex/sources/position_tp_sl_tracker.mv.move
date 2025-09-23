module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::position_tp_sl_tracker {
    use 0x1::big_ordered_map;
    use 0x7::order_book_types;
    use 0x1::option;
    use 0x1::object;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine;
    struct PendingOrderTracker has key {
        price_move_up_index: big_ordered_map::BigOrderedMap<PriceIndexKey, PendingRequest>,
        price_move_down_index: big_ordered_map::BigOrderedMap<PriceIndexKey, PendingRequest>,
    }
    struct PriceIndexKey has copy, drop, store {
        trigger_price: u64,
        position_address: address,
        limit_price: option::Option<u64>,
        is_full_size: bool,
    }
    struct PendingRequest has copy, drop, store {
        order_id: order_book_types::OrderIdType,
        account: address,
        limit_price: option::Option<u64>,
        size: option::Option<u64>,
    }
    fun new_default_big_ordered_map<T0: store, T1: store>(): big_ordered_map::BigOrderedMap<T0, T1> {
        big_ordered_map::new_with_config<T0,T1>(64u16, 32u16, true)
    }
    friend fun register_market(p0: &signer) {
        let _t2 = new_default_big_ordered_map<PriceIndexKey,PendingRequest>();
        let _t3 = new_default_big_ordered_map<PriceIndexKey,PendingRequest>();
        let _t4 = PendingOrderTracker{price_move_up_index: _t2, price_move_down_index: _t3};
        move_to<PendingOrderTracker>(p0, _t4);
    }
    friend fun add_new_tp_sl(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: order_book_types::OrderIdType, p3: PriceIndexKey, p4: option::Option<u64>, p5: option::Option<u64>, p6: bool, p7: bool)
        acquires PendingOrderTracker
    {
        let _t10;
        let _t12 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t8 = borrow_global_mut<PendingOrderTracker>(_t12);
        let _t9 = PendingRequest{order_id: p2, account: p1, limit_price: p4, size: p5};
        if (p6 == p7) _t10 = &mut _t8.price_move_up_index else _t10 = &mut _t8.price_move_down_index;
        big_ordered_map::add<PriceIndexKey,PendingRequest>(_t10, p3, _t9);
    }
    friend fun cancel_pending_tp_sl(p0: object::Object<perp_market::PerpMarket>, p1: PriceIndexKey, p2: bool, p3: bool)
        acquires PendingOrderTracker
    {
        let _t5;
        let _t7 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t4 = borrow_global_mut<PendingOrderTracker>(_t7);
        if (p2 == p3) _t5 = &mut _t4.price_move_up_index else _t5 = &mut _t4.price_move_down_index;
        let _t15 = &p1;
        let _t16 = big_ordered_map::remove<PriceIndexKey,PendingRequest>(_t5, _t15);
    }
    friend fun destroy_pending_request(p0: PendingRequest): (address, order_book_types::OrderIdType, option::Option<u64>, option::Option<u64>) {
        let PendingRequest{order_id: _t6, account: _t7, limit_price: _t8, size: _t9} = p0;
        (_t7, _t6, _t8, _t9)
    }
    friend fun get_account_from_pending_request(p0: &PendingRequest): address {
        *&p0.account
    }
    friend fun get_order_id_from_pending_request(p0: &PendingRequest): order_book_types::OrderIdType {
        *&p0.order_id
    }
    friend fun get_pending_order_id(p0: object::Object<perp_market::PerpMarket>, p1: PriceIndexKey, p2: bool, p3: bool): option::Option<order_book_types::OrderIdType>
        acquires PendingOrderTracker
    {
        let _t5;
        let _t8;
        let _t10 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t4 = borrow_global<PendingOrderTracker>(_t10);
        if (p2 == p3) _t5 = &_t4.price_move_up_index else _t5 = &_t4.price_move_down_index;
        let _t18 = &p1;
        let _t6 = big_ordered_map::get<PriceIndexKey,PendingRequest>(_t5, _t18);
        if (option::is_some<PendingRequest>(&_t6)) {
            let _t7 = option::destroy_some<PendingRequest>(_t6);
            _t8 = option::some<order_book_types::OrderIdType>(*&(&_t7).order_id)
        } else _t8 = option::none<order_book_types::OrderIdType>();
        _t8
    }
    friend fun get_pending_tp_sl(p0: object::Object<perp_market::PerpMarket>, p1: PriceIndexKey, p2: bool, p3: bool): (address, order_book_types::OrderIdType, option::Option<u64>, option::Option<u64>)
        acquires PendingOrderTracker
    {
        let _t5;
        let _t7 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t4 = borrow_global<PendingOrderTracker>(_t7);
        if (p2 == p3) _t5 = &_t4.price_move_up_index else _t5 = &_t4.price_move_down_index;
        let _t15 = &p1;
        let (_t18,_t19,_t20,_t21) = destroy_pending_request(*big_ordered_map::borrow<PriceIndexKey,PendingRequest>(_t5, _t15));
        (_t18, _t19, _t20, _t21)
    }
    friend fun get_size_from_pending_request(p0: &PendingRequest): option::Option<u64> {
        *&p0.size
    }
    friend fun get_trigger_price(p0: &PriceIndexKey): u64 {
        *&p0.trigger_price
    }
    friend fun increase_pending_tp_sl_size(p0: object::Object<perp_market::PerpMarket>, p1: PriceIndexKey, p2: u64, p3: bool, p4: bool)
        acquires PendingOrderTracker
    {
        let _t6;
        let _t9 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t5 = borrow_global_mut<PendingOrderTracker>(_t9);
        if (p3 == p4) _t6 = &mut _t5.price_move_up_index else _t6 = &mut _t5.price_move_down_index;
        let _t17 = &p1;
        let _t7 = big_ordered_map::remove<PriceIndexKey,PendingRequest>(_t6, _t17);
        if (!option::is_some<u64>(&(&_t7).size)) abort 1;
        let _t28 = option::some<u64>(option::destroy_some<u64>(*&(&_t7).size) + p2);
        let _t30 = &mut (&mut _t7).size;
        *_t30 = _t28;
        big_ordered_map::add<PriceIndexKey,PendingRequest>(_t6, p1, _t7);
    }
    friend fun new_price_index_key(p0: u64, p1: address, p2: option::Option<u64>, p3: bool): PriceIndexKey {
        PriceIndexKey{trigger_price: p0, position_address: p1, limit_price: p2, is_full_size: p3}
    }
    friend fun take_ready_price_move_down_orders(p0: object::Object<perp_market::PerpMarket>, p1: u64, p2: u64): vector<PendingRequest>
        acquires PendingOrderTracker
    {
        let _t10 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t3 = borrow_global_mut<PendingOrderTracker>(_t10);
        let _t4 = 0x1::vector::empty<PendingRequest>();
        loop {
            let _t5;
            if (big_ordered_map::is_empty<PriceIndexKey,PendingRequest>(&_t3.price_move_down_index)) _t5 = false else _t5 = 0x1::vector::length<PendingRequest>(&_t4) < p2;
            if (!_t5) break;
            let (_t23,_t24) = big_ordered_map::borrow_back<PriceIndexKey,PendingRequest>(&_t3.price_move_down_index);
            let _t7 = _t23;
            let _t29 = *&(&_t7).trigger_price;
            if (!(p1 <= _t29)) break;
            let _t32 = &mut _t3.price_move_down_index;
            let _t33 = &_t7;
            let _t8 = big_ordered_map::remove<PriceIndexKey,PendingRequest>(_t32, _t33);
            0x1::vector::push_back<PendingRequest>(&mut _t4, _t8);
            continue
        };
        _t4
    }
    friend fun take_ready_price_move_up_orders(p0: object::Object<perp_market::PerpMarket>, p1: u64, p2: u64): vector<PendingRequest>
        acquires PendingOrderTracker
    {
        let _t10 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t3 = borrow_global_mut<PendingOrderTracker>(_t10);
        let _t4 = 0x1::vector::empty<PendingRequest>();
        loop {
            let _t5;
            if (big_ordered_map::is_empty<PriceIndexKey,PendingRequest>(&_t3.price_move_up_index)) _t5 = false else _t5 = 0x1::vector::length<PendingRequest>(&_t4) < p2;
            if (!_t5) break;
            let (_t23,_t24) = big_ordered_map::borrow_front<PriceIndexKey,PendingRequest>(&_t3.price_move_up_index);
            let _t7 = _t23;
            let _t29 = *&(&_t7).trigger_price;
            if (!(p1 >= _t29)) break;
            let _t32 = &mut _t3.price_move_up_index;
            let _t33 = &_t7;
            let _t8 = big_ordered_map::remove<PriceIndexKey,PendingRequest>(_t32, _t33);
            0x1::vector::push_back<PendingRequest>(&mut _t4, _t8);
            continue
        };
        _t4
    }
}
