module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_management {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::spread_ema;
    use 0x1::object;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::decibel_time;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::i64;
    use 0x1::math64;
    use 0x1::error;
    use 0x1::signer;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market_config;
    use 0x1::event;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::accounts_collateral;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::tp_sl_utils;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::clearinghouse_perp;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::liquidation;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::async_matching_engine;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine;
    struct Price has drop, key {
        last_updated: u64,
        oracle_px: u64,
        mark_px: u64,
        size_multiplier: u64,
        accumulative_index: AccumulativeIndex,
        oracle_150_spread_ema: spread_ema::SpreadEMA,
        oracle_30_spread_ema: spread_ema::SpreadEMA,
        basis_30_spread_ema: spread_ema::SpreadEMA,
    }
    struct AccumulativeIndex has copy, drop, store {
        index: u128,
    }
    enum PriceIndexStore has key {
        V1 {
            interest_rate: u64,
        }
    }
    struct PriceUpdateEvent has drop, store {
        market: object::Object<perp_market::PerpMarket>,
        oracle_px: u64,
        mark_px: u64,
        impact_ask_px: u64,
        impact_bid_px: u64,
        funding_index: u128,
        funding_rate_bps: u64,
        is_funding_positive: bool,
    }
    friend fun accumulative_index(p0: &AccumulativeIndex): u128 {
        *&p0.index
    }
    friend fun register_market(p0: &signer, p1: u64, p2: u64) {
        let _t4 = decibel_time::now_microseconds();
        let _t9 = AccumulativeIndex{index: 170141183460469231731687303715884105727u128};
        let _t11 = spread_ema::new_ema(150);
        let _t13 = spread_ema::new_ema(30);
        let _t15 = spread_ema::new_ema(30);
        let _t16 = Price{last_updated: _t4, oracle_px: p1, mark_px: p1, size_multiplier: p2, accumulative_index: _t9, oracle_150_spread_ema: _t11, oracle_30_spread_ema: _t13, basis_30_spread_ema: _t15};
        move_to<Price>(p0, _t16);
    }
    friend fun get_oracle_price(p0: object::Object<perp_market::PerpMarket>): u64
        acquires Price
    {
        let _t2 = object::object_address<perp_market::PerpMarket>(&p0);
        *&borrow_global<Price>(_t2).oracle_px
    }
    fun calculate_funding_rate(p0: &Price, p1: u64, p2: u64, p3: u64, p4: u64): i64::I64 {
        let _t7;
        let _t16 = i64::new_from_subtraction(p2, p1);
        let _t19 = i64::new_from_subtraction(p1, p3);
        let _t5 = i64::new_positive(0);
        let _t8 = i64::max(_t16, _t5);
        let _t24 = &mut _t8;
        let _t27 = i64::max(_t19, _t5);
        i64::sub_inplace(_t24, _t27);
        let _t9 = _t8;
        i64::mul_div_inplace(&mut _t9, 1000000, p1);
        let _t10 = i64::new_positive(p4);
        i64::sub_inplace(&mut _t10, _t9);
        let (_t37,_t38) = i64::into_inner(_t10);
        let _t40 = math64::min(_t38, 500);
        let _t12 = i64::new(_t37, _t40);
        i64::add_inplace(&mut _t12, _t9);
        let (_t45,_t46) = i64::into_inner(_t12);
        p1 = _t46;
        let _t11 = _t45;
        if (p1 > 40000) _t7 = i64::new(_t11, 40000) else _t7 = i64::new(_t11, p1);
        _t7
    }
    fun calculate_mark_px(p0: u64, p1: u64, p2: u64): u64 {
        ((p1 + p2) / 2 + p0) / 2
    }
    friend fun get_accumulative_index(p0: object::Object<perp_market::PerpMarket>): AccumulativeIndex
        acquires Price
    {
        let _t2 = object::object_address<perp_market::PerpMarket>(&p0);
        *&borrow_global<Price>(_t2).accumulative_index
    }
    friend fun get_funding_cost(p0: &AccumulativeIndex, p1: &AccumulativeIndex, p2: u64, p3: u64, p4: bool): i64::I64 {
        let _t12;
        let _t6;
        let _t5;
        let _t16 = *&p1.index;
        let _t19 = *&p0.index;
        if (_t16 >= _t19) {
            _t5 = p4;
            let _t24 = *&p1.index;
            let _t27 = *&p0.index;
            _t6 = _t24 - _t27
        } else {
            _t5 = !p4;
            let _t69 = *&p0.index;
            let _t72 = *&p1.index;
            _t6 = _t69 - _t72
        };
        let _t32 = p2 as u128;
        let _t8 = _t6 * _t32;
        let _t9 = (p3 as u128) * 1000000u128;
        if (_t5) {
            let _t10 = _t8;
            let _t11 = _t9;
            if (_t10 == 0u128) if (_t11 != 0u128) _t12 = 0u128 else {
                let _t54 = error::invalid_argument(4);
                abort _t54
            } else _t12 = (_t10 - 1u128) / _t11 + 1u128
        } else _t12 = _t8 / _t9;
        let _t13 = _t12 as u64;
        i64::new(_t5, _t13)
    }
    friend fun get_mark_and_oracle_price(p0: object::Object<perp_market::PerpMarket>): (u64, u64)
        acquires Price
    {
        let _t3 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t1 = borrow_global<Price>(_t3);
        let _t7 = *&_t1.mark_px;
        let _t10 = *&_t1.oracle_px;
        (_t7, _t10)
    }
    friend fun get_mark_price(p0: object::Object<perp_market::PerpMarket>): u64
        acquires Price
    {
        let _t2 = object::object_address<perp_market::PerpMarket>(&p0);
        *&borrow_global<Price>(_t2).mark_px
    }
    friend fun get_market_info_for_pnl_calculation(p0: object::Object<perp_market::PerpMarket>): (u64, AccumulativeIndex, u64)
        acquires Price
    {
        let _t3 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t1 = borrow_global<Price>(_t3);
        let _t7 = *&_t1.mark_px;
        let _t10 = *&_t1.accumulative_index;
        let _t13 = *&_t1.size_multiplier;
        (_t7, _t10, _t13)
    }
    fun get_median_price(p0: u64, p1: u64, p2: u64): u64 {
        let _t3;
        loop {
            if (p0 >= p1) {
                if (p1 >= p2) {
                    _t3 = p1;
                    break
                };
                if (p0 >= p2) {
                    _t3 = p2;
                    break
                };
                _t3 = p0;
                break
            };
            if (p0 >= p2) {
                _t3 = p0;
                break
            };
            if (p1 >= p2) {
                _t3 = p2;
                break
            };
            _t3 = p1;
            break
        };
        _t3
    }
    friend fun new_price_management(p0: &signer) {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) {
            let _t10 = error::invalid_argument(1);
            abort _t10
        };
        let _t7 = PriceIndexStore::V1{interest_rate: 12};
        move_to<PriceIndexStore>(p0, _t7);
    }
    friend fun override_mark_price(p0: object::Object<perp_market::PerpMarket>, p1: u64)
        acquires Price
    {
        if (!perp_market_config::is_market_delisted(p0)) abort 3;
        let _t7 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t2 = borrow_global_mut<Price>(_t7);
        let _t3 = &mut _t2.mark_px;
        *_t3 = p1;
        let _t21 = *&(&_t2.accumulative_index).index;
        event::emit<PriceUpdateEvent>(PriceUpdateEvent{market: p0, oracle_px: p1, mark_px: p1, impact_ask_px: p1, impact_bid_px: p1, funding_index: _t21, funding_rate_bps: 0, is_funding_positive: true});
    }
    friend fun set_interest_rate(p0: &signer, p1: u64)
        acquires PriceIndexStore
    {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) {
            let _t13 = error::invalid_argument(1);
            abort _t13
        };
        let _t2 = &mut borrow_global_mut<PriceIndexStore>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).interest_rate;
        *_t2 = p1;
    }
    friend fun update_accumulative_index(p0: &mut Price, p1: u64, p2: u64, p3: u64, p4: u64, p5: u64): i64::I64 {
        let _t11;
        let (_t20,_t21) = i64::into_inner(calculate_funding_rate(freeze(p0), p1, p2, p3, p4));
        p2 = _t21;
        let _t6 = _t20;
        let _t25 = *&p0.last_updated;
        p3 = p5 - _t25;
        let _t28 = p2 as u128;
        let _t30 = p3 as u128;
        let _t7 = _t28 * _t30;
        let _t8 = p1 as u128;
        let _t35 = _t7 as u256;
        let _t37 = _t8 as u256;
        let _t9 = (_t35 * _t37 / 3600000000u256) as u128;
        if (_t6) {
            _t11 = &mut (&mut p0.accumulative_index).index;
            *_t11 = *_t11 + _t9
        } else {
            _t11 = &mut (&mut p0.accumulative_index).index;
            *_t11 = *_t11 - _t9
        };
        let _t12 = &mut p0.last_updated;
        *_t12 = p5;
        _t12 = &mut p0.oracle_px;
        *_t12 = p1;
        i64::new(_t6, p2)
    }
    fun update_mark_px(p0: &mut Price, p1: u64, p2: u64) {
        let _t11;
        let _t8;
        let _t5;
        let _t3 = p1;
        let (_t16,_t17) = i64::into_inner(spread_ema::get_current_spread(&p0.oracle_150_spread_ema));
        let _t4 = _t17;
        if (_t16) _t5 = _t3 + _t4 else if (_t4 > _t3) _t5 = 0 else _t5 = _t3 - _t4;
        let _t6 = p1;
        let (_t25,_t26) = i64::into_inner(spread_ema::get_current_spread(&p0.oracle_30_spread_ema));
        let _t7 = _t26;
        if (_t25) _t8 = _t6 + _t7 else if (_t7 > _t6) _t8 = 0 else _t8 = _t6 - _t7;
        let _t9 = p2;
        let (_t34,_t35) = i64::into_inner(spread_ema::get_current_spread(&p0.basis_30_spread_ema));
        let _t10 = _t35;
        if (_t34) _t11 = _t9 + _t10 else if (_t10 > _t9) _t11 = 0 else _t11 = _t9 - _t10;
        let _t42 = get_median_price(_t5, _t8, _t11);
        let _t44 = &mut p0.mark_px;
        *_t44 = _t42;
    }
    friend fun update_price(p0: object::Object<perp_market::PerpMarket>, p1: u64, p2: u64, p3: u64)
        acquires Price
        acquires PriceIndexStore
    {
        let _t11;
        if (!perp_market_config::can_update_oracle(p0)) abort 2;
        let _t4 = *&borrow_global<PriceIndexStore>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).interest_rate;
        let _t21 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t5 = borrow_global_mut<Price>(_t21);
        let _t6 = decibel_time::now_microseconds();
        let _t26 = *&_t5.last_updated;
        loop {
            if (!(_t26 == _t6)) {
                let _t10;
                let _t7 = (p2 + p3) / 2;
                let _t36 = perp_market_config::get_max_leverage(p0);
                let _t8 = p1;
                let _t9 = _t36 as u64;
                if (_t8 == 0) if (_t9 != 0) _t10 = 0 else {
                    let _t94 = error::invalid_argument(4);
                    abort _t94
                } else _t10 = (_t8 - 1) / _t9 + 1;
                let _t49 = p1 + _t10;
                if (_t7 > _t49) {
                    _t11 = p1 + _t10;
                    break
                };
                let _t86 = p1 - _t10;
                if (_t7 < _t86) {
                    _t11 = p1 - _t10;
                    break
                };
                _t11 = _t7;
                break
            };
            return ()
        };
        update_mark_px(_t5, p1, _t11);
        update_spread_emas(_t5, p1, _t11);
        let (_t67,_t68) = i64::into_inner(update_accumulative_index(_t5, p1, p2, p3, _t4, _t6));
        let _t73 = *&_t5.mark_px;
        let _t79 = *&(&_t5.accumulative_index).index;
        event::emit<PriceUpdateEvent>(PriceUpdateEvent{market: p0, oracle_px: p1, mark_px: _t73, impact_ask_px: p3, impact_bid_px: p2, funding_index: _t79, funding_rate_bps: _t68, is_funding_positive: _t67});
    }
    fun update_spread_emas(p0: &mut Price, p1: u64, p2: u64) {
        spread_ema::add_observation(&mut p0.oracle_150_spread_ema, p2, p1);
        spread_ema::add_observation(&mut p0.oracle_30_spread_ema, p2, p1);
        let _t12 = &mut p0.basis_30_spread_ema;
        let _t15 = *&p0.mark_px;
        spread_ema::add_observation(_t12, _t15, p2);
    }
}
