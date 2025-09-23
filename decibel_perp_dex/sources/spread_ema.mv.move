module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::spread_ema {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::decibel_time;
    use 0x1::error;
    use 0x1::fixed_point32;
    use 0x1::math_fixed;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::i64;
    use 0x1::option;
    struct SpreadEMA has copy, drop, store {
        lhs_ema: u128,
        rhs_ema: u128,
        lookback_window_seconds: u64,
        last_observation_time: u64,
        observation_count: u64,
    }
    public fun add_observation(p0: &mut SpreadEMA, p1: u64, p2: u64) {
        let _t3 = decibel_time::now_seconds();
        add_observation_with_time(p0, p1, p2, _t3);
    }
    public fun add_observation_with_time(p0: &mut SpreadEMA, p1: u64, p2: u64, p3: u64) {
        let _t6;
        let _t4 = (p1 as u128) * 100000000u128;
        let _t5 = (p2 as u128) * 100000000u128;
        if (*&p0.observation_count > 0) {
            let _t37 = *&p0.last_observation_time;
            _t6 = p3 <= _t37
        } else _t6 = false;
        loop {
            if (!_t6) {
                if (*&p0.observation_count == 0) {
                    let _t7 = &mut p0.lhs_ema;
                    *_t7 = _t4;
                    _t7 = &mut p0.rhs_ema;
                    *_t7 = _t5;
                    break
                };
                let _t67 = *&p0.lookback_window_seconds;
                let _t71 = *&p0.last_observation_time;
                let _t72 = p3 - _t71;
                let _t9 = calculate_alpha(_t67, _t72);
                let _t77 = _t9 as u256;
                let _t79 = _t4 as u256;
                let _t12 = (_t77 * _t79 / 100000000u256) as u128;
                let _t13 = 100000000u128 - _t9;
                let _t14 = *&p0.lhs_ema;
                let _t91 = _t13 as u256;
                let _t93 = _t14 as u256;
                let _t15 = (_t91 * _t93 / 100000000u256) as u128;
                let _t100 = _t12 + _t15;
                let _t102 = &mut p0.lhs_ema;
                *_t102 = _t100;
                let _t106 = _t9 as u256;
                let _t108 = _t5 as u256;
                let _t17 = (_t106 * _t108 / 100000000u256) as u128;
                let _t18 = 100000000u128 - _t9;
                let _t19 = *&p0.rhs_ema;
                let _t120 = _t18 as u256;
                let _t122 = _t19 as u256;
                let _t20 = (_t120 * _t122 / 100000000u256) as u128;
                let _t129 = _t17 + _t20;
                let _t131 = &mut p0.rhs_ema;
                *_t131 = _t129;
                break
            };
            return ()
        };
        let _t8 = &mut p0.last_observation_time;
        *_t8 = p3;
        _t8 = &mut p0.observation_count;
        *_t8 = *_t8 + 1;
    }
    fun calculate_alpha(p0: u64, p1: u64): u128 {
        let _t6 = 18 * p0;
        if (p1 > _t6) return 100000000u128;
        let _t2 = math_fixed::exp(fixed_point32::create_from_rational(p1, p0));
        let _t17 = fixed_point32::divide_u64(100000000, _t2) as u128;
        100000000u128 - _t17
    }
    public fun get_current_spread(p0: &SpreadEMA): i64::I64 {
        if (*&p0.observation_count == 0) return i64::zero();
        let _t15 = (*&p0.lhs_ema / 100000000u128) as u64;
        let _t21 = (*&p0.rhs_ema / 100000000u128) as u64;
        i64::new_from_subtraction(_t15, _t21)
    }
    public fun get_last_observation_time(p0: &SpreadEMA): option::Option<u64> {
        let _t1;
        if (*&p0.observation_count > 0) _t1 = option::some<u64>(*&p0.last_observation_time) else _t1 = option::none<u64>();
        _t1
    }
    public fun get_lookback_window(p0: &SpreadEMA): u64 {
        *&p0.lookback_window_seconds
    }
    public fun get_observation_count(p0: &SpreadEMA): u64 {
        *&p0.observation_count
    }
    public fun new_ema(p0: u64): SpreadEMA {
        if (!(p0 >= 10)) {
            let _t16 = error::invalid_argument(1);
            abort _t16
        };
        if (!(p0 <= 31536000)) {
            let _t14 = error::invalid_argument(1);
            abort _t14
        };
        SpreadEMA{lhs_ema: 0u128, rhs_ema: 0u128, lookback_window_seconds: p0, last_observation_time: 0, observation_count: 0}
    }
    public fun update_lookback_window(p0: &mut SpreadEMA, p1: u64) {
        if (!(p1 >= 10)) {
            let _t18 = error::invalid_argument(1);
            abort _t18
        };
        if (!(p1 <= 31536000)) {
            let _t15 = error::invalid_argument(1);
            abort _t15
        };
        let _t2 = &mut p0.lookback_window_seconds;
        *_t2 = p1;
    }
}
