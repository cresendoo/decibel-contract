module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::adl_tracker {
    use 0x1::big_ordered_map;
    use 0x1::object;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market;
    use 0x1::option;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::liquidation;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine;
    struct ADLKey has copy, drop, store {
        entry_px: u64,
        account: address,
    }
    struct ADLTracker has key {
        long_positions: big_ordered_map::BigOrderedMap<ADLKey, ADLValue>,
        short_positions: big_ordered_map::BigOrderedMap<ADLKey, ADLValue>,
    }
    struct ADLValue has copy, drop, store {
    }
    friend fun initialize(p0: &signer) {
        let _t2 = big_ordered_map::new<ADLKey,ADLValue>();
        let _t3 = big_ordered_map::new<ADLKey,ADLValue>();
        let _t4 = ADLTracker{long_positions: _t2, short_positions: _t3};
        move_to<ADLTracker>(p0, _t4);
    }
    friend fun add_position(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: bool, p3: u64)
        acquires ADLTracker
    {
        let _t7 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t4 = borrow_global_mut<ADLTracker>(_t7);
        let _t5 = ADLKey{entry_px: p3, account: p1};
        if (p2) {
            let _t14 = &mut _t4.long_positions;
            let _t17 = ADLValue{};
            let _t18 = big_ordered_map::upsert<ADLKey,ADLValue>(_t14, _t5, _t17);
        } else {
            let _t20 = &mut _t4.short_positions;
            let _t23 = ADLValue{};
            let _t24 = big_ordered_map::upsert<ADLKey,ADLValue>(_t20, _t5, _t23);
        };
    }
    friend fun get_next_adl_address(p0: object::Object<perp_market::PerpMarket>, p1: bool): address
        acquires ADLTracker
    {
        let _t5;
        let _t8 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t2 = borrow_global<ADLTracker>(_t8);
        if (p1) {
            let (_t13,_t14) = big_ordered_map::borrow_back<ADLKey,ADLValue>(&_t2.long_positions);
            let _t4 = _t13;
            _t5 = *&(&_t4).account
        } else {
            let (_t22,_t23) = big_ordered_map::borrow_front<ADLKey,ADLValue>(&_t2.short_positions);
            let _t6 = _t22;
            _t5 = *&(&_t6).account
        };
        _t5
    }
    friend fun remove_position(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: bool, p3: u64)
        acquires ADLTracker
    {
        let _t7 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t4 = borrow_global_mut<ADLTracker>(_t7);
        let _t5 = ADLKey{entry_px: p3, account: p1};
        if (p2) {
            let _t14 = &mut _t4.long_positions;
            let _t15 = &_t5;
            let _t16 = big_ordered_map::remove<ADLKey,ADLValue>(_t14, _t15);
        } else {
            let _t18 = &mut _t4.short_positions;
            let _t19 = &_t5;
            let _t20 = big_ordered_map::remove<ADLKey,ADLValue>(_t18, _t19);
        };
    }
}
