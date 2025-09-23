module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market_config {
    use 0x1::string;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::math;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::oracle;
    use 0x1::object;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market;
    use 0x1::vector;
    use 0x1::error;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_management;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::tp_sl_utils;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::clearinghouse_perp;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::async_matching_engine;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine;
    enum MarketMode has copy, drop, store {
        Open,
        ReduceOnly {
            allowlist: vector<address>,
        }
        AllowlistOnly {
            allowlist: vector<address>,
        }
        Halt,
        Delisting,
    }
    enum PerpMarketConfig has key {
        V1 {
            name: string::String,
            sz_precision: math::Precision,
            min_size: u64,
            lot_size: u64,
            ticker_size: u64,
            max_leverage: u8,
            mode: MarketMode,
            oracle_source: oracle::OracleSource,
        }
    }
    friend fun is_reduce_only(p0: object::Object<perp_market::PerpMarket>, p1: address): bool
        acquires PerpMarketConfig
    {
        let _t3;
        let _t5 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t2 = &borrow_global<PerpMarketConfig>(_t5).mode;
        if (_t2 is Open) _t3 = false else if (_t2 is ReduceOnly) {
            let _t16 = &_t2.allowlist;
            let _t17 = &p1;
            _t3 = !vector::contains<address>(_t16, _t17)
        } else if (_t2 is AllowlistOnly) _t3 = false else if (_t2 is Halt) _t3 = false else if (_t2 is Delisting) _t3 = false else abort 14566554180833181697;
        _t3
    }
    friend fun register_market(p0: &signer, p1: string::String, p2: u8, p3: u64, p4: u64, p5: u64, p6: u8, p7: oracle::OracleSource) {
        if (!(p4 > 0)) abort 2;
        if (!(p3 > 0)) abort 1;
        if (!(p3 % p4 == 0)) abort 1;
        if (!(p5 > 0)) abort 3;
        let _t25 = math::new_precision(p2);
        let _t30 = MarketMode::Open{};
        let _t32 = PerpMarketConfig::V1{name: p1, sz_precision: _t25, min_size: p3, lot_size: p4, ticker_size: p5, max_leverage: p6, mode: _t30, oracle_source: p7};
        move_to<PerpMarketConfig>(p0, _t32);
    }
    friend fun get_oracle_price(p0: object::Object<perp_market::PerpMarket>, p1: math::Precision): u64
        acquires PerpMarketConfig
    {
        let _t3 = object::object_address<perp_market::PerpMarket>(&p0);
        oracle::get_oracle_price(&borrow_global<PerpMarketConfig>(_t3).oracle_source, p1)
    }
    friend fun update_internal_oracle_price(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: u64)
        acquires PerpMarketConfig
    {
        let _t4 = object::object_address<perp_market::PerpMarket>(&p1);
        oracle::update_internal_oracle_price(&mut borrow_global_mut<PerpMarketConfig>(_t4).oracle_source, p0, p2);
    }
    friend fun update_internal_oracle_updater(p0: object::Object<perp_market::PerpMarket>, p1: address)
        acquires PerpMarketConfig
    {
        let _t3 = object::object_address<perp_market::PerpMarket>(&p0);
        oracle::update_internal_oracle_updater(&mut borrow_global_mut<PerpMarketConfig>(_t3).oracle_source, p1);
    }
    friend fun allowlist_only(p0: object::Object<perp_market::PerpMarket>, p1: vector<address>)
        acquires PerpMarketConfig
    {
        if (!(vector::length<address>(&p1) <= 100)) abort 8;
        let _t8 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t2 = borrow_global_mut<PerpMarketConfig>(_t8);
        let _t11 = MarketMode::AllowlistOnly{allowlist: p1};
        let _t13 = &mut _t2.mode;
        *_t13 = _t11;
    }
    friend fun can_place_order(p0: object::Object<perp_market::PerpMarket>, p1: address): bool
        acquires PerpMarketConfig
    {
        let _t3;
        let _t5 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t2 = &borrow_global<PerpMarketConfig>(_t5).mode;
        if (_t2 is Open) _t3 = true else if (_t2 is ReduceOnly) _t3 = true else if (_t2 is AllowlistOnly) {
            let _t20 = &_t2.allowlist;
            let _t21 = &p1;
            _t3 = vector::contains<address>(_t20, _t21)
        } else if (_t2 is Halt) _t3 = false else if (_t2 is Delisting) _t3 = false else abort 14566554180833181697;
        _t3
    }
    friend fun can_settle_order(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: address): bool
        acquires PerpMarketConfig
    {
        let _t4;
        let _t8 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t3 = &borrow_global<PerpMarketConfig>(_t8).mode;
        loop {
            if (_t3 is Open) {
                _t4 = true;
                break
            };
            if (_t3 is ReduceOnly) {
                _t4 = true;
                break
            };
            if (_t3 is AllowlistOnly) {
                let _t5 = &_t3.allowlist;
                let _t25 = &p1;
                if (vector::contains<address>(_t5, _t25)) {
                    _t4 = true;
                    break
                };
                let _t6 = &p2;
                _t4 = vector::contains<address>(_t5, _t6);
                break
            };
            if (_t3 is Halt) {
                _t4 = false;
                break
            };
            if (!(_t3 is Delisting)) abort 14566554180833181697;
            _t4 = false;
            break
        };
        _t4
    }
    friend fun can_update_oracle(p0: object::Object<perp_market::PerpMarket>): bool
        acquires PerpMarketConfig
    {
        let _t2;
        let _t4 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t1 = &borrow_global<PerpMarketConfig>(_t4).mode;
        if (_t1 is Open) _t2 = true else if (_t1 is ReduceOnly) _t2 = true else if (_t1 is AllowlistOnly) _t2 = true else if (_t1 is Halt) _t2 = false else if (_t1 is Delisting) _t2 = false else abort 14566554180833181697;
        _t2
    }
    friend fun delist_market(p0: object::Object<perp_market::PerpMarket>)
        acquires PerpMarketConfig
    {
        let _t3 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t1 = borrow_global_mut<PerpMarketConfig>(_t3);
        let _t5 = MarketMode::Delisting{};
        let _t7 = &mut _t1.mode;
        *_t7 = _t5;
    }
    friend fun get_lot_size(p0: object::Object<perp_market::PerpMarket>): u64
        acquires PerpMarketConfig
    {
        let _t2 = object::object_address<perp_market::PerpMarket>(&p0);
        *&borrow_global<PerpMarketConfig>(_t2).lot_size
    }
    friend fun get_max_leverage(p0: object::Object<perp_market::PerpMarket>): u8
        acquires PerpMarketConfig
    {
        let _t2 = object::object_address<perp_market::PerpMarket>(&p0);
        *&borrow_global<PerpMarketConfig>(_t2).max_leverage
    }
    friend fun get_min_size(p0: object::Object<perp_market::PerpMarket>): u64
        acquires PerpMarketConfig
    {
        let _t2 = object::object_address<perp_market::PerpMarket>(&p0);
        *&borrow_global<PerpMarketConfig>(_t2).min_size
    }
    friend fun get_name(p0: object::Object<perp_market::PerpMarket>): string::String
        acquires PerpMarketConfig
    {
        let _t2 = object::object_address<perp_market::PerpMarket>(&p0);
        *&borrow_global<PerpMarketConfig>(_t2).name
    }
    friend fun get_size_multiplier(p0: object::Object<perp_market::PerpMarket>): u64
        acquires PerpMarketConfig
    {
        let _t1 = get_sz_precision(p0);
        math::get_decimals_multiplier(&_t1)
    }
    friend fun get_sz_precision(p0: object::Object<perp_market::PerpMarket>): math::Precision
        acquires PerpMarketConfig
    {
        let _t2 = object::object_address<perp_market::PerpMarket>(&p0);
        *&borrow_global<PerpMarketConfig>(_t2).sz_precision
    }
    friend fun get_sz_decimals(p0: object::Object<perp_market::PerpMarket>): u8
        acquires PerpMarketConfig
    {
        let _t2 = object::object_address<perp_market::PerpMarket>(&p0);
        math::get_decimals(&borrow_global<PerpMarketConfig>(_t2).sz_precision)
    }
    friend fun get_ticker_size(p0: object::Object<perp_market::PerpMarket>): u64
        acquires PerpMarketConfig
    {
        let _t2 = object::object_address<perp_market::PerpMarket>(&p0);
        *&borrow_global<PerpMarketConfig>(_t2).ticker_size
    }
    friend fun halt_market(p0: object::Object<perp_market::PerpMarket>)
        acquires PerpMarketConfig
    {
        let _t3 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t1 = borrow_global_mut<PerpMarketConfig>(_t3);
        let _t5 = MarketMode::Halt{};
        let _t7 = &mut _t1.mode;
        *_t7 = _t5;
    }
    friend fun is_market_delisted(p0: object::Object<perp_market::PerpMarket>): bool
        acquires PerpMarketConfig
    {
        let _t3 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t5 = &borrow_global<PerpMarketConfig>(_t3).mode;
        let _t1 = MarketMode::Delisting{};
        let _t7 = &_t1;
        _t5 == _t7
    }
    friend fun round_price_to_ticker(p0: object::Object<perp_market::PerpMarket>, p1: u64, p2: bool): u64
        acquires PerpMarketConfig
    {
        let _t7;
        let _t3 = get_ticker_size(p0);
        let _t4 = _t3;
        if (p2) {
            let _t5 = p1;
            let _t6 = _t4;
            if (_t5 == 0) if (_t6 != 0) _t7 = 0 else {
                let _t25 = error::invalid_argument(4);
                abort _t25
            } else _t7 = (_t5 - 1) / _t6 + 1
        } else _t7 = p1 / _t4;
        _t7 * _t3
    }
    friend fun set_max_leverage(p0: object::Object<perp_market::PerpMarket>, p1: u8)
        acquires PerpMarketConfig
    {
        let _t4 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t2 = &mut borrow_global_mut<PerpMarketConfig>(_t4).max_leverage;
        *_t2 = p1;
    }
    friend fun set_open(p0: object::Object<perp_market::PerpMarket>)
        acquires PerpMarketConfig
    {
        let _t3 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t1 = borrow_global_mut<PerpMarketConfig>(_t3);
        let _t5 = MarketMode::Open{};
        let _t7 = &mut _t1.mode;
        *_t7 = _t5;
    }
    friend fun set_reduce_only(p0: object::Object<perp_market::PerpMarket>, p1: vector<address>)
        acquires PerpMarketConfig
    {
        let _t4 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t2 = borrow_global_mut<PerpMarketConfig>(_t4);
        let _t7 = MarketMode::ReduceOnly{allowlist: p1};
        let _t9 = &mut _t2.mode;
        *_t9 = _t7;
    }
    friend fun validate_price(p0: object::Object<perp_market::PerpMarket>, p1: u64)
        acquires PerpMarketConfig
    {
        let _t4 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t2 = borrow_global<PerpMarketConfig>(_t4);
        if (!(p1 > 0)) abort 10;
        let _t12 = *&_t2.ticker_size;
        if (!(p1 % _t12 == 0)) abort 6;
    }
    friend fun validate_price_and_size(p0: object::Object<perp_market::PerpMarket>, p1: u64, p2: u64)
        acquires PerpMarketConfig
    {
        let _t9 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t3 = borrow_global<PerpMarketConfig>(_t9);
        let _t5 = p1;
        if (!(_t5 > 0)) abort 10;
        let _t19 = *&_t3.ticker_size;
        if (!(_t5 % _t19 == 0)) abort 6;
        let _t6 = _t3;
        let _t7 = p2;
        if (!(_t7 > 0)) abort 11;
        let _t31 = *&_t6.lot_size;
        if (!(_t7 % _t31 == 0)) abort 5;
        let _t38 = *&_t6.min_size;
        if (!(_t7 >= _t38)) abort 4;
        let _t41 = p1 as u128;
        let _t43 = p2 as u128;
        let _t44 = _t41 * _t43;
        let _t49 = math::get_decimals_multiplier(&_t3.sz_precision) as u128;
        let _t50 = 18446744073709551615u128 * _t49;
        if (!(_t44 <= _t50)) abort 12;
    }
    friend fun validate_price_and_size_allow_below_min_size(p0: object::Object<perp_market::PerpMarket>, p1: u64, p2: u64)
        acquires PerpMarketConfig
    {
        let _t9 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t3 = borrow_global<PerpMarketConfig>(_t9);
        let _t5 = p1;
        if (!(_t5 > 0)) abort 10;
        let _t19 = *&_t3.ticker_size;
        if (!(_t5 % _t19 == 0)) abort 6;
        let _t7 = p2;
        if (!(_t7 > 0)) abort 11;
        let _t31 = *&_t3.lot_size;
        if (!(_t7 % _t31 == 0)) abort 5;
        let _t41 = p1 as u128;
        let _t43 = p2 as u128;
        let _t44 = _t41 * _t43;
        let _t49 = math::get_decimals_multiplier(&_t3.sz_precision) as u128;
        let _t50 = 18446744073709551615u128 * _t49;
        if (!(_t44 <= _t50)) abort 12;
    }
    friend fun validate_size(p0: object::Object<perp_market::PerpMarket>, p1: u64)
        acquires PerpMarketConfig
    {
        let _t4 = object::object_address<perp_market::PerpMarket>(&p0);
        let _t2 = borrow_global<PerpMarketConfig>(_t4);
        if (!(p1 > 0)) abort 11;
        let _t12 = *&_t2.lot_size;
        if (!(p1 % _t12 == 0)) abort 5;
    }
}
