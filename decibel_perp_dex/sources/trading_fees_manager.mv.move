module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::trading_fees_manager {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::volume_tracker;
    use 0x1::signer;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::builder_code_registry;
    use 0x1::error;
    use 0x1::option;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::fee_distribution;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::i64;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::accounts_collateral;
    struct GlobalState has key {
        volume_stats: volume_tracker::VolumeStats,
        fee_config: TradingFeeConfiguration,
    }
    struct TradingFeeConfiguration has drop, store {
        tier_thresholds: vector<u128>,
        tier_maker_fees: vector<u64>,
        tier_taker_fees: vector<u64>,
        market_maker_absolute_threshold: u128,
        market_maker_tier_pct_thresholds: vector<u64>,
        market_maker_tier_fee_rebates: vector<u64>,
        builder_max_fee: u64,
        backstop_vault_fee_pct: u64,
    }
    friend fun initialize(p0: &signer) {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) {
            let _t22 = error::invalid_argument(1);
            abort _t22
        };
        let _t9 = volume_tracker::initialize();
        let _t1 = create_default_config();
        let _t14 = *&(&_t1).builder_max_fee;
        builder_code_registry::initialize(p0, _t14);
        let _t4 = GlobalState{volume_stats: _t9, fee_config: _t1};
        move_to<GlobalState>(p0, _t4);
    }
    fun create_default_config(): TradingFeeConfiguration {
        TradingFeeConfiguration{tier_thresholds: vector[5000000u128, 25000000u128, 100000000u128, 500000000u128, 2000000000u128], tier_maker_fees: vector[100, 50, 0, 0, 0, 0], tier_taker_fees: vector[350, 300, 250, 230, 200, 180], market_maker_absolute_threshold: 150000000u128, market_maker_tier_pct_thresholds: vector[50, 100, 200], market_maker_tier_fee_rebates: vector[0, 10, 20, 30], builder_max_fee: 1000, backstop_vault_fee_pct: 0}
    }
    public fun get_global_volume(): u128
        acquires GlobalState
    {
        volume_tracker::get_global_volume(&mut borrow_global_mut<GlobalState>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).volume_stats)
    }
    public fun get_maker_volume(p0: address): u128
        acquires GlobalState
    {
        volume_tracker::get_maker_volume(&mut borrow_global_mut<GlobalState>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).volume_stats, p0)
    }
    public fun get_taker_volume(p0: address): u128
        acquires GlobalState
    {
        volume_tracker::get_taker_volume(&mut borrow_global_mut<GlobalState>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).volume_stats, p0)
    }
    friend fun track_taker_volume(p0: address, p1: u128)
        acquires GlobalState
    {
        volume_tracker::track_taker_volume(&mut borrow_global_mut<GlobalState>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).volume_stats, p0, p1);
    }
    friend fun track_volume(p0: address, p1: address, p2: u128)
        acquires GlobalState
    {
        volume_tracker::track_volume(&mut borrow_global_mut<GlobalState>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).volume_stats, p0, p1, p2);
    }
    friend fun get_maker_fee_for_notional(p0: address, p1: address, p2: u128, p3: option::Option<builder_code_registry::BuilderCode>): fee_distribution::FeeDistribution
        acquires GlobalState
    {
        let _t17;
        let _t16;
        let _t14;
        let _t11;
        let _t7;
        let (_t20,_t21,_t22) = get_maker_fees_and_backstop_pct(p0);
        let _t5 = _t21;
        let _t6 = _t20;
        if (_t6 != 0) {
            let _t12;
            let _t28 = _t6 as u128;
            _t7 = (p2 * _t28 / 1000000u128) as u64;
            let _t10 = p3;
            if (option::is_some<builder_code_registry::BuilderCode>(&_t10)) {
                _t11 = option::destroy_some<builder_code_registry::BuilderCode>(_t10);
                _t12 = builder_code_registry::get_builder_fee_for_notional(p0, _t11, p2)
            } else _t12 = 0;
            if (_t7 > _t12) _t14 = i64::new_negative(_t7 - _t12) else _t14 = i64::new_positive(_t12 - _t7);
            if (_t12 > 0) _t16 = option::some<fee_distribution::FeeWithDestination>(fee_distribution::new_fee_with_destination(builder_code_registry::get_builder_from_builder_code(option::borrow<builder_code_registry::BuilderCode>(&p3)), _t12)) else _t16 = option::none<fee_distribution::FeeWithDestination>();
            _t17 = fee_distribution::new_fee_distribution(p1, _t14, 0, _t16)
        } else {
            let _t76 = _t5 as u128;
            _t6 = (p2 * _t76 / 1000000u128) as u64;
            let _t18 = p3;
            if (option::is_some<builder_code_registry::BuilderCode>(&_t18)) {
                _t11 = option::destroy_some<builder_code_registry::BuilderCode>(_t18);
                _t5 = builder_code_registry::get_builder_fee_for_notional(p0, _t11, p2)
            } else _t5 = 0;
            _t14 = i64::new_positive(_t6 + _t5);
            _t7 = _t6 * _t22 / 100;
            if (_t5 > 0) _t16 = option::some<fee_distribution::FeeWithDestination>(fee_distribution::new_fee_with_destination(builder_code_registry::get_builder_from_builder_code(option::borrow<builder_code_registry::BuilderCode>(&p3)), _t5)) else _t16 = option::none<fee_distribution::FeeWithDestination>();
            _t17 = fee_distribution::new_fee_distribution(p1, _t14, _t7, _t16)
        };
        _t17
    }
    public fun get_maker_fees_and_backstop_pct(p0: address): (u64, u64, u64)
        acquires GlobalState
    {
        let _t7;
        let _t6;
        let _t5;
        let _t1 = borrow_global_mut<GlobalState>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95);
        let _t2 = volume_tracker::get_maker_volume(&mut _t1.volume_stats, p0);
        let _t3 = volume_tracker::get_global_volume(&mut _t1.volume_stats);
        let _t4 = get_market_maker_fee_rebate(&_t1.fee_config, _t2, _t3);
        if (_t4 != 0) {
            _t5 = _t4;
            _t6 = 0;
            _t7 = *&(&_t1.fee_config).backstop_vault_fee_pct
        } else {
            _t5 = 0;
            _t6 = get_maker_fees_for_volume(&_t1.fee_config, _t2);
            _t7 = *&(&_t1.fee_config).backstop_vault_fee_pct
        };
        (_t5, _t6, _t7)
    }
    fun get_market_maker_fee_rebate(p0: &TradingFeeConfiguration, p1: u128, p2: u128): u64 {
        let _t4;
        let _t9 = *&p0.market_maker_absolute_threshold;
        'l0: loop {
            loop {
                if (!(p1 < _t9)) {
                    if (p2 == 0u128) break;
                    if (!(p2 != 0u128)) {
                        let _t55 = error::invalid_argument(4);
                        abort _t55
                    };
                    let _t24 = (p1 as u256) * 10000u256;
                    let _t26 = p2 as u256;
                    let _t3 = ((_t24 / _t26) as u128) as u64;
                    _t4 = 0;
                    loop {
                        let _t5;
                        let _t34 = 0x1::vector::length<u64>(&p0.market_maker_tier_pct_thresholds);
                        if (_t4 < _t34) {
                            let _t41 = *0x1::vector::borrow<u64>(&p0.market_maker_tier_pct_thresholds, _t4);
                            _t5 = _t3 >= _t41
                        } else _t5 = false;
                        if (!_t5) break 'l0;
                        _t4 = _t4 + 1;
                        continue
                    }
                };
                return 0
            };
            return 0
        };
        *0x1::vector::borrow<u64>(&p0.market_maker_tier_fee_rebates, _t4)
    }
    fun get_maker_fees_for_volume(p0: &TradingFeeConfiguration, p1: u128): u64 {
        let _t2 = 0;
        loop {
            let _t3;
            let _t8 = 0x1::vector::length<u128>(&p0.tier_thresholds);
            if (_t2 < _t8) {
                let _t15 = *0x1::vector::borrow<u128>(&p0.tier_thresholds, _t2);
                _t3 = p1 >= _t15
            } else _t3 = false;
            if (!_t3) break;
            _t2 = _t2 + 1;
            continue
        };
        *0x1::vector::borrow<u64>(&p0.tier_maker_fees, _t2)
    }
    friend fun get_taker_fee_for_notional(p0: address, p1: address, p2: u128, p3: option::Option<builder_code_registry::BuilderCode>): fee_distribution::FeeDistribution
        acquires GlobalState
    {
        let _t12;
        let _t8;
        let (_t14,_t15) = get_taker_fees_and_backstop_pct(p0);
        let _t5 = _t14;
        let _t18 = _t5 as u128;
        _t5 = (p2 * _t18 / 1000000u128) as u64;
        let _t6 = p3;
        if (option::is_some<builder_code_registry::BuilderCode>(&_t6)) {
            let _t7 = option::destroy_some<builder_code_registry::BuilderCode>(_t6);
            _t8 = builder_code_registry::get_builder_fee_for_notional(p0, _t7, p2)
        } else _t8 = 0;
        let _t10 = i64::new_positive(_t5 + _t8);
        let _t11 = _t5 * _t15 / 100;
        if (_t8 > 0) _t12 = option::some<fee_distribution::FeeWithDestination>(fee_distribution::new_fee_with_destination(builder_code_registry::get_builder_from_builder_code(option::borrow<builder_code_registry::BuilderCode>(&p3)), _t8)) else _t12 = option::none<fee_distribution::FeeWithDestination>();
        fee_distribution::new_fee_distribution(p1, _t10, _t11, _t12)
    }
    public fun get_taker_fees_and_backstop_pct(p0: address): (u64, u64)
        acquires GlobalState
    {
        let _t1 = borrow_global_mut<GlobalState>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95);
        let _t2 = volume_tracker::get_taker_volume(&mut _t1.volume_stats, p0);
        let _t12 = get_taker_fees_for_volume(&_t1.fee_config, _t2);
        let _t16 = *&(&_t1.fee_config).backstop_vault_fee_pct;
        (_t12, _t16)
    }
    fun get_taker_fees_for_volume(p0: &TradingFeeConfiguration, p1: u128): u64 {
        let _t2 = 0;
        loop {
            let _t3;
            let _t8 = 0x1::vector::length<u128>(&p0.tier_thresholds);
            if (_t2 < _t8) {
                let _t15 = *0x1::vector::borrow<u128>(&p0.tier_thresholds, _t2);
                _t3 = p1 >= _t15
            } else _t3 = false;
            if (!_t3) break;
            _t2 = _t2 + 1;
            continue
        };
        *0x1::vector::borrow<u64>(&p0.tier_taker_fees, _t2)
    }
    friend fun track_global_and_maker_volume(p0: address, p1: u128)
        acquires GlobalState
    {
        volume_tracker::track_volume(&mut borrow_global_mut<GlobalState>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).volume_stats, p0, @0x0, p1);
    }
    friend fun update_fee_config(p0: &signer, p1: vector<u128>, p2: vector<u64>, p3: vector<u64>, p4: u128, p5: vector<u64>, p6: vector<u64>, p7: u64, p8: u64)
        acquires GlobalState
    {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) {
            let _t28 = error::invalid_argument(1);
            abort _t28
        };
        let _t9 = borrow_global_mut<GlobalState>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95);
        let _t24 = TradingFeeConfiguration{tier_thresholds: p1, tier_maker_fees: p2, tier_taker_fees: p3, market_maker_absolute_threshold: p4, market_maker_tier_pct_thresholds: p5, market_maker_tier_fee_rebates: p6, builder_max_fee: p7, backstop_vault_fee_pct: p8};
        let _t26 = &mut _t9.fee_config;
        *_t26 = _t24;
    }
}
