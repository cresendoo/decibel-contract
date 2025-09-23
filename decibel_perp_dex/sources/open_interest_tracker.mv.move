module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::open_interest_tracker {
    use 0x1::object;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::i64;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::clearinghouse_perp;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine;
    struct OpenInterestTracker has key {
        max_open_interest: u64,
        current_open_interest: u64,
    }
    friend fun get_current_open_interest(p0: object::Object<perp_market::PerpMarket>): u64
        acquires OpenInterestTracker
    {
        let _t2 = object::object_address<perp_market::PerpMarket>(&p0);
        *&borrow_global<OpenInterestTracker>(_t2).current_open_interest
    }
    friend fun get_max_open_interest(p0: object::Object<perp_market::PerpMarket>): u64
        acquires OpenInterestTracker
    {
        let _t2 = object::object_address<perp_market::PerpMarket>(&p0);
        *&borrow_global<OpenInterestTracker>(_t2).max_open_interest
    }
    friend fun get_max_open_interest_delta_for_market(p0: object::Object<perp_market::PerpMarket>): u64
        acquires OpenInterestTracker
    {
        let _t3 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t1 = borrow_global<OpenInterestTracker>(_t3);
        let _t7 = *&_t1.current_open_interest;
        let _t10 = *&_t1.max_open_interest;
        if (_t7 >= _t10) return 0;
        let _t16 = *&_t1.max_open_interest;
        let _t19 = *&_t1.current_open_interest;
        _t16 - _t19
    }
    friend fun mark_open_interest_delta_for_market(p0: object::Object<perp_market::PerpMarket>, p1: i64::I64)
        acquires OpenInterestTracker
    {
        let _t4;
        let _t3;
        let _t6 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t2 = borrow_global_mut<OpenInterestTracker>(_t6);
        if (i64::is_positive_or_zero(&p1)) {
            _t3 = i64::amount(&p1);
            _t4 = &mut _t2.current_open_interest;
            *_t4 = *_t4 + _t3
        } else {
            let _t21 = *&_t2.current_open_interest;
            let _t23 = i64::amount(&p1);
            if (_t21 >= _t23) {
                _t3 = i64::amount(&p1);
                _t4 = &mut _t2.current_open_interest;
                *_t4 = *_t4 - _t3
            } else abort 0
        };
    }
    friend fun register_open_interest_tracker(p0: &signer, p1: u64) {
        let _t5 = OpenInterestTracker{max_open_interest: p1, current_open_interest: 0};
        move_to<OpenInterestTracker>(p0, _t5);
    }
    friend fun set_max_open_interest(p0: object::Object<perp_market::PerpMarket>, p1: u64)
        acquires OpenInterestTracker
    {
        let _t4 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t2 = &mut borrow_global_mut<OpenInterestTracker>(_t4).max_open_interest;
        *_t2 = p1;
    }
}
