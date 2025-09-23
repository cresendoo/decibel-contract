module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::i64;
    use 0x1::option;
    use 0x1::ordered_map;
    use 0x1::object;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::position_tp_sl_tracker;
    use 0x7::order_book_types;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_management;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::fee_distribution;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::trading_fees_manager;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::liquidation_config;
    use 0x1::error;
    use 0x1::vector;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::collateral_balance_sheet;
    use 0x1::signer;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market_config;
    use 0x1::bcs;
    use 0x1::event;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::builder_code_registry;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::math;
    use 0x1::math64;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::adl_tracker;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::accounts_collateral;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::tp_sl_utils;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::clearinghouse_perp;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::liquidation;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::async_matching_engine;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine;
    struct AccountInfo has key {
        fee_tracking_addr: address,
    }
    struct AccountStatus has drop {
        account_balance: i64::I64,
        initial_margin: u64,
        total_notional_value: u64,
    }
    struct AccountStatusDetailed has drop {
        account_balance: i64::I64,
        initial_margin: u64,
        liquidation_margin: u64,
        backstop_liquidator_margin: u64,
        total_notional_value: u64,
    }
    enum Action has copy, drop, store {
        OpenLong,
        CloseLong,
        OpenShort,
        CloseShort,
        Net,
    }
    struct CrossedPosition has key {
        positions: vector<PerpPosition>,
    }
    struct PerpPosition has copy, drop, store {
        size: u64,
        entry_px_times_size_sum: u128,
        avg_acquire_entry_px: u64,
        user_leverage: u8,
        max_allowed_leverage: u8,
        is_long: bool,
        funding_index_at_last_update: price_management::AccumulativeIndex,
        unrealized_funding_amount_before_last_update: i64::I64,
        market: object::Object<perp_market::PerpMarket>,
        tp_reqs: PendingTpSLs,
        sl_reqs: PendingTpSLs,
    }
    struct PendingTpSLs has copy, drop, store {
        full_sized: option::Option<PendingTpSlKey>,
        fixed_sized: vector<PendingTpSlKey>,
    }
    struct FixedSizedTpSlForEvent has copy, drop, store {
        order_id: u128,
        trigger_price: u64,
        limit_price: option::Option<u64>,
        size: u64,
    }
    struct FullSizedTpSlForEvent has copy, drop, store {
        order_id: u128,
        trigger_price: u64,
        limit_price: option::Option<u64>,
    }
    struct IsolatedPosition has key {
        position: PerpPosition,
    }
    struct IsolatedPositionRefs has key {
        extend_refs: ordered_map::OrderedMap<object::Object<perp_market::PerpMarket>, object::ExtendRef>,
    }
    struct PendingTpSlKey has copy, drop, store {
        price_index: position_tp_sl_tracker::PriceIndexKey,
        order_id: order_book_types::OrderIdType,
    }
    struct PositionPendingTpSL has copy, drop {
        order_id: order_book_types::OrderIdType,
        trigger_price: u64,
        account: address,
        limit_price: option::Option<u64>,
        size: option::Option<u64>,
    }
    struct PositionUpdateEvent has copy, drop, store {
        market: object::Object<perp_market::PerpMarket>,
        user: address,
        is_long: bool,
        size: u64,
        user_leverage: u8,
        max_allowed_leverage: u8,
        entry_price_times_size_sum: u128,
        is_isolated: bool,
        funding_index_at_last_update: u128,
        unrealized_funding_amount_before_last_update: u64,
        is_unrealized_funding_amount_before_last_update_positive: bool,
        full_sized_tp: option::Option<FullSizedTpSlForEvent>,
        fixed_sized_tps: vector<FixedSizedTpSlForEvent>,
        full_sized_sl: option::Option<FullSizedTpSlForEvent>,
        fixed_sized_sls: vector<FixedSizedTpSlForEvent>,
    }
    enum ReduceOnlyValidationResult has drop {
        ReduceOnlyViolation,
        Success {
            size: u64,
        }
    }
    struct TradeEvent has drop, store {
        account: address,
        market: object::Object<perp_market::PerpMarket>,
        action: Action,
        size: u64,
        price: u64,
        is_profit: bool,
        realized_pnl_amount: u64,
        is_funding_positive: bool,
        realized_funding_amount: u64,
        is_rebate: bool,
        fee_amount: u64,
    }
    enum UpdatePositionResult has copy, drop {
        Liquidatable,
        InsufficientMargin,
        InvalidLeverage,
        Success {
            account: address,
            market: object::Object<perp_market::PerpMarket>,
            is_isolated: bool,
            position_address: address,
            margin_delta: option::Option<i64::I64>,
            backstop_liquidator_covered_loss: u64,
            fee_distribution: fee_distribution::FeeDistribution,
            realized_pnl: option::Option<i64::I64>,
            realized_funding_cost: option::Option<i64::I64>,
            unrealized_funding_cost: i64::I64,
            updated_funding_index: price_management::AccumulativeIndex,
            volume_delta: u128,
            is_taker: bool,
        }
    }
    public fun is_long(p0: &PerpPosition): bool {
        *&p0.is_long
    }
    public fun get_market(p0: &PerpPosition): object::Object<perp_market::PerpMarket> {
        *&p0.market
    }
    friend fun track_volume(p0: address, p1: bool, p2: u128)
        acquires AccountInfo
    {
        p0 = *&borrow_global<AccountInfo>(p0).fee_tracking_addr;
        if (p1) trading_fees_manager::track_taker_volume(p0, p2) else trading_fees_manager::track_global_and_maker_volume(p0, p2);
    }
    friend fun account_initialized(p0: address): bool {
        exists<CrossedPosition>(p0)
    }
    friend fun add_liquidation_details(p0: AccountStatus, p1: &liquidation_config::LiquidationConfig): AccountStatusDetailed {
        let AccountStatus{account_balance: _t5, initial_margin: _t6, total_notional_value: _t7} = p0;
        let _t3 = _t6;
        let _t12 = liquidation_config::get_liquidation_margin(p1, _t3, false);
        let _t16 = liquidation_config::get_liquidation_margin(p1, _t3, true);
        AccountStatusDetailed{account_balance: _t5, initial_margin: _t3, liquidation_margin: _t12, backstop_liquidator_margin: _t16, total_notional_value: _t7}
    }
    friend fun add_sl(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: order_book_types::OrderIdType, p3: u64, p4: option::Option<u64>, p5: option::Option<u64>)
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        add_tp_sl(p0, p1, p2, p3, p4, p5, false);
    }
    friend fun add_tp_sl(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: order_book_types::OrderIdType, p3: u64, p4: option::Option<u64>, p5: option::Option<u64>, p6: bool)
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t11;
        let _t9;
        let _t7 = p0;
        let _t8 = p1;
        let _t25 = isolated_position_address(_t7, _t8);
        if (exists<IsolatedPosition>(_t25)) {
            let _t29 = isolated_position_address(_t7, _t8);
            _t9 = &mut borrow_global_mut<IsolatedPosition>(_t29).position
        } else {
            let _t14 = &mut borrow_global_mut<CrossedPosition>(_t7).positions;
            let _t15 = freeze(_t14);
            let _t16 = false;
            let _t17 = 0;
            let _t18 = 0;
            let _t19 = vector::length<PerpPosition>(_t15);
            'l0: loop {
                loop {
                    if (!(_t18 < _t19)) break 'l0;
                    let _t152 = &vector::borrow<PerpPosition>(_t15, _t18).market;
                    let _t153 = &_t8;
                    if (_t152 == _t153) break;
                    _t18 = _t18 + 1;
                    continue
                };
                _t16 = true;
                _t17 = _t18;
                break
            };
            if (_t16) _t9 = vector::borrow_mut<PerpPosition>(_t14, _t17) else {
                let _t165 = error::invalid_argument(7);
                abort _t165
            }
        };
        if (!validate_tp_sl_internal(freeze(_t9), p3, p6)) {
            let _t135 = error::invalid_argument(15);
            abort _t135
        };
        let _t10 = is_position_isolated(p0, p1);
        if (_t10) _t11 = isolated_position_address(p0, p1) else _t11 = p0;
        let _t48 = option::is_none<u64>(&p5);
        let _t12 = position_tp_sl_tracker::new_price_index_key(p3, _t11, p4, _t48);
        let _t13 = PendingTpSlKey{price_index: _t12, order_id: p2};
        let _t54 = option::is_none<u64>(&p5);
        loop {
            if (_t54) {
                if (p6) {
                    if (!option::is_none<PendingTpSlKey>(&(&_t9.tp_reqs).full_sized)) {
                        let _t83 = error::invalid_argument(19);
                        abort _t83
                    };
                    let _t61 = option::some<PendingTpSlKey>(_t13);
                    let _t64 = &mut (&mut _t9.tp_reqs).full_sized;
                    *_t64 = _t61;
                    break
                };
                if (!option::is_none<PendingTpSlKey>(&(&_t9.sl_reqs).full_sized)) {
                    let _t95 = error::invalid_argument(19);
                    abort _t95
                };
                let _t89 = option::some<PendingTpSlKey>(_t13);
                let _t92 = &mut (&mut _t9.sl_reqs).full_sized;
                *_t92 = _t89;
                break
            };
            let _t98 = *&_t9.size;
            let _t100 = option::destroy_some<u64>(p5);
            if (!(_t98 >= _t100)) {
                let _t131 = error::invalid_argument(20);
                abort _t131
            };
            if (p6) {
                if (!(vector::length<PendingTpSlKey>(&(&_t9.tp_reqs).fixed_sized) < 10)) {
                    let _t115 = error::invalid_argument(18);
                    abort _t115
                };
                vector::push_back<PendingTpSlKey>(&mut (&mut _t9.tp_reqs).fixed_sized, _t13);
                break
            };
            if (!(vector::length<PendingTpSlKey>(&(&_t9.sl_reqs).fixed_sized) < 10)) {
                let _t128 = error::invalid_argument(18);
                abort _t128
            };
            vector::push_back<PendingTpSlKey>(&mut (&mut _t9.sl_reqs).fixed_sized, _t13);
            break
        };
        let _t67 = *&_t9.market;
        let _t76 = *&_t9.is_long;
        position_tp_sl_tracker::add_new_tp_sl(_t67, p0, p2, _t12, p4, p5, p6, _t76);
        emit_position_update_event(freeze(_t9), p0, _t10);
    }
    friend fun add_tp(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: order_book_types::OrderIdType, p3: u64, p4: option::Option<u64>, p5: option::Option<u64>)
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        add_tp_sl(p0, p1, p2, p3, p4, p5, true);
    }
    public fun isolated_position_address(p0: address, p1: object::Object<perp_market::PerpMarket>): address {
        let _t2 = &p0;
        let _t4 = bcs::to_bytes<object::Object<perp_market::PerpMarket>>(&p1);
        object::create_object_address(_t2, _t4)
    }
    fun validate_tp_sl_internal(p0: &PerpPosition, p1: u64, p2: bool): bool {
        let _t5;
        let _t4;
        let _t3 = price_management::get_mark_price(*&p0.market);
        if (*&p0.is_long) _t4 = p2 else _t4 = false;
        if (_t4) _t5 = true else if (*&p0.is_long) _t5 = false else _t5 = !p2;
        'l0: loop {
            loop {
                if (_t5) if (!(p1 > _t3)) break else if (p1 < _t3) break 'l0 else break;
                return true
            };
            return false
        };
        true
    }
    public fun is_position_isolated(p0: address, p1: object::Object<perp_market::PerpMarket>): bool {
        let _t4 = isolated_position_address(p0, p1);
        exists<IsolatedPosition>(_t4)
    }
    fun emit_position_update_event(p0: &PerpPosition, p1: address, p2: bool) {
        let (_t16,_t17) = i64::into_inner(*&p0.unrealized_funding_amount_before_last_update);
        let _t20 = *&p0.market;
        let _t5 = *&p0.is_long;
        let _t6 = *&p0.size;
        let _t7 = *&p0.entry_px_times_size_sum;
        let _t8 = *&p0.user_leverage;
        let _t9 = *&p0.max_allowed_leverage;
        let _t10 = price_management::accumulative_index(&p0.funding_index_at_last_update);
        let _t11 = get_full_sized_tp_sl_for_event(p0, true);
        let _t12 = get_full_sized_tp_sl_for_event(p0, false);
        let _t58 = get_fixed_sized_tp_sl_for_event(p0, true);
        let _t62 = get_fixed_sized_tp_sl_for_event(p0, false);
        event::emit<PositionUpdateEvent>(PositionUpdateEvent{market: _t20, user: p1, is_long: _t5, size: _t6, user_leverage: _t8, max_allowed_leverage: _t9, entry_price_times_size_sum: _t7, is_isolated: p2, funding_index_at_last_update: _t10, unrealized_funding_amount_before_last_update: _t17, is_unrealized_funding_amount_before_last_update_positive: _t16, full_sized_tp: _t11, fixed_sized_tps: _t58, full_sized_sl: _t12, fixed_sized_sls: _t62});
    }
    fun calculate_cross_margin_required(p0: address, p1: option::Option<object::Object<perp_market::PerpMarket>>): u64
        acquires CrossedPosition
    {
        let _t10 = borrow_global<CrossedPosition>(p0);
        let _t2 = 0;
        let _t3 = &_t10.positions;
        let _t4 = 0;
        let _t5 = vector::length<PerpPosition>(_t3);
        loop {
            let _t7;
            if (!(_t4 < _t5)) break;
            let _t6 = vector::borrow<PerpPosition>(_t3, _t4);
            if (option::is_none<object::Object<perp_market::PerpMarket>>(&p1)) _t7 = true else {
                let _t37 = *&_t6.market;
                let _t39 = option::destroy_some<object::Object<perp_market::PerpMarket>>(p1);
                _t7 = _t37 != _t39
            };
            if (_t7) {
                let _t8 = margin_required(_t6);
                _t2 = _t2 + _t8
            };
            _t4 = _t4 + 1;
            continue
        };
        _t2
    }
    fun margin_required(p0: &PerpPosition): u64 {
        let _t1 = perp_market_config::get_size_multiplier(*&p0.market);
        let _t2 = price_management::get_mark_price(*&p0.market);
        let _t13 = *&p0.size;
        let _t18 = *&p0.user_leverage;
        margin_required_formula(_t13, _t2, _t1, _t18)
    }
    fun cancel_all_tp_sl_for_position(p0: &mut PerpPosition, p1: object::Object<perp_market::PerpMarket>) {
        cancel_full_sized_tp_sl(p0, true, p1);
        cancel_full_sized_tp_sl(p0, false, p1);
        let _t2 = *&(&p0.tp_reqs).fixed_sized;
        vector::reverse<PendingTpSlKey>(&mut _t2);
        let _t3 = _t2;
        let _t4 = vector::length<PendingTpSlKey>(&_t3);
        while (_t4 > 0) {
            let _t5 = vector::pop_back<PendingTpSlKey>(&mut _t3);
            let _t31 = *&(&_t5).price_index;
            let _t35 = *&p0.is_long;
            position_tp_sl_tracker::cancel_pending_tp_sl(p1, _t31, true, _t35);
            _t4 = _t4 - 1;
            continue
        };
        vector::destroy_empty<PendingTpSlKey>(_t3);
        let _t6 = *&(&p0.sl_reqs).fixed_sized;
        vector::reverse<PendingTpSlKey>(&mut _t6);
        let _t7 = _t6;
        _t4 = vector::length<PendingTpSlKey>(&_t7);
        while (_t4 > 0) {
            let _t8 = vector::pop_back<PendingTpSlKey>(&mut _t7);
            let _t56 = *&(&_t8).price_index;
            let _t60 = *&p0.is_long;
            position_tp_sl_tracker::cancel_pending_tp_sl(p1, _t56, false, _t60);
            _t4 = _t4 - 1;
            continue
        };
        vector::destroy_empty<PendingTpSlKey>(_t7);
        let _t65 = vector::empty<PendingTpSlKey>();
        let _t68 = &mut (&mut p0.tp_reqs).fixed_sized;
        *_t68 = _t65;
        let _t69 = vector::empty<PendingTpSlKey>();
        let _t72 = &mut (&mut p0.sl_reqs).fixed_sized;
        *_t72 = _t69;
    }
    fun cancel_full_sized_tp_sl(p0: &mut PerpPosition, p1: bool, p2: object::Object<perp_market::PerpMarket>) {
        let _t3 = clear_full_sized_tp_sl(p0, p1);
        if (option::is_some<PendingTpSlKey>(&_t3)) {
            let _t4 = option::destroy_some<PendingTpSlKey>(_t3);
            let _t15 = *&(&_t4).price_index;
            let _t19 = *&p0.is_long;
            position_tp_sl_tracker::cancel_pending_tp_sl(p2, _t15, p1, _t19)
        };
    }
    fun clear_full_sized_tp_sl(p0: &mut PerpPosition, p1: bool): option::Option<PendingTpSlKey> {
        let _t2;
        if (p1) {
            _t2 = *&(&p0.tp_reqs).full_sized;
            let _t8 = option::none<PendingTpSlKey>();
            let _t11 = &mut (&mut p0.tp_reqs).full_sized;
            *_t11 = _t8
        } else {
            let _t16 = *&(&p0.sl_reqs).full_sized;
            let _t17 = option::none<PendingTpSlKey>();
            let _t20 = &mut (&mut p0.sl_reqs).full_sized;
            *_t20 = _t17;
            _t2 = _t16
        };
        _t2
    }
    friend fun cancel_tp_sl(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: order_book_types::OrderIdType)
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t12;
        let _t5;
        let _t3 = p0;
        let _t4 = p1;
        let _t25 = isolated_position_address(_t3, _t4);
        if (exists<IsolatedPosition>(_t25)) {
            let _t29 = isolated_position_address(_t3, _t4);
            _t5 = &mut borrow_global_mut<IsolatedPosition>(_t29).position
        } else {
            let _t14 = &mut borrow_global_mut<CrossedPosition>(_t3).positions;
            let _t15 = freeze(_t14);
            let _t16 = false;
            let _t17 = 0;
            let _t18 = 0;
            let _t19 = vector::length<PerpPosition>(_t15);
            'l0: loop {
                loop {
                    if (!(_t18 < _t19)) break 'l0;
                    let _t146 = &vector::borrow<PerpPosition>(_t15, _t18).market;
                    let _t147 = &_t4;
                    if (_t146 == _t147) break;
                    _t18 = _t18 + 1;
                    continue
                };
                _t16 = true;
                _t17 = _t18;
                break
            };
            if (_t16) _t5 = vector::borrow_mut<PerpPosition>(_t14, _t17) else {
                let _t159 = error::invalid_argument(7);
                abort _t159
            }
        };
        let _t6 = clear_full_sized_tp_sl_for_order(_t5, true, p2);
        let _t37 = option::is_some<PendingTpSlKey>(&_t6);
        'l2: loop {
            let _t10;
            'l1: loop {
                let _t8;
                loop {
                    if (!_t37) {
                        _t8 = clear_full_sized_tp_sl_for_order(_t5, false, p2);
                        if (option::is_some<PendingTpSlKey>(&_t8)) break;
                        _t10 = clear_fixed_sized_tp_sl_for_order(_t5, true, p2);
                        if (option::is_some<PendingTpSlKey>(&_t10)) break 'l1;
                        _t12 = clear_fixed_sized_tp_sl_for_order(_t5, false, p2);
                        if (option::is_some<PendingTpSlKey>(&_t12)) break 'l2;
                        abort 16
                    };
                    let _t40 = *&_t5.market;
                    let _t7 = option::destroy_some<PendingTpSlKey>(_t6);
                    let _t45 = *&(&_t7).price_index;
                    let _t49 = *&_t5.is_long;
                    position_tp_sl_tracker::cancel_pending_tp_sl(_t40, _t45, true, _t49);
                    let _t51 = freeze(_t5);
                    let _t55 = is_position_isolated(p0, p1);
                    emit_position_update_event(_t51, p0, _t55);
                    return ()
                };
                let _t64 = *&_t5.market;
                let _t9 = option::destroy_some<PendingTpSlKey>(_t8);
                let _t69 = *&(&_t9).price_index;
                let _t73 = *&_t5.is_long;
                position_tp_sl_tracker::cancel_pending_tp_sl(_t64, _t69, false, _t73);
                let _t75 = freeze(_t5);
                let _t79 = is_position_isolated(p0, p1);
                emit_position_update_event(_t75, p0, _t79);
                return ()
            };
            let _t88 = *&_t5.market;
            let _t11 = option::destroy_some<PendingTpSlKey>(_t10);
            let _t93 = *&(&_t11).price_index;
            let _t97 = *&_t5.is_long;
            position_tp_sl_tracker::cancel_pending_tp_sl(_t88, _t93, true, _t97);
            let _t99 = freeze(_t5);
            let _t103 = is_position_isolated(p0, p1);
            emit_position_update_event(_t99, p0, _t103);
            return ()
        };
        let _t112 = *&_t5.market;
        let _t13 = option::destroy_some<PendingTpSlKey>(_t12);
        let _t117 = *&(&_t13).price_index;
        let _t121 = *&_t5.is_long;
        position_tp_sl_tracker::cancel_pending_tp_sl(_t112, _t117, false, _t121);
        let _t123 = freeze(_t5);
        let _t127 = is_position_isolated(p0, p1);
        emit_position_update_event(_t123, p0, _t127);
    }
    fun clear_full_sized_tp_sl_for_order(p0: &mut PerpPosition, p1: bool, p2: order_book_types::OrderIdType): option::Option<PendingTpSlKey> {
        let _t5 = p1;
        'l1: loop {
            'l0: loop {
                loop {
                    if (_t5) {
                        if (option::is_some<PendingTpSlKey>(&(&p0.tp_reqs).full_sized)) {
                            let _t3 = option::destroy_some<PendingTpSlKey>(*&(&p0.tp_reqs).full_sized);
                            p1 = *&(&_t3).order_id == p2
                        } else p1 = false;
                        if (p1) break;
                        break 'l0
                    };
                    if (option::is_some<PendingTpSlKey>(&(&p0.sl_reqs).full_sized)) {
                        let _t4 = option::destroy_some<PendingTpSlKey>(*&(&p0.sl_reqs).full_sized);
                        p1 = *&(&_t4).order_id == p2
                    } else p1 = false;
                    if (p1) break 'l1;
                    break 'l0
                };
                return clear_full_sized_tp_sl(p0, true)
            };
            return option::none<PendingTpSlKey>()
        };
        clear_full_sized_tp_sl(p0, false)
    }
    fun clear_fixed_sized_tp_sl_for_order(p0: &mut PerpPosition, p1: bool, p2: order_book_types::OrderIdType): option::Option<PendingTpSlKey> {
        let _t3;
        if (p1) _t3 = &mut p0.tp_reqs else _t3 = &mut p0.sl_reqs;
        let _t4 = &_t3.fixed_sized;
        let _t5 = false;
        let _t6 = 0;
        let _t7 = 0;
        let _t8 = vector::length<PendingTpSlKey>(_t4);
        'l0: loop {
            loop {
                if (!(_t7 < _t8)) break 'l0;
                let _t26 = &vector::borrow<PendingTpSlKey>(_t4, _t7).order_id;
                let _t27 = &p2;
                if (_t26 == _t27) break;
                _t7 = _t7 + 1;
                continue
            };
            _t5 = true;
            _t6 = _t7;
            break
        };
        if (_t5) return option::some<PendingTpSlKey>(vector::swap_remove<PendingTpSlKey>(&mut _t3.fixed_sized, _t6));
        option::none<PendingTpSlKey>()
    }
    friend fun commit_update(p0: &mut collateral_balance_sheet::CollateralBalanceSheet, p1: u64, p2: bool, p3: u64, p4: UpdatePositionResult, p5: address)
        acquires AccountInfo
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t18;
        let _t17;
        let _t16;
        let _t13;
        let _t12;
        let _t11;
        let _t10;
        let _t9;
        let _t6 = &p4;
        loop {
            if (_t6 is Success) {
                let _t19;
                let UpdatePositionResult::Success{account: _t27, market: _t28, is_isolated: _t29, position_address: _t30, margin_delta: _t31, backstop_liquidator_covered_loss: _t32, fee_distribution: _t33, realized_pnl: _t34, realized_funding_cost: _t35, unrealized_funding_cost: _t36, updated_funding_index: _t37, volume_delta: _t38, is_taker: _t39} = p4;
                let _t8 = _t38;
                _t9 = _t37;
                _t10 = _t36;
                _t11 = _t35;
                _t12 = _t34;
                _t13 = _t33;
                let _t14 = _t32;
                let _t15 = _t31;
                _t16 = _t30;
                _t17 = _t28;
                _t18 = _t27;
                if (!(_t14 == 0)) {
                    let _t135 = error::invalid_argument(6);
                    abort _t135
                };
                if (_t16 == _t18) _t19 = collateral_balance_sheet::balance_type_cross(_t18) else _t19 = collateral_balance_sheet::balance_type_isolated(_t18, _t17);
                if (option::is_some<i64::I64>(&_t12)) {
                    let (_t52,_t53) = i64::into_inner(option::destroy_some<i64::I64>(_t12));
                    _t14 = _t53;
                    if (_t52) {
                        let _t58 = collateral_balance_sheet::change_type_pnl();
                        collateral_balance_sheet::deposit_to_user(p0, _t16, _t14, _t19, _t58)
                    } else if (collateral_balance_sheet::balance_at_least(freeze(p0), _t16, _t14)) {
                        let _t127 = collateral_balance_sheet::change_type_pnl();
                        collateral_balance_sheet::decrease_balance(p0, _t16, _t14, _t19, _t127)
                    } else abort 13
                };
                if (option::is_some<i64::I64>(&_t15)) {
                    let _t20 = collateral_balance_sheet::change_type_margin();
                    let (_t64,_t65) = i64::into_inner(option::destroy_some<i64::I64>(_t15));
                    let _t21 = _t65;
                    if (_t64) {
                        if (collateral_balance_sheet::balance_of(freeze(p0), _t18) < _t21) update_crossed_position_pnl(p0, _t18);
                        let _t79 = collateral_balance_sheet::balance_type_cross(_t18);
                        collateral_balance_sheet::transfer_position(p0, _t18, _t16, _t21, _t79, _t20, _t19, _t20)
                    } else {
                        let _t116 = collateral_balance_sheet::balance_type_cross(_t18);
                        collateral_balance_sheet::transfer_position(p0, _t16, _t18, _t21, _t19, _t20, _t116, _t20)
                    }
                };
                fee_distribution::distribute_fees(&_t13, p0, _t19, p5);
                if (!(_t8 != 0u128)) break;
                track_volume(_t18, _t39, _t8);
                break
            };
            if (_t6 is Liquidatable) {
                let UpdatePositionResult::Liquidatable{} = p4;
                let _t142 = error::invalid_argument(1);
                abort _t142
            };
            if (_t6 is InsufficientMargin) {
                let UpdatePositionResult::InsufficientMargin{} = p4;
                let _t148 = error::invalid_argument(6);
                abort _t148
            };
            if (_t6 is InvalidLeverage) {
                let UpdatePositionResult::InvalidLeverage{} = p4;
                let _t153 = error::invalid_argument(2);
                abort _t153
            };
            abort 14566554180833181697
        };
        let _t101 = &_t11;
        let _t102 = i64::zero();
        let _t103 = option::get_with_default<i64::I64>(_t101, _t102);
        let _t104 = &_t12;
        let _t105 = i64::zero();
        let _t106 = option::get_with_default<i64::I64>(_t104, _t105);
        let _t108 = fee_distribution::get_position_fee_delta(&_t13);
        update_position(_t18, _t16, _t17, p1, p2, p3, _t10, _t9, _t103, _t106, _t108);
    }
    friend fun update_crossed_position_pnl(p0: &mut collateral_balance_sheet::CollateralBalanceSheet, p1: address)
        acquires CrossedPosition
    {
        let _t2 = &mut borrow_global_mut<CrossedPosition>(p1).positions;
        let _t3 = i64::zero();
        let _t4 = 0;
        let _t5 = vector::length<PerpPosition>(freeze(_t2));
        while (_t4 < _t5) {
            let _t6 = vector::borrow_mut<PerpPosition>(_t2, _t4);
            let _t7 = price_management::get_mark_price(*&_t6.market);
            let _t35 = freeze(_t6);
            let _t39 = *&_t6.size;
            let (_t40,_t41,_t42,_t43) = get_pnl_and_funding_for_decrease(_t35, _t7, _t39);
            let _t10 = _t40;
            let (_t45,_t46) = i64::into_inner(_t10);
            let (_t48,_t49) = i64::into_inner(_t41);
            let _t53 = *&_t6.market;
            let _t54 = Action::Net{};
            let _t57 = *&_t6.size;
            event::emit<TradeEvent>(TradeEvent{account: p1, market: _t53, action: _t54, size: _t57, price: _t7, is_profit: _t45, realized_pnl_amount: _t46, is_funding_positive: _t48, realized_funding_amount: _t49, is_rebate: true, fee_amount: 0});
            i64::add_inplace(&mut _t3, _t10);
            let _t15 = &mut _t6.funding_index_at_last_update;
            *_t15 = _t43;
            let _t72 = i64::zero();
            let _t74 = &mut _t6.unrealized_funding_amount_before_last_update;
            *_t74 = _t72;
            let _t76 = _t7 as u128;
            let _t80 = (*&_t6.size) as u128;
            let _t81 = _t76 * _t80;
            let _t83 = &mut _t6.entry_px_times_size_sum;
            *_t83 = _t81;
            _t4 = _t4 + 1;
            continue
        };
        let (_t89,_t90) = i64::into_inner(_t3);
        _t4 = _t90;
        if (_t89) {
            let _t95 = collateral_balance_sheet::balance_type_cross(p1);
            let _t96 = collateral_balance_sheet::change_type_pnl();
            collateral_balance_sheet::deposit_to_user(p0, p1, _t4, _t95, _t96)
        } else if (collateral_balance_sheet::balance_at_least(freeze(p0), p1, _t4)) {
            let _t106 = collateral_balance_sheet::balance_type_cross(p1);
            let _t107 = collateral_balance_sheet::change_type_pnl();
            collateral_balance_sheet::decrease_balance(p0, p1, _t4, _t106, _t107)
        } else abort 13;
    }
    fun update_position(p0: address, p1: address, p2: object::Object<perp_market::PerpMarket>, p3: u64, p4: bool, p5: u64, p6: i64::I64, p7: price_management::AccumulativeIndex, p8: i64::I64, p9: i64::I64, p10: i64::I64)
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t11;
        if (exists<IsolatedPosition>(p1)) {
            _t11 = &mut borrow_global_mut<IsolatedPosition>(p1).position;
            let _t27 = freeze(_t11);
            emit_trade_event(p0, _t27, p4, p5, p3, p9, p8, p10);
            update_single_position(p2, p0, _t11, p3, p4, p5, p6, p7);
            emit_position_update_event(freeze(_t11), p0, true)
        } else {
            let _t12 = &mut borrow_global_mut<CrossedPosition>(p1).positions;
            let _t13 = freeze(_t12);
            let _t14 = false;
            let _t15 = 0;
            let _t16 = 0;
            let _t17 = vector::length<PerpPosition>(_t13);
            'l0: loop {
                loop {
                    if (!(_t16 < _t17)) break 'l0;
                    let _t62 = &vector::borrow<PerpPosition>(_t13, _t16).market;
                    let _t63 = &p2;
                    if (_t62 == _t63) break;
                    _t16 = _t16 + 1;
                    continue
                };
                _t14 = true;
                _t15 = _t16;
                break
            };
            if (_t14) {
                _t11 = vector::borrow_mut<PerpPosition>(_t12, _t15);
                let _t75 = freeze(_t11);
                emit_trade_event(p0, _t75, p4, p5, p3, p9, p8, p10);
                update_single_position(p2, p0, _t11, p3, p4, p5, p6, p7);
                emit_position_update_event(freeze(_t11), p0, false)
            } else {
                let _t97 = p3 as u128;
                let _t99 = p5 as u128;
                let _t100 = _t97 * _t99;
                let _t102 = perp_market_config::get_max_leverage(p2);
                let _t19 = new_perp_position(p5, p2, _t100, _t102, p4);
                let _t106 = &_t19;
                emit_trade_event(p0, _t106, p4, p5, p3, p9, p8, p10);
                adl_tracker::add_position(p2, p0, p4, p3);
                vector::push_back<PerpPosition>(_t12, _t19);
                emit_position_update_event(&_t19, p0, false)
            }
        };
    }
    friend fun configure_user_settings_for_market(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: bool, p3: u8)
        acquires CrossedPosition
        acquires IsolatedPosition
        acquires IsolatedPositionRefs
    {
        let _t6;
        let _t4 = signer::address_of(p0);
        let _t5 = perp_market_config::get_max_leverage(p1);
        if (p3 > 0u8) _t6 = p3 <= _t5 else _t6 = false;
        if (!_t6) abort 2;
        loop {
            let _t20;
            let _t23;
            let _t22;
            let _t21;
            let _t18;
            let _t16;
            let _t12;
            let _t9;
            let _t7;
            if (p2) {
                _t7 = isolated_position_address(_t4, p1);
                if (exists<IsolatedPosition>(_t7)) {
                    let IsolatedPosition{position: _t49} = move_from<IsolatedPosition>(_t7);
                    let _t8 = _t49;
                    if (!(*&(&_t8).size == 0)) abort 17
                };
                _t9 = &mut borrow_global_mut<CrossedPosition>(_t4).positions;
                let _t10 = freeze(_t9);
                let _t11 = false;
                _t12 = 0;
                let _t13 = 0;
                let _t14 = vector::length<PerpPosition>(_t10);
                'l0: loop {
                    loop {
                        if (!(_t13 < _t14)) break 'l0;
                        let _t71 = &vector::borrow<PerpPosition>(_t10, _t13).market;
                        let _t72 = &p1;
                        if (_t71 == _t72) break;
                        _t13 = _t13 + 1;
                        continue
                    };
                    _t11 = true;
                    _t12 = _t13;
                    break
                };
                if (_t11) {
                    _t16 = vector::borrow_mut<PerpPosition>(_t9, _t12);
                    if (*&_t16.user_leverage != p3) {
                        let _t17;
                        if (*&_t16.size == 0) _t17 = true else _t17 = *&_t16.user_leverage > p3;
                        if (_t17) {
                            _t18 = &mut _t16.user_leverage;
                            *_t18 = p3;
                            emit_position_update_event(freeze(_t16), _t4, false);
                            break
                        } else if (*&_t16.user_leverage == p3) break else abort 17
                    } else break
                } else {
                    let _t19 = new_empty_perp_position(p1, p3);
                    emit_position_update_event(&_t19, _t4, false);
                    vector::push_back<PerpPosition>(_t9, _t19);
                    break
                }
            } else {
                _t9 = &mut borrow_global_mut<CrossedPosition>(_t4).positions;
                _t20 = freeze(_t9);
                _t21 = false;
                _t12 = 0;
                _t22 = 0;
                _t23 = vector::length<PerpPosition>(_t20)
            };
            'l1: loop {
                loop {
                    if (!(_t22 < _t23)) break 'l1;
                    let _t142 = &vector::borrow<PerpPosition>(_t20, _t22).market;
                    let _t143 = &p1;
                    if (_t142 == _t143) break;
                    _t22 = _t22 + 1;
                    continue
                };
                _t21 = true;
                _t12 = _t22;
                break
            };
            if (_t21) {
                let _t24 = vector::swap_remove<PerpPosition>(_t9, _t12);
                if (!(*&(&_t24).size == 0)) abort 17
            };
            _t7 = isolated_position_address(_t4, p1);
            if (exists<IsolatedPosition>(_t7)) {
                _t16 = &mut borrow_global_mut<IsolatedPosition>(_t7).position;
                if (!(*&_t16.user_leverage != p3)) break;
                if (*&_t16.size == 0) {
                    _t18 = &mut _t16.user_leverage;
                    *_t18 = p3;
                    emit_position_update_event(freeze(_t16), _t4, true);
                    break
                };
                if (*&_t16.user_leverage == p3) break;
                abort 17
            };
            let _t25 = &mut borrow_global_mut<IsolatedPositionRefs>(_t4).extend_refs;
            let _t196 = freeze(_t25);
            let _t197 = &p1;
            if (!ordered_map::contains<object::Object<perp_market::PerpMarket>,object::ExtendRef>(_t196, _t197)) {
                let _t201 = bcs::to_bytes<object::Object<perp_market::PerpMarket>>(&p1);
                let _t26 = object::create_named_object(p0, _t201);
                object::set_untransferable(&_t26);
                let _t207 = object::generate_extend_ref(&_t26);
                ordered_map::add<object::Object<perp_market::PerpMarket>,object::ExtendRef>(_t25, p1, _t207)
            };
            let _t209 = freeze(_t25);
            let _t210 = &p1;
            let _t27 = object::generate_signer_for_extending(ordered_map::borrow<object::Object<perp_market::PerpMarket>,object::ExtendRef>(_t209, _t210));
            let _t28 = new_empty_perp_position(p1, p3);
            emit_position_update_event(&_t28, _t4, true);
            let _t219 = &_t27;
            let _t221 = IsolatedPosition{position: _t28};
            move_to<IsolatedPosition>(_t219, _t221);
            break
        };
    }
    friend fun new_empty_perp_position(p0: object::Object<perp_market::PerpMarket>, p1: u8): PerpPosition {
        new_perp_position(0, p0, 0u128, p1, true)
    }
    fun cross_position_status(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: address): AccountStatus
        acquires CrossedPosition
    {
        let _t2 = i64::zero();
        let _t3 = &borrow_global<CrossedPosition>(p1).positions;
        let _t4 = 0;
        let _t5 = 0;
        let _t6 = 0;
        let _t7 = vector::length<PerpPosition>(_t3);
        'l0: loop {
            loop {
                if (!(_t6 < _t7)) break 'l0;
                let _t8 = vector::borrow<PerpPosition>(_t3, _t6);
                let (_t33,_t34,_t35) = price_management::get_market_info_for_pnl_calculation(*&_t8.market);
                let _t9 = _t35;
                let _t11 = _t33;
                let _t36 = &mut _t2;
                let _t41 = pnl_with_funding_impl(_t8, _t9, _t34, _t11);
                i64::add_inplace(_t36, _t41);
                let _t44 = *&_t8.size;
                let _t49 = *&_t8.max_allowed_leverage;
                let _t12 = margin_required_formula(_t44, _t11, _t9, _t49);
                _t4 = _t4 + _t12;
                _t12 = *&_t8.size;
                if (!(_t9 != 0)) break;
                let _t61 = _t12 as u128;
                let _t63 = _t11 as u128;
                let _t64 = _t61 * _t63;
                let _t66 = _t9 as u128;
                let _t13 = (_t64 / _t66) as u64;
                _t5 = _t5 + _t13;
                _t6 = _t6 + 1;
                continue
            };
            let _t78 = error::invalid_argument(4);
            abort _t78
        };
        let _t14 = i64::new_positive(collateral_balance_sheet::balance_of(p0, p1));
        i64::add_inplace(&mut _t14, _t2);
        AccountStatus{account_balance: _t14, initial_margin: _t4, total_notional_value: _t5}
    }
    fun pnl_with_funding_impl(p0: &PerpPosition, p1: u64, p2: price_management::AccumulativeIndex, p3: u64): i64::I64 {
        let _t12;
        let _t6;
        let _t5;
        let _t16 = p3 as u128;
        let _t20 = (*&p0.size) as u128;
        let _t4 = _t16 * _t20;
        let _t25 = *&p0.entry_px_times_size_sum;
        if (_t4 >= _t25) {
            _t5 = *&p0.is_long;
            let _t33 = *&p0.entry_px_times_size_sum;
            _t6 = _t4 - _t33
        } else {
            _t5 = !*&p0.is_long;
            _t6 = *&p0.entry_px_times_size_sum - _t4
        };
        let _t8 = _t6;
        let _t9 = p1 as u128;
        if (_t5) _t12 = _t8 / _t9 else {
            let _t10 = _t8;
            let _t11 = _t9;
            if (_t10 == 0u128) if (_t11 != 0u128) _t12 = 0u128 else {
                let _t64 = error::invalid_argument(4);
                abort _t64
            } else _t12 = (_t10 - 1u128) / _t11 + 1u128
        };
        p3 = _t12 as u64;
        let _t13 = i64::new(_t5, p3);
        let (_t57,_t58) = get_position_funding_cost_and_index_impl(p0, p1, p2);
        i64::sub_inplace(&mut _t13, _t57);
        _t13
    }
    fun margin_required_formula(p0: u64, p1: u64, p2: u64, p3: u8): u64 {
        let _t6;
        let _t9 = p3 as u64;
        p2 = p2 * _t9;
        if (!(p2 != 0)) {
            let _t40 = error::invalid_argument(4);
            abort _t40
        };
        let _t15 = p0 as u128;
        let _t17 = p1 as u128;
        let _t4 = _t15 * _t17;
        let _t5 = p2 as u128;
        if (_t4 == 0u128) if (_t5 != 0u128) _t6 = 0u128 else {
            let _t31 = error::invalid_argument(4);
            abort _t31
        } else _t6 = (_t4 - 1u128) / _t5 + 1u128;
        _t6 as u64
    }
    fun cross_positions_pnl(p0: address, p1: option::Option<object::Object<perp_market::PerpMarket>>): i64::I64
        acquires CrossedPosition
    {
        let _t10 = borrow_global<CrossedPosition>(p0);
        let _t2 = i64::zero();
        let _t3 = &_t10.positions;
        let _t4 = 0;
        let _t5 = vector::length<PerpPosition>(_t3);
        loop {
            let _t7;
            if (!(_t4 < _t5)) break;
            let _t6 = vector::borrow<PerpPosition>(_t3, _t4);
            if (option::is_none<object::Object<perp_market::PerpMarket>>(&p1)) _t7 = true else {
                let _t36 = *&_t6.market;
                let _t38 = option::destroy_some<object::Object<perp_market::PerpMarket>>(p1);
                _t7 = _t36 != _t38
            };
            if (_t7) {
                let _t8 = pnl_with_funding(_t6);
                i64::add_inplace(&mut _t2, _t8)
            };
            _t4 = _t4 + 1;
            continue
        };
        _t2
    }
    fun pnl_with_funding(p0: &PerpPosition): i64::I64 {
        let (_t7,_t8,_t9) = price_management::get_market_info_for_pnl_calculation(*&p0.market);
        pnl_with_funding_impl(p0, _t9, _t8, _t7)
    }
    public fun destroy_fixed_sized_tp_sl_for_event(p0: FixedSizedTpSlForEvent): (u64, option::Option<u64>, u64) {
        let _t3 = *&(&p0).trigger_price;
        let _t6 = *&(&p0).limit_price;
        let _t9 = *&(&p0).size;
        (_t3, _t6, _t9)
    }
    public fun destroy_full_sized_tp_sl_for_event(p0: FullSizedTpSlForEvent): (u64, option::Option<u64>) {
        let _t3 = *&(&p0).trigger_price;
        let _t6 = *&(&p0).limit_price;
        (_t3, _t6)
    }
    friend fun destroy_position_pending_request(p0: PositionPendingTpSL): (address, order_book_types::OrderIdType, u64, option::Option<u64>, option::Option<u64>) {
        let PositionPendingTpSL{order_id: _t7, trigger_price: _t8, account: _t9, limit_price: _t10, size: _t11} = p0;
        (_t9, _t7, _t8, _t10, _t11)
    }
    fun get_full_sized_tp_sl_for_event(p0: &PerpPosition, p1: bool): option::Option<FullSizedTpSlForEvent> {
        let _t7;
        let _t2;
        if (p1) _t2 = *&(&p0.tp_reqs).full_sized else _t2 = *&(&p0.sl_reqs).full_sized;
        if (option::is_some<PendingTpSlKey>(&_t2)) {
            let _t3 = option::destroy_some<PendingTpSlKey>(_t2);
            let _t19 = *&p0.market;
            let _t22 = *&(&_t3).price_index;
            let _t26 = *&p0.is_long;
            let (_t27,_t28,_t29,_t30) = position_tp_sl_tracker::get_pending_tp_sl(_t19, _t22, p1, _t26);
            let _t4 = _t30;
            let _t6 = _t28;
            if (option::is_none<u64>(&_t4)) {
                let _t34 = order_book_types::get_order_id_value(&_t6);
                let _t37 = position_tp_sl_tracker::get_trigger_price(&(&_t3).price_index);
                _t7 = option::some<FullSizedTpSlForEvent>(FullSizedTpSlForEvent{order_id: _t34, trigger_price: _t37, limit_price: _t29})
            } else abort 20
        } else _t7 = option::none<FullSizedTpSlForEvent>();
        _t7
    }
    fun get_fixed_sized_tp_sl_for_event(p0: &PerpPosition, p1: bool): vector<FixedSizedTpSlForEvent> {
        let _t3;
        let _t2 = vector::empty<FixedSizedTpSlForEvent>();
        if (p1) _t3 = &p0.tp_reqs else _t3 = &p0.sl_reqs;
        let _t4 = *&_t3.fixed_sized;
        vector::reverse<PendingTpSlKey>(&mut _t4);
        let _t5 = _t4;
        let _t6 = vector::length<PendingTpSlKey>(&_t5);
        'l0: loop {
            loop {
                if (!(_t6 > 0)) break 'l0;
                let _t7 = vector::pop_back<PendingTpSlKey>(&mut _t5);
                let _t29 = *&p0.market;
                let _t32 = *&(&_t7).price_index;
                let _t36 = *&p0.is_long;
                let (_t37,_t38,_t39,_t40) = position_tp_sl_tracker::get_pending_tp_sl(_t29, _t32, p1, _t36);
                let _t8 = _t40;
                let _t10 = _t38;
                if (!option::is_some<u64>(&_t8)) break;
                let _t43 = &mut _t2;
                let _t45 = order_book_types::get_order_id_value(&_t10);
                let _t48 = position_tp_sl_tracker::get_trigger_price(&(&_t7).price_index);
                let _t51 = option::destroy_some<u64>(_t8);
                let _t52 = FixedSizedTpSlForEvent{order_id: _t45, trigger_price: _t48, limit_price: _t39, size: _t51};
                vector::push_back<FixedSizedTpSlForEvent>(_t43, _t52);
                _t6 = _t6 - 1;
                continue
            };
            abort 20
        };
        vector::destroy_empty<PendingTpSlKey>(_t5);
        _t2
    }
    fun emit_trade_event(p0: address, p1: &PerpPosition, p2: bool, p3: u64, p4: u64, p5: i64::I64, p6: i64::I64, p7: i64::I64) {
        let _t14;
        let (_t30,_t31) = i64::into_inner(p5);
        let _t8 = _t31;
        let _t9 = _t30;
        let (_t33,_t34) = i64::into_inner(p6);
        let _t10 = _t34;
        let _t11 = _t33;
        let (_t36,_t37) = i64::into_inner(p7);
        let _t12 = _t37;
        let _t13 = _t36;
        if (*&p1.is_long != p2) _t14 = *&p1.size != 0 else _t14 = false;
        loop {
            let _t17;
            let _t16;
            if (_t14) {
                let _t27;
                if (*&p1.size >= p3) {
                    _t16 = *&p1.market;
                    if (*&p1.is_long) _t17 = Action::CloseLong{} else _t17 = Action::CloseShort{};
                    event::emit<TradeEvent>(TradeEvent{account: p0, market: _t16, action: _t17, size: p3, price: p4, is_profit: _t9, realized_pnl_amount: _t8, is_funding_positive: _t11, realized_funding_amount: _t10, is_rebate: _t13, fee_amount: _t12});
                    break
                };
                _t16 = *&p1.market;
                if (*&p1.is_long) _t17 = Action::CloseLong{} else _t17 = Action::CloseShort{};
                let _t92 = *&p1.size;
                event::emit<TradeEvent>(TradeEvent{account: p0, market: _t16, action: _t17, size: _t92, price: p4, is_profit: _t9, realized_pnl_amount: _t8, is_funding_positive: _t11, realized_funding_amount: _t10, is_rebate: _t13, fee_amount: _t12});
                let _t26 = *&p1.market;
                if (p2) _t27 = Action::OpenLong{} else _t27 = Action::OpenShort{};
                let _t120 = *&p1.size;
                let _t121 = p3 - _t120;
                event::emit<TradeEvent>(TradeEvent{account: p0, market: _t26, action: _t27, size: _t121, price: p4, is_profit: true, realized_pnl_amount: 0, is_funding_positive: true, realized_funding_amount: 0, is_rebate: true, fee_amount: 0});
                break
            };
            _t16 = *&p1.market;
            if (p2) _t17 = Action::OpenLong{} else _t17 = Action::OpenShort{};
            event::emit<TradeEvent>(TradeEvent{account: p0, market: _t16, action: _t17, size: p3, price: p4, is_profit: _t9, realized_pnl_amount: _t8, is_funding_positive: _t11, realized_funding_amount: _t10, is_rebate: _t13, fee_amount: _t12});
            break
        };
    }
    friend fun extract_backstop_liquidator_covered_loss(p0: UpdatePositionResult): (UpdatePositionResult, u64) {
        if (!(&p0 is Success)) {
            let _t42 = error::invalid_argument(9);
            abort _t42
        };
        let UpdatePositionResult::Success{account: _t18, market: _t19, is_isolated: _t20, position_address: _t21, margin_delta: _t22, backstop_liquidator_covered_loss: _t23, fee_distribution: _t24, realized_pnl: _t25, realized_funding_cost: _t26, unrealized_funding_cost: _t27, updated_funding_index: _t28, volume_delta: _t29, is_taker: _t30} = p0;
        (UpdatePositionResult::Success{account: _t18, market: _t19, is_isolated: _t20, position_address: _t21, margin_delta: _t22, backstop_liquidator_covered_loss: 0, fee_distribution: _t24, realized_pnl: _t25, realized_funding_cost: _t26, unrealized_funding_cost: _t27, updated_funding_index: _t28, volume_delta: _t29, is_taker: _t30}, _t23)
    }
    public fun get_cross_position_markets(p0: address): vector<object::Object<perp_market::PerpMarket>>
        acquires CrossedPosition
    {
        let _t1 = &borrow_global<CrossedPosition>(p0).positions;
        let _t2 = vector::empty<object::Object<perp_market::PerpMarket>>();
        let _t3 = 0;
        let _t4 = vector::length<PerpPosition>(_t1);
        while (_t3 < _t4) {
            let _t5 = vector::borrow<PerpPosition>(_t1, _t3);
            let _t19 = &mut _t2;
            let _t22 = *&_t5.market;
            vector::push_back<object::Object<perp_market::PerpMarket>>(_t19, _t22);
            _t3 = _t3 + 1;
            continue
        };
        _t2
    }
    public fun get_entry_px_times_size_sum(p0: &PerpPosition): u128 {
        *&p0.entry_px_times_size_sum
    }
    fun get_fee_and_volume_delta(p0: address, p1: address, p2: bool, p3: u64, p4: u64, p5: option::Option<builder_code_registry::BuilderCode>, p6: &math::Precision): (fee_distribution::FeeDistribution, u128)
        acquires AccountInfo
    {
        let _t9;
        let _t8;
        p0 = *&borrow_global<AccountInfo>(p0).fee_tracking_addr;
        let _t15 = p4 as u128;
        let _t17 = p3 as u128;
        let _t18 = _t15 * _t17;
        let _t21 = math::get_decimals_multiplier(p6) as u128;
        let _t7 = _t18 / _t21;
        if (p2) {
            _t8 = trading_fees_manager::get_taker_fee_for_notional(p0, p1, _t7, p5);
            _t9 = _t7
        } else {
            _t8 = trading_fees_manager::get_maker_fee_for_notional(p0, p1, _t7, p5);
            _t9 = _t7
        };
        (_t8, _t9)
    }
    public fun get_fixed_sized_requests(p0: &PendingTpSLs): vector<PendingTpSlKey> {
        *&p0.fixed_sized
    }
    friend fun get_fixed_sized_tp_sl(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: bool, p3: u64, p4: option::Option<u64>): option::Option<order_book_types::OrderIdType>
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t8;
        let _t7;
        let _t5 = p0;
        let _t6 = p1;
        let _t21 = isolated_position_address(_t5, _t6);
        if (exists<IsolatedPosition>(_t21)) {
            let _t25 = isolated_position_address(_t5, _t6);
            _t7 = &borrow_global<IsolatedPosition>(_t25).position
        } else {
            let _t10 = &borrow_global<CrossedPosition>(_t5).positions;
            let _t11 = _t10;
            let _t12 = false;
            let _t13 = 0;
            let _t14 = 0;
            let _t15 = vector::length<PerpPosition>(_t11);
            'l0: loop {
                loop {
                    if (!(_t14 < _t15)) break 'l0;
                    let _t64 = &vector::borrow<PerpPosition>(_t11, _t14).market;
                    let _t65 = &_t6;
                    if (_t64 == _t65) break;
                    _t14 = _t14 + 1;
                    continue
                };
                _t12 = true;
                _t13 = _t14;
                break
            };
            if (_t12) _t7 = vector::borrow<PerpPosition>(_t10, _t13) else {
                let _t77 = error::invalid_argument(7);
                abort _t77
            }
        };
        if (is_position_isolated(p0, p1)) _t8 = isolated_position_address(p0, p1) else _t8 = p0;
        let _t9 = position_tp_sl_tracker::new_price_index_key(p3, _t8, p4, false);
        let _t41 = *&_t7.market;
        let _t46 = *&_t7.is_long;
        position_tp_sl_tracker::get_pending_order_id(_t41, _t9, p2, _t46)
    }
    friend fun get_fixed_sized_tp_sl_for_key(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: bool, p3: u64, p4: option::Option<u64>): option::Option<PositionPendingTpSL>
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t13;
        let _t9;
        let _t8;
        let _t7;
        let _t5 = p0;
        let _t6 = p1;
        let _t30 = isolated_position_address(_t5, _t6);
        if (exists<IsolatedPosition>(_t30)) {
            let _t34 = isolated_position_address(_t5, _t6);
            _t7 = &borrow_global<IsolatedPosition>(_t34).position
        } else {
            let _t21 = &borrow_global<CrossedPosition>(_t5).positions;
            let _t22 = _t21;
            let _t23 = false;
            _t13 = 0;
            let _t24 = 0;
            let _t25 = vector::length<PerpPosition>(_t22);
            'l0: loop {
                loop {
                    if (!(_t24 < _t25)) break 'l0;
                    let _t125 = &vector::borrow<PerpPosition>(_t22, _t24).market;
                    let _t126 = &_t6;
                    if (_t125 == _t126) break;
                    _t24 = _t24 + 1;
                    continue
                };
                _t23 = true;
                _t13 = _t24;
                break
            };
            if (_t23) _t7 = vector::borrow<PerpPosition>(_t21, _t13) else {
                let _t138 = error::invalid_argument(7);
                abort _t138
            }
        };
        if (p2) _t8 = *&_t7.tp_reqs else _t8 = *&_t7.sl_reqs;
        if (is_position_isolated(p0, p1)) _t9 = isolated_position_address(p0, p1) else _t9 = p0;
        let _t10 = position_tp_sl_tracker::new_price_index_key(p3, _t9, p4, false);
        let _t11 = &(&_t8).fixed_sized;
        let _t12 = false;
        _t13 = 0;
        let _t14 = 0;
        let _t15 = vector::length<PendingTpSlKey>(_t11);
        'l1: loop {
            loop {
                if (!(_t14 < _t15)) break 'l1;
                let _t65 = &vector::borrow<PendingTpSlKey>(_t11, _t14).price_index;
                let _t66 = &_t10;
                if (_t65 == _t66) break;
                _t14 = _t14 + 1;
                continue
            };
            _t12 = true;
            _t13 = _t14;
            break
        };
        if (_t12) {
            let _t17 = *vector::borrow<PendingTpSlKey>(&(&_t8).fixed_sized, _t13);
            let _t81 = *&(&_t17).price_index;
            let _t85 = *&_t7.is_long;
            let (_t86,_t87,_t88,_t89) = position_tp_sl_tracker::get_pending_tp_sl(p1, _t81, p2, _t85);
            let _t92 = *&(&_t17).order_id;
            let _t95 = position_tp_sl_tracker::get_trigger_price(&(&_t17).price_index);
            return option::some<PositionPendingTpSL>(PositionPendingTpSL{order_id: _t92, trigger_price: _t95, account: _t86, limit_price: _t88, size: _t89})
        };
        option::none<PositionPendingTpSL>()
    }
    friend fun get_fixed_sized_tp_sl_for_order_id(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: bool, p3: u128): option::Option<PositionPendingTpSL>
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t10;
        let _t7;
        let _t6;
        let _t4 = order_book_types::new_order_id_type(p3);
        let _t5 = p1;
        let _t28 = isolated_position_address(p0, _t5);
        if (exists<IsolatedPosition>(_t28)) {
            let _t32 = isolated_position_address(p0, _t5);
            _t6 = &borrow_global<IsolatedPosition>(_t32).position
        } else {
            let _t18 = &borrow_global<CrossedPosition>(p0).positions;
            let _t19 = _t18;
            let _t20 = false;
            _t10 = 0;
            let _t21 = 0;
            let _t22 = vector::length<PerpPosition>(_t19);
            'l0: loop {
                loop {
                    if (!(_t21 < _t22)) break 'l0;
                    let _t111 = &vector::borrow<PerpPosition>(_t19, _t21).market;
                    let _t112 = &_t5;
                    if (_t111 == _t112) break;
                    _t21 = _t21 + 1;
                    continue
                };
                _t20 = true;
                _t10 = _t21;
                break
            };
            if (_t20) _t6 = vector::borrow<PerpPosition>(_t18, _t10) else {
                let _t124 = error::invalid_argument(7);
                abort _t124
            }
        };
        if (p2) _t7 = *&_t6.tp_reqs else _t7 = *&_t6.sl_reqs;
        let _t8 = &(&_t7).fixed_sized;
        let _t9 = false;
        _t10 = 0;
        let _t11 = 0;
        let _t12 = vector::length<PendingTpSlKey>(_t8);
        'l1: loop {
            loop {
                if (!(_t11 < _t12)) break 'l1;
                let _t52 = &vector::borrow<PendingTpSlKey>(_t8, _t11).order_id;
                let _t53 = &_t4;
                if (_t52 == _t53) break;
                _t11 = _t11 + 1;
                continue
            };
            _t9 = true;
            _t10 = _t11;
            break
        };
        if (_t9) {
            let _t14 = *vector::borrow<PendingTpSlKey>(&(&_t7).fixed_sized, _t10);
            let _t68 = *&(&_t14).price_index;
            let _t72 = *&_t6.is_long;
            let (_t73,_t74,_t75,_t76) = position_tp_sl_tracker::get_pending_tp_sl(p1, _t68, p2, _t72);
            let _t79 = *&(&_t14).order_id;
            let _t82 = position_tp_sl_tracker::get_trigger_price(&(&_t14).price_index);
            return option::some<PositionPendingTpSL>(PositionPendingTpSL{order_id: _t79, trigger_price: _t82, account: _t73, limit_price: _t75, size: _t76})
        };
        option::none<PositionPendingTpSL>()
    }
    public fun get_fixed_sized_tp_sl_from_event(p0: &PositionUpdateEvent, p1: bool): vector<FixedSizedTpSlForEvent> {
        let _t2;
        if (p1) _t2 = *&p0.fixed_sized_tps else _t2 = *&p0.fixed_sized_sls;
        _t2
    }
    friend fun get_fixed_sized_tp_sl_orders(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: bool): vector<PositionPendingTpSL>
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t9;
        let _t5;
        let _t4;
        let _t3 = p1;
        let _t23 = isolated_position_address(p0, _t3);
        if (exists<IsolatedPosition>(_t23)) {
            let _t27 = isolated_position_address(p0, _t3);
            _t4 = &borrow_global<IsolatedPosition>(_t27).position
        } else {
            let _t14 = &borrow_global<CrossedPosition>(p0).positions;
            let _t15 = _t14;
            let _t16 = false;
            _t9 = 0;
            let _t17 = 0;
            let _t18 = vector::length<PerpPosition>(_t15);
            'l0: loop {
                loop {
                    if (!(_t17 < _t18)) break 'l0;
                    let _t94 = &vector::borrow<PerpPosition>(_t15, _t17).market;
                    let _t95 = &_t3;
                    if (_t94 == _t95) break;
                    _t17 = _t17 + 1;
                    continue
                };
                _t16 = true;
                _t9 = _t17;
                break
            };
            if (_t16) _t4 = vector::borrow<PerpPosition>(_t14, _t9) else {
                let _t107 = error::invalid_argument(7);
                abort _t107
            }
        };
        if (p2) _t5 = *&_t4.tp_reqs else _t5 = *&_t4.sl_reqs;
        let _t6 = vector::empty<PositionPendingTpSL>();
        let _t7 = *&(&_t5).fixed_sized;
        vector::reverse<PendingTpSlKey>(&mut _t7);
        let _t8 = _t7;
        _t9 = vector::length<PendingTpSlKey>(&_t8);
        while (_t9 > 0) {
            let _t10 = vector::pop_back<PendingTpSlKey>(&mut _t8);
            let _t50 = *&(&_t10).price_index;
            let _t54 = *&_t4.is_long;
            let (_t55,_t56,_t57,_t58) = position_tp_sl_tracker::get_pending_tp_sl(p1, _t50, p2, _t54);
            let _t59 = &mut _t6;
            let _t62 = *&(&_t10).order_id;
            let _t65 = position_tp_sl_tracker::get_trigger_price(&(&_t10).price_index);
            let _t69 = PositionPendingTpSL{order_id: _t62, trigger_price: _t65, account: _t55, limit_price: _t57, size: _t58};
            vector::push_back<PositionPendingTpSL>(_t59, _t69);
            _t9 = _t9 - 1;
            continue
        };
        vector::destroy_empty<PendingTpSlKey>(_t8);
        _t6
    }
    public fun get_full_sized_request(p0: &PendingTpSLs): option::Option<PendingTpSlKey> {
        *&p0.full_sized
    }
    public fun get_full_sized_tp_sl_from_event(p0: &PositionUpdateEvent, p1: bool): option::Option<FullSizedTpSlForEvent> {
        let _t2;
        if (p1) _t2 = *&p0.full_sized_tp else _t2 = *&p0.full_sized_sl;
        _t2
    }
    friend fun get_full_sized_tp_sl_order(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: bool): option::Option<PositionPendingTpSL>
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t10;
        let _t5;
        let _t4;
        let _t3 = p1;
        let _t21 = isolated_position_address(p0, _t3);
        if (exists<IsolatedPosition>(_t21)) {
            let _t25 = isolated_position_address(p0, _t3);
            _t4 = &borrow_global<IsolatedPosition>(_t25).position
        } else {
            let _t11 = &borrow_global<CrossedPosition>(p0).positions;
            let _t12 = _t11;
            let _t13 = false;
            let _t14 = 0;
            let _t15 = 0;
            let _t16 = vector::length<PerpPosition>(_t12);
            'l0: loop {
                loop {
                    if (!(_t15 < _t16)) break 'l0;
                    let _t83 = &vector::borrow<PerpPosition>(_t12, _t15).market;
                    let _t84 = &_t3;
                    if (_t83 == _t84) break;
                    _t15 = _t15 + 1;
                    continue
                };
                _t13 = true;
                _t14 = _t15;
                break
            };
            if (_t13) _t4 = vector::borrow<PerpPosition>(_t11, _t14) else {
                let _t96 = error::invalid_argument(7);
                abort _t96
            }
        };
        if (p2) _t5 = *&_t4.tp_reqs else _t5 = *&_t4.sl_reqs;
        if (option::is_some<PendingTpSlKey>(&(&_t5).full_sized)) {
            let _t6 = option::destroy_some<PendingTpSlKey>(*&(&_t5).full_sized);
            let _t42 = *&(&_t6).price_index;
            let _t46 = *&_t4.is_long;
            let (_t47,_t48,_t49,_t50) = position_tp_sl_tracker::get_pending_tp_sl(p1, _t42, p2, _t46);
            let _t53 = *&(&_t6).order_id;
            let _t56 = position_tp_sl_tracker::get_trigger_price(&(&_t6).price_index);
            _t10 = option::some<PositionPendingTpSL>(PositionPendingTpSL{order_id: _t53, trigger_price: _t56, account: _t47, limit_price: _t49, size: _t50})
        } else _t10 = option::none<PositionPendingTpSL>();
        _t10
    }
    public fun get_maker_volume_for_account(p0: address): u128
        acquires AccountInfo
    {
        trading_fees_manager::get_maker_volume(*&borrow_global<AccountInfo>(p0).fee_tracking_addr)
    }
    public fun get_max_allowed_leverage(p0: &PerpPosition): u8 {
        *&p0.max_allowed_leverage
    }
    friend fun get_open_interest_delta_for_long(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: bool, p3: u64): i64::I64
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t4 = may_be_find_position(p0, p1);
        let _t10 = option::is_none<PerpPosition>(&_t4);
        'l4: loop {
            let _t5;
            'l3: loop {
                'l2: loop {
                    'l0: loop {
                        'l1: loop {
                            loop {
                                if (_t10) if (!p2) break else {
                                    _t5 = option::destroy_some<PerpPosition>(_t4);
                                    if (*&(&_t5).is_long) {
                                        if (!p2) break 'l0;
                                        break 'l1
                                    } else if (p2) {
                                        let _t33 = *&(&_t5).size;
                                        if (p3 < _t33) break 'l2 else break 'l3
                                    } else break 'l4
                                };
                                return i64::new_positive(p3)
                            };
                            return i64::zero()
                        };
                        return i64::new_positive(p3)
                    };
                    let _t26 = *&(&_t5).size;
                    return i64::new_negative(math64::min(p3, _t26))
                };
                return i64::zero()
            };
            let _t39 = *&(&_t5).size;
            return i64::new_positive(p3 - _t39)
        };
        i64::zero()
    }
    fun may_be_find_position(p0: address, p1: object::Object<perp_market::PerpMarket>): option::Option<PerpPosition>
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t2;
        let _t12 = isolated_position_address(p0, p1);
        if (exists<IsolatedPosition>(_t12)) {
            let _t16 = isolated_position_address(p0, p1);
            _t2 = option::some<PerpPosition>(*&borrow_global<IsolatedPosition>(_t16).position)
        } else if (exists<CrossedPosition>(p0)) {
            let _t3 = &borrow_global<CrossedPosition>(p0).positions;
            let _t4 = _t3;
            let _t5 = false;
            let _t6 = 0;
            let _t7 = 0;
            let _t8 = vector::length<PerpPosition>(_t4);
            'l0: loop {
                loop {
                    if (!(_t7 < _t8)) break 'l0;
                    let _t39 = &vector::borrow<PerpPosition>(_t4, _t7).market;
                    let _t40 = &p1;
                    if (_t39 == _t40) break;
                    _t7 = _t7 + 1;
                    continue
                };
                _t5 = true;
                _t6 = _t7;
                break
            };
            if (_t5) _t2 = option::some<PerpPosition>(*vector::borrow<PerpPosition>(_t3, _t6)) else _t2 = option::none<PerpPosition>()
        } else _t2 = option::none<PerpPosition>();
        _t2
    }
    fun get_pnl_and_funding_for_decrease(p0: &PerpPosition, p1: u64, p2: u64): (i64::I64, i64::I64, i64::I64, price_management::AccumulativeIndex) {
        let _t21;
        let _t16;
        let _t15;
        let _t14;
        let _t3 = perp_market_config::get_size_multiplier(*&p0.market);
        let _t34 = p1 as u128;
        let _t36 = p2 as u128;
        let _t4 = _t34 * _t36;
        let _t5 = *&p0.entry_px_times_size_sum;
        let _t6 = p2 as u128;
        let _t7 = (*&p0.size) as u128;
        if (*&p0.is_long) {
            let _t13;
            let _t10 = _t7;
            if (!(_t10 != 0u128)) {
                let _t152 = error::invalid_argument(4);
                abort _t152
            };
            let _t57 = _t5 as u256;
            let _t59 = _t6 as u256;
            let _t11 = _t57 * _t59;
            let _t12 = _t10 as u256;
            if (_t11 == 0u256) if (_t12 != 0u256) _t13 = 0u256 else {
                let _t142 = error::invalid_argument(4);
                abort _t142
            } else _t13 = (_t11 - 1u256) / _t12 + 1u256;
            _t14 = _t13 as u128
        } else if (_t7 != 0u128) {
            let _t157 = _t5 as u256;
            let _t159 = _t6 as u256;
            let _t160 = _t157 * _t159;
            let _t162 = _t7 as u256;
            _t14 = (_t160 / _t162) as u128
        } else {
            let _t167 = error::invalid_argument(4);
            abort _t167
        };
        if (*&p0.is_long) _t15 = _t4 > _t14 else _t15 = _t4 < _t14;
        if (_t4 > _t14) _t16 = _t4 - _t14 else _t16 = _t14 - _t4;
        let _t17 = _t16;
        let _t18 = _t3 as u128;
        if (_t15) _t21 = _t17 / _t18 else {
            let _t19 = _t17;
            let _t20 = _t18;
            if (_t19 == 0u128) if (_t20 != 0u128) _t21 = 0u128 else {
                let _t123 = error::invalid_argument(4);
                abort _t123
            } else _t21 = (_t19 - 1u128) / _t20 + 1u128
        };
        p1 = _t21 as u64;
        let (_t100,_t101) = get_position_funding_cost_and_index(p0);
        let _t23 = _t100;
        let _t24 = _t23;
        let _t103 = &mut _t24;
        let _t107 = *&p0.size;
        i64::mul_div_inplace(_t103, p2, _t107);
        i64::negative_inplace(&mut _t24);
        let _t25 = _t23;
        i64::add_inplace(&mut _t25, _t24);
        let _t26 = i64::new(_t15, p1);
        i64::add_inplace(&mut _t26, _t24);
        (_t26, _t24, _t25, _t101)
    }
    fun get_position_funding_cost_and_index(p0: &PerpPosition): (i64::I64, price_management::AccumulativeIndex) {
        let _t1 = perp_market_config::get_size_multiplier(*&p0.market);
        let _t2 = price_management::get_accumulative_index(*&p0.market);
        let (_t14,_t15) = get_position_funding_cost_and_index_impl(p0, _t1, _t2);
        (_t14, _t15)
    }
    public fun get_position_entry_px_times_size_sum(p0: address, p1: object::Object<perp_market::PerpMarket>): u128
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t3;
        let _t2 = p1;
        let _t14 = isolated_position_address(p0, _t2);
        if (exists<IsolatedPosition>(_t14)) {
            let _t18 = isolated_position_address(p0, _t2);
            _t3 = &borrow_global<IsolatedPosition>(_t18).position
        } else {
            let _t4 = &borrow_global<CrossedPosition>(p0).positions;
            let _t5 = _t4;
            let _t6 = false;
            let _t7 = 0;
            let _t8 = 0;
            let _t9 = vector::length<PerpPosition>(_t5);
            'l0: loop {
                loop {
                    if (!(_t8 < _t9)) break 'l0;
                    let _t39 = &vector::borrow<PerpPosition>(_t5, _t8).market;
                    let _t40 = &_t2;
                    if (_t39 == _t40) break;
                    _t8 = _t8 + 1;
                    continue
                };
                _t6 = true;
                _t7 = _t8;
                break
            };
            if (_t6) _t3 = vector::borrow<PerpPosition>(_t4, _t7) else {
                let _t52 = error::invalid_argument(7);
                abort _t52
            }
        };
        *&_t3.entry_px_times_size_sum
    }
    fun get_position_funding_cost_and_index_impl(p0: &PerpPosition, p1: u64, p2: price_management::AccumulativeIndex): (i64::I64, price_management::AccumulativeIndex) {
        let _t5 = &p0.funding_index_at_last_update;
        let _t6 = &p2;
        let _t9 = *&p0.size;
        let _t13 = *&p0.is_long;
        let _t3 = price_management::get_funding_cost(_t5, _t6, _t9, p1, _t13);
        (i64::add(*&p0.unrealized_funding_amount_before_last_update, _t3), p2)
    }
    public fun get_position_is_long(p0: address, p1: object::Object<perp_market::PerpMarket>): bool
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t3;
        let _t2 = p1;
        let _t14 = isolated_position_address(p0, _t2);
        if (exists<IsolatedPosition>(_t14)) {
            let _t18 = isolated_position_address(p0, _t2);
            _t3 = &borrow_global<IsolatedPosition>(_t18).position
        } else {
            let _t4 = &borrow_global<CrossedPosition>(p0).positions;
            let _t5 = _t4;
            let _t6 = false;
            let _t7 = 0;
            let _t8 = 0;
            let _t9 = vector::length<PerpPosition>(_t5);
            'l0: loop {
                loop {
                    if (!(_t8 < _t9)) break 'l0;
                    let _t39 = &vector::borrow<PerpPosition>(_t5, _t8).market;
                    let _t40 = &_t2;
                    if (_t39 == _t40) break;
                    _t8 = _t8 + 1;
                    continue
                };
                _t6 = true;
                _t7 = _t8;
                break
            };
            if (_t6) _t3 = vector::borrow<PerpPosition>(_t4, _t7) else {
                let _t52 = error::invalid_argument(7);
                abort _t52
            }
        };
        *&_t3.is_long
    }
    public fun get_position_size(p0: address, p1: object::Object<perp_market::PerpMarket>): u64
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t4;
        let _t2 = may_be_find_position(p0, p1);
        if (option::is_some<PerpPosition>(&_t2)) {
            let _t3 = option::destroy_some<PerpPosition>(_t2);
            _t4 = option::some<u64>(*&(&_t3).size)
        } else {
            option::destroy_none<PerpPosition>(_t2);
            _t4 = option::none<u64>()
        };
        option::get_with_default<u64>(&_t4, 0)
    }
    friend fun get_position_size_and_is_long(p0: address, p1: object::Object<perp_market::PerpMarket>): (u64, bool)
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t3;
        let _t2 = p1;
        let _t14 = isolated_position_address(p0, _t2);
        if (exists<IsolatedPosition>(_t14)) {
            let _t18 = isolated_position_address(p0, _t2);
            _t3 = &borrow_global<IsolatedPosition>(_t18).position
        } else {
            let _t4 = &borrow_global<CrossedPosition>(p0).positions;
            let _t5 = _t4;
            let _t6 = false;
            let _t7 = 0;
            let _t8 = 0;
            let _t9 = vector::length<PerpPosition>(_t5);
            'l0: loop {
                loop {
                    if (!(_t8 < _t9)) break 'l0;
                    let _t42 = &vector::borrow<PerpPosition>(_t5, _t8).market;
                    let _t43 = &_t2;
                    if (_t42 == _t43) break;
                    _t8 = _t8 + 1;
                    continue
                };
                _t6 = true;
                _t7 = _t8;
                break
            };
            if (_t6) _t3 = vector::borrow<PerpPosition>(_t4, _t7) else {
                let _t55 = error::invalid_argument(7);
                abort _t55
            }
        };
        let _t23 = *&_t3.size;
        let _t26 = *&_t3.is_long;
        (_t23, _t26)
    }
    public fun get_position_unrealized_funding_cost(p0: address, p1: object::Object<perp_market::PerpMarket>): i64::I64
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t3;
        let _t2 = p1;
        let _t14 = isolated_position_address(p0, _t2);
        if (exists<IsolatedPosition>(_t14)) {
            let _t18 = isolated_position_address(p0, _t2);
            _t3 = &borrow_global<IsolatedPosition>(_t18).position
        } else {
            let _t4 = &borrow_global<CrossedPosition>(p0).positions;
            let _t5 = _t4;
            let _t6 = false;
            let _t7 = 0;
            let _t8 = 0;
            let _t9 = vector::length<PerpPosition>(_t5);
            'l0: loop {
                loop {
                    if (!(_t8 < _t9)) break 'l0;
                    let _t39 = &vector::borrow<PerpPosition>(_t5, _t8).market;
                    let _t40 = &_t2;
                    if (_t39 == _t40) break;
                    _t8 = _t8 + 1;
                    continue
                };
                _t6 = true;
                _t7 = _t8;
                break
            };
            if (_t6) _t3 = vector::borrow<PerpPosition>(_t4, _t7) else {
                let _t52 = error::invalid_argument(7);
                abort _t52
            }
        };
        let (_t22,_t23) = get_position_funding_cost_and_index(_t3);
        _t22
    }
    public fun get_reduce_only_size(p0: &ReduceOnlyValidationResult): u64 {
        if (!(p0 is Success)) {
            let _t8 = error::invalid_argument(8);
            abort _t8
        };
        *&p0.size
    }
    public fun get_size(p0: &PerpPosition): u64 {
        *&p0.size
    }
    public fun get_sl_order(p0: address, p1: object::Object<perp_market::PerpMarket>): option::Option<PositionPendingTpSL>
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        get_full_sized_tp_sl_order(p0, p1, false)
    }
    public fun get_taker_volume_for_account(p0: address): u128
        acquires AccountInfo
    {
        trading_fees_manager::get_taker_volume(*&borrow_global<AccountInfo>(p0).fee_tracking_addr)
    }
    public fun get_tp_order(p0: address, p1: object::Object<perp_market::PerpMarket>): option::Option<PositionPendingTpSL>
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        get_full_sized_tp_sl_order(p0, p1, true)
    }
    public fun get_user_leverage(p0: &PerpPosition): u8 {
        *&p0.user_leverage
    }
    public fun has_position(p0: address, p1: object::Object<perp_market::PerpMarket>): bool
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t2 = may_be_find_position(p0, p1);
        option::is_some<PerpPosition>(&_t2)
    }
    friend fun increase_tp_sl_size(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: u64, p3: option::Option<u64>, p4: u64, p5: bool)
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t10;
        let _t8;
        let _t6 = p0;
        let _t7 = p1;
        let _t23 = isolated_position_address(_t6, _t7);
        if (exists<IsolatedPosition>(_t23)) {
            let _t27 = isolated_position_address(_t6, _t7);
            _t8 = &borrow_global<IsolatedPosition>(_t27).position
        } else {
            let _t12 = &borrow_global<CrossedPosition>(_t6).positions;
            let _t13 = _t12;
            let _t14 = false;
            let _t15 = 0;
            let _t16 = 0;
            let _t17 = vector::length<PerpPosition>(_t13);
            'l0: loop {
                loop {
                    if (!(_t16 < _t17)) break 'l0;
                    let _t75 = &vector::borrow<PerpPosition>(_t13, _t16).market;
                    let _t76 = &_t7;
                    if (_t75 == _t76) break;
                    _t16 = _t16 + 1;
                    continue
                };
                _t14 = true;
                _t15 = _t16;
                break
            };
            if (_t14) _t8 = vector::borrow<PerpPosition>(_t12, _t15) else {
                let _t88 = error::invalid_argument(7);
                abort _t88
            }
        };
        if (!validate_tp_sl_internal(_t8, p2, p5)) {
            let _t59 = error::invalid_argument(15);
            abort _t59
        };
        let _t9 = is_position_isolated(p0, p1);
        if (_t9) _t10 = isolated_position_address(p0, p1) else _t10 = p0;
        let _t11 = position_tp_sl_tracker::new_price_index_key(p2, _t10, p3, false);
        let _t52 = *&_t8.is_long;
        position_tp_sl_tracker::increase_pending_tp_sl_size(p1, _t11, p4, p5, _t52);
        emit_position_update_event(_t8, p0, _t9);
    }
    friend fun init_user_if_new(p0: &signer, p1: address) {
        let _t2 = signer::address_of(p0);
        if (!exists<CrossedPosition>(_t2)) {
            let _t9 = CrossedPosition{positions: vector::empty<PerpPosition>()};
            move_to<CrossedPosition>(p0, _t9)
        };
        if (!exists<IsolatedPositionRefs>(_t2)) {
            let _t14 = IsolatedPositionRefs{extend_refs: ordered_map::new<object::Object<perp_market::PerpMarket>,object::ExtendRef>()};
            move_to<IsolatedPositionRefs>(p0, _t14)
        };
        if (!exists<AccountInfo>(_t2)) {
            let _t19 = AccountInfo{fee_tracking_addr: p1};
            move_to<AccountInfo>(p0, _t19)
        };
    }
    friend fun is_account_liquidatable(p0: &AccountStatus, p1: &liquidation_config::LiquidationConfig, p2: bool): bool {
        let _t7 = *&p0.initial_margin;
        let _t3 = liquidation_config::get_liquidation_margin(p1, _t7, p2);
        i64::is_lt(&p0.account_balance, _t3)
    }
    friend fun is_account_liquidatable_detailed(p0: &AccountStatusDetailed, p1: bool): bool {
        if (p1) {
            let _t4 = &p0.account_balance;
            let _t7 = *&p0.backstop_liquidator_margin;
            p1 = i64::is_lt(_t4, _t7)
        } else {
            let _t11 = &p0.account_balance;
            let _t14 = *&p0.liquidation_margin;
            p1 = i64::is_lt(_t11, _t14)
        };
        p1
    }
    friend fun is_allowed_settle_price(p0: object::Object<perp_market::PerpMarket>, p1: u64, p2: &liquidation_config::LiquidationConfig): (bool, bool) {
        let _t3 = price_management::get_mark_price(p0);
        let _t10 = perp_market_config::get_max_leverage(p0);
        let _t4 = liquidation_config::get_liquidation_price(p2, _t3, _t10, false);
        let _t16 = _t3 + _t4;
        let _t21 = _t3 - _t4;
        (p1 <= _t16, p1 >= _t21)
    }
    friend fun is_insufficient_margin(p0: &UpdatePositionResult): bool {
        let _t1;
        if (p0 is InsufficientMargin) _t1 = true else _t1 = false;
        _t1
    }
    friend fun is_liquidatable(p0: &UpdatePositionResult): bool {
        let _t1;
        if (p0 is Liquidatable) _t1 = true else _t1 = false;
        _t1
    }
    friend fun is_max_allowed_withdraw_from_cross_margin_at_least(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: address, p2: i64::I64, p3: u64): bool
        acquires CrossedPosition
    {
        let _t6;
        let _t4 = cross_position_status(p0, p1);
        let _t14 = i64::sub(*&(&_t4).account_balance, p2);
        let _t18 = i64::new_negative(*&(&_t4).initial_margin);
        let (_t20,_t21) = i64::into_inner(i64::add(_t14, _t18));
        if (_t20) _t6 = _t21 else _t6 = 0;
        _t6 >= p3
    }
    friend fun is_position_liquidatable(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: &liquidation_config::LiquidationConfig, p2: address, p3: object::Object<perp_market::PerpMarket>, p4: bool): bool
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t5 = position_status(p0, p2, p3);
        is_account_liquidatable(&_t5, p1, p4)
    }
    friend fun position_status(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: address, p2: object::Object<perp_market::PerpMarket>): AccountStatus
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t4;
        let _t3 = isolated_position_address(p1, p2);
        if (exists<IsolatedPosition>(_t3)) _t4 = isolated_position_status(p0, _t3) else _t4 = cross_position_status(p0, p1);
        _t4
    }
    fun is_position_liquidatable_crossed(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: &liquidation_config::LiquidationConfig, p2: address, p3: bool): bool
        acquires CrossedPosition
    {
        let _t4 = cross_position_status(p0, p2);
        is_account_liquidatable(&_t4, p1, p3)
    }
    fun is_position_liquidatable_isolated(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: &liquidation_config::LiquidationConfig, p2: address, p3: bool): bool
        acquires IsolatedPosition
    {
        let _t4 = isolated_position_status(p0, p2);
        is_account_liquidatable(&_t4, p1, p3)
    }
    fun isolated_position_status(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: address): AccountStatus
        acquires IsolatedPosition
    {
        let _t8;
        let _t7;
        let _t6;
        let _t5;
        let _t4;
        let _t3;
        let _t2 = &borrow_global<IsolatedPosition>(p1).position;
        let _t17 = *&_t2.size;
        loop {
            if (!(_t17 == 0)) {
                _t3 = price_management::get_mark_price(*&_t2.market);
                let _t37 = *&_t2.size;
                let (_t38,_t39,_t40,_t41) = get_pnl_and_funding_for_decrease(_t2, _t3, _t37);
                _t4 = _t38;
                _t5 = perp_market_config::get_size_multiplier(*&_t2.market);
                _t6 = *&_t2.size;
                _t7 = _t3;
                _t8 = _t5;
                if (_t8 != 0) break;
                let _t85 = error::invalid_argument(4);
                abort _t85
            };
            let _t24 = collateral_balance_sheet::balance_of(p0, p1);
            return AccountStatus{account_balance: i64::new(true, _t24), initial_margin: 0, total_notional_value: 0}
        };
        let _t55 = _t6 as u128;
        let _t57 = _t7 as u128;
        let _t58 = _t55 * _t57;
        let _t60 = _t8 as u128;
        let _t9 = (_t58 / _t60) as u64;
        let _t65 = *&_t2.size;
        let _t70 = *&_t2.max_allowed_leverage;
        let _t10 = margin_required_formula(_t65, _t3, _t5, _t70);
        let _t11 = i64::new_positive(collateral_balance_sheet::balance_of(p0, p1));
        i64::add_inplace(&mut _t11, _t4);
        AccountStatus{account_balance: _t11, initial_margin: _t10, total_notional_value: _t9}
    }
    public fun is_reduce_only_violation(p0: &ReduceOnlyValidationResult): bool {
        let _t1;
        if (p0 is ReduceOnlyViolation) _t1 = true else _t1 = false;
        _t1
    }
    friend fun is_update_successful(p0: &UpdatePositionResult): bool {
        let _t1;
        if (p0 is Success) _t1 = true else if (p0 is Liquidatable) _t1 = false else if (p0 is InsufficientMargin) _t1 = false else if (p0 is InvalidLeverage) _t1 = false else abort 14566554180833181697;
        _t1
    }
    public fun isolated_position_object(p0: address, p1: object::Object<perp_market::PerpMarket>): object::Object<IsolatedPosition> {
        let _t2 = &p0;
        let _t4 = bcs::to_bytes<object::Object<perp_market::PerpMarket>>(&p1);
        object::address_to_object<IsolatedPosition>(object::create_object_address(_t2, _t4))
    }
    friend fun liquidation_price(p0: &PerpPosition, p1: &AccountStatusDetailed): u64 {
        let _t8;
        let _t2 = price_management::get_mark_price(*&p0.market);
        let (_t16,_t17) = i64::into_inner(*&p1.account_balance);
        if (!_t16) abort 1;
        let _t22 = *&p1.backstop_liquidator_margin;
        let _t5 = _t17 - _t22;
        let _t6 = *&p1.total_notional_value;
        if (!(_t6 != 0)) {
            let _t51 = error::invalid_argument(4);
            abort _t51
        };
        let _t31 = _t2 as u128;
        let _t33 = _t5 as u128;
        let _t34 = _t31 * _t33;
        let _t36 = _t6 as u128;
        let _t7 = (_t34 / _t36) as u64;
        if (*&p0.is_long) _t8 = _t2 - _t7 else _t8 = _t2 + _t7;
        _t8
    }
    friend fun max_allowed_withdraw_from_isolated_margin(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: address): u64
        acquires IsolatedPosition
    {
        let _t5;
        let _t2 = &borrow_global<IsolatedPosition>(p1).position;
        let _t3 = margin_required(_t2);
        let _t4 = pnl_with_funding(_t2);
        let _t18 = i64::add(i64::new_positive(collateral_balance_sheet::balance_of(p0, p1)), _t4);
        let _t20 = i64::new_negative(_t3);
        let (_t22,_t23) = i64::into_inner(i64::add(_t18, _t20));
        if (_t22) _t5 = _t23 else _t5 = 0;
        _t5
    }
    friend fun new_perp_position(p0: u64, p1: object::Object<perp_market::PerpMarket>, p2: u128, p3: u8, p4: bool): PerpPosition {
        let _t9;
        let _t6;
        let _t5 = perp_market_config::get_max_leverage(p1);
        if (p3 > 0u8) _t6 = p3 <= _t5 else _t6 = false;
        if (!_t6) {
            let _t64 = error::invalid_argument(2);
            abort _t64
        };
        if (p0 == 0) _t9 = 0 else {
            let _t60 = p0 as u128;
            _t9 = (p2 / _t60) as u64
        };
        let _t37 = price_management::get_accumulative_index(p1);
        let _t38 = i64::zero();
        let _t40 = option::none<PendingTpSlKey>();
        let _t41 = vector::empty<PendingTpSlKey>();
        let _t42 = PendingTpSLs{full_sized: _t40, fixed_sized: _t41};
        let _t43 = option::none<PendingTpSlKey>();
        let _t44 = vector::empty<PendingTpSlKey>();
        let _t10 = PendingTpSLs{full_sized: _t43, fixed_sized: _t44};
        PerpPosition{size: p0, entry_px_times_size_sum: p2, avg_acquire_entry_px: _t9, user_leverage: p3, max_allowed_leverage: _t5, is_long: p4, funding_index_at_last_update: _t37, unrealized_funding_amount_before_last_update: _t38, market: p1, tp_reqs: _t42, sl_reqs: _t10}
    }
    public fun new_pending_requests(p0: option::Option<PendingTpSlKey>, p1: vector<PendingTpSlKey>): PendingTpSLs {
        PendingTpSLs{full_sized: p0, fixed_sized: p1}
    }
    friend fun positions_to_liquidate(p0: address, p1: object::Object<perp_market::PerpMarket>): vector<PerpPosition>
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t3;
        let _t2 = isolated_position_address(p0, p1);
        if (exists<IsolatedPosition>(_t2)) {
            let _t12 = *&borrow_global<IsolatedPosition>(_t2).position;
            let _t13 = vector::empty<PerpPosition>();
            vector::push_back<PerpPosition>(&mut _t13, _t12);
            _t3 = _t13
        } else _t3 = *&borrow_global<CrossedPosition>(p0).positions;
        _t3
    }
    friend fun take_ready_tp_sl_orders(p0: object::Object<perp_market::PerpMarket>, p1: u64, p2: bool, p3: u64): vector<position_tp_sl_tracker::PendingRequest>
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t4;
        if (p2) _t4 = position_tp_sl_tracker::take_ready_price_move_up_orders(p0, p1, p3) else _t4 = position_tp_sl_tracker::take_ready_price_move_down_orders(p0, p1, p3);
        let _t5 = _t4;
        vector::reverse<position_tp_sl_tracker::PendingRequest>(&mut _t5);
        let _t6 = _t5;
        let _t7 = vector::length<position_tp_sl_tracker::PendingRequest>(&_t6);
        'l0: loop {
            loop {
                let _t74;
                let _t67;
                let _t14;
                let _t13;
                let _t11;
                if (!(_t7 > 0)) break 'l0;
                let _t8 = vector::pop_back<position_tp_sl_tracker::PendingRequest>(&mut _t6);
                let _t9 = position_tp_sl_tracker::get_account_from_pending_request(&_t8);
                let _t10 = p0;
                let _t44 = isolated_position_address(_t9, _t10);
                if (exists<IsolatedPosition>(_t44)) {
                    let _t48 = isolated_position_address(_t9, _t10);
                    _t11 = &mut borrow_global_mut<IsolatedPosition>(_t48).position
                } else {
                    let _t17 = &mut borrow_global_mut<CrossedPosition>(_t9).positions;
                    let _t18 = freeze(_t17);
                    let _t19 = false;
                    let _t20 = 0;
                    let _t21 = 0;
                    let _t22 = vector::length<PerpPosition>(_t18);
                    'l1: loop {
                        loop {
                            if (!(_t21 < _t22)) break 'l1;
                            let _t96 = &vector::borrow<PerpPosition>(_t18, _t21).market;
                            let _t97 = &_t10;
                            if (_t96 == _t97) break;
                            _t21 = _t21 + 1;
                            continue
                        };
                        _t19 = true;
                        _t20 = _t21;
                        break
                    };
                    if (_t19) _t11 = vector::borrow_mut<PerpPosition>(_t17, _t20) else break
                };
                let _t12 = *&_t11.is_long;
                if (_t12) _t13 = p2 else _t13 = false;
                if (_t13) _t14 = true else if (_t12) _t14 = false else _t14 = !p2;
                let _t15 = position_tp_sl_tracker::get_size_from_pending_request(&_t8);
                let _t61 = option::is_none<u64>(&_t15);
                let _t16 = position_tp_sl_tracker::get_order_id_from_pending_request(&_t8);
                if (_t61) _t67 = clear_full_sized_tp_sl_for_order(_t11, _t14, _t16) else _t74 = clear_fixed_sized_tp_sl_for_order(_t11, _t14, _t16);
                _t7 = _t7 - 1;
                continue
            };
            let _t109 = error::invalid_argument(7);
            abort _t109
        };
        vector::destroy_empty<position_tp_sl_tracker::PendingRequest>(_t6);
        _t4
    }
    friend fun transfer_balance_to_liquidator(p0: &mut collateral_balance_sheet::CollateralBalanceSheet, p1: address, p2: address, p3: object::Object<perp_market::PerpMarket>) {
        let _t5;
        let _t4 = isolated_position_address(p2, p3);
        if (exists<IsolatedPosition>(_t4)) {
            _t5 = collateral_balance_sheet::balance_of(freeze(p0), _t4);
            let _t21 = collateral_balance_sheet::balance_type_isolated(p2, p3);
            let _t22 = collateral_balance_sheet::change_type_liquidation();
            let _t24 = collateral_balance_sheet::balance_type_cross(p1);
            let _t25 = collateral_balance_sheet::change_type_liquidation();
            collateral_balance_sheet::transfer_position(p0, _t4, p1, _t5, _t21, _t22, _t24, _t25)
        } else {
            _t5 = collateral_balance_sheet::balance_of(freeze(p0), p2);
            let _t35 = collateral_balance_sheet::balance_type_cross(p2);
            let _t36 = collateral_balance_sheet::change_type_liquidation();
            let _t38 = collateral_balance_sheet::balance_type_cross(p1);
            let _t39 = collateral_balance_sheet::change_type_liquidation();
            collateral_balance_sheet::transfer_position(p0, p2, p1, _t5, _t35, _t36, _t38, _t39)
        };
    }
    friend fun transfer_margin_to_isolated_position(p0: &mut collateral_balance_sheet::CollateralBalanceSheet, p1: address, p2: object::Object<perp_market::PerpMarket>, p3: bool, p4: u64)
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t5 = isolated_position_address(p1, p2);
        if (!exists<IsolatedPosition>(_t5)) abort 7;
        if (p3) {
            let _t13 = freeze(p0);
            let _t15 = i64::zero();
            if (!is_max_allowed_withdraw_from_cross_margin_at_least(_t13, p1, _t15, p4)) abort 6;
            if (collateral_balance_sheet::balance_of(freeze(p0), p1) < p4) update_crossed_position_pnl(p0, p1);
            let _t31 = collateral_balance_sheet::balance_type_cross(p1);
            let _t32 = collateral_balance_sheet::change_type_user_movement();
            let _t35 = collateral_balance_sheet::balance_type_isolated(p1, p2);
            let _t36 = collateral_balance_sheet::change_type_user_movement();
            collateral_balance_sheet::transfer_position(p0, p1, _t5, p4, _t31, _t32, _t35, _t36)
        } else if (max_allowed_withdraw_from_isolated_margin(freeze(p0), _t5) >= p4) {
            if (collateral_balance_sheet::balance_of(freeze(p0), _t5) < p4) update_isolated_position_pnl(p0, _t5, p1);
            let _t60 = collateral_balance_sheet::balance_type_isolated(p1, p2);
            let _t61 = collateral_balance_sheet::change_type_user_movement();
            let _t63 = collateral_balance_sheet::balance_type_cross(p1);
            let _t64 = collateral_balance_sheet::change_type_user_movement();
            collateral_balance_sheet::transfer_position(p0, _t5, p1, p4, _t60, _t61, _t63, _t64)
        } else abort 6;
    }
    friend fun update_isolated_position_pnl(p0: &mut collateral_balance_sheet::CollateralBalanceSheet, p1: address, p2: address)
        acquires IsolatedPosition
    {
        let _t3 = &mut borrow_global_mut<IsolatedPosition>(p1).position;
        let _t4 = price_management::get_mark_price(*&_t3.market);
        let _t23 = freeze(_t3);
        let _t27 = *&_t3.size;
        let (_t28,_t29,_t30,_t31) = get_pnl_and_funding_for_decrease(_t23, _t4, _t27);
        let _t6 = _t30;
        let _t8 = _t28;
        let (_t33,_t34) = i64::into_inner(_t8);
        let (_t36,_t37) = i64::into_inner(_t29);
        if (!i64::is_zero(&_t6)) {
            let _t104 = error::invalid_argument(9);
            abort _t104
        };
        let _t43 = *&_t3.market;
        let _t44 = Action::Net{};
        let _t47 = *&_t3.size;
        event::emit<TradeEvent>(TradeEvent{account: p2, market: _t43, action: _t44, size: _t47, price: _t4, is_profit: _t33, realized_pnl_amount: _t34, is_funding_positive: _t36, realized_funding_amount: _t37, is_rebate: true, fee_amount: 0});
        let (_t57,_t58) = i64::into_inner(_t8);
        let _t13 = _t58;
        if (_t57) {
            let _t65 = *&_t3.market;
            let _t66 = collateral_balance_sheet::balance_type_isolated(p2, _t65);
            let _t67 = collateral_balance_sheet::change_type_pnl();
            collateral_balance_sheet::deposit_to_user(p0, p1, _t13, _t66, _t67)
        } else if (collateral_balance_sheet::balance_at_least(freeze(p0), p1, _t13)) {
            let _t95 = *&_t3.market;
            let _t96 = collateral_balance_sheet::balance_type_isolated(p2, _t95);
            let _t97 = collateral_balance_sheet::change_type_pnl();
            collateral_balance_sheet::decrease_balance(p0, p1, _t13, _t96, _t97)
        } else abort 13;
        let _t14 = &mut _t3.funding_index_at_last_update;
        *_t14 = _t31;
        let _t73 = _t4 as u128;
        let _t77 = (*&_t3.size) as u128;
        let _t78 = _t73 * _t77;
        let _t80 = &mut _t3.entry_px_times_size_sum;
        *_t80 = _t78;
        let _t81 = i64::zero();
        let _t83 = &mut _t3.unrealized_funding_amount_before_last_update;
        *_t83 = _t81;
    }
    friend fun unwrap_system_fees(p0: &UpdatePositionResult): i64::I64 {
        if (!(p0 is Success)) {
            let _t8 = error::invalid_argument(9);
            abort _t8
        };
        fee_distribution::get_system_fee_delta(&p0.fee_distribution)
    }
    friend fun unwrap_update_result(p0: UpdatePositionResult): (address, object::Object<perp_market::PerpMarket>, bool, address, option::Option<i64::I64>, fee_distribution::FeeDistribution, option::Option<i64::I64>, option::Option<i64::I64>, i64::I64, price_management::AccumulativeIndex, u128) {
        if (!(&p0 is Success)) {
            let _t46 = error::invalid_argument(9);
            abort _t46
        };
        let UpdatePositionResult::Success{account: _t16, market: _t17, is_isolated: _t18, position_address: _t19, margin_delta: _t20, backstop_liquidator_covered_loss: _t21, fee_distribution: _t22, realized_pnl: _t23, realized_funding_cost: _t24, unrealized_funding_cost: _t25, updated_funding_index: _t26, volume_delta: _t27, is_taker: _t28} = p0;
        if (!(_t21 == 0)) {
            let _t44 = error::invalid_argument(9);
            abort _t44
        };
        (_t16, _t17, _t18, _t19, _t20, _t22, _t23, _t24, _t25, _t26, _t27)
    }
    fun update_single_position(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: &mut PerpPosition, p3: u64, p4: bool, p5: u64, p6: i64::I64, p7: price_management::AccumulativeIndex) {
        let _t19;
        let _t9;
        if (*&p2.size != 0) {
            let _t33 = *&p2.is_long;
            let _t36 = *&p2.avg_acquire_entry_px;
            adl_tracker::remove_position(p0, p1, _t33, _t36)
        };
        if (*&p2.is_long != p4) {
            let _t20;
            if (*&p2.size <= p5) cancel_all_tp_sl_for_position(p2, p0);
            if (*&p2.size >= p5) {
                let _t18;
                let _t8 = *&p2.size - p5;
                _t9 = *&p2.entry_px_times_size_sum;
                let _t10 = _t8 as u128;
                let _t11 = (*&p2.size) as u128;
                if (*&p2.is_long) {
                    let _t17;
                    let _t14 = _t11;
                    if (!(_t14 != 0u128)) {
                        let _t134 = error::invalid_argument(4);
                        abort _t134
                    };
                    let _t78 = _t9 as u256;
                    let _t80 = _t10 as u256;
                    let _t15 = _t78 * _t80;
                    let _t16 = _t14 as u256;
                    if (_t15 == 0u256) if (_t16 != 0u256) _t17 = 0u256 else {
                        let _t124 = error::invalid_argument(4);
                        abort _t124
                    } else _t17 = (_t15 - 1u256) / _t16 + 1u256;
                    _t18 = _t17 as u128
                } else if (_t11 != 0u128) {
                    let _t139 = _t9 as u256;
                    let _t141 = _t10 as u256;
                    let _t142 = _t139 * _t141;
                    let _t144 = _t11 as u256;
                    _t18 = (_t142 / _t144) as u128
                } else {
                    let _t149 = error::invalid_argument(4);
                    abort _t149
                };
                _t19 = &mut p2.entry_px_times_size_sum;
                *_t19 = _t18;
                _t20 = &mut p2.size;
                *_t20 = _t8
            } else {
                let _t153 = *&p2.size;
                let _t154 = p5 - _t153;
                let _t156 = &mut p2.size;
                *_t156 = _t154;
                let _t158 = p3 as u128;
                let _t162 = (*&p2.size) as u128;
                let _t163 = _t158 * _t162;
                let _t165 = &mut p2.entry_px_times_size_sum;
                *_t165 = _t163;
                _t20 = &mut p2.avg_acquire_entry_px;
                *_t20 = p3;
                let _t23 = &mut p2.is_long;
                *_t23 = p4
            }
        } else {
            let _t175 = p3 as u128;
            let _t177 = p5 as u128;
            let _t178 = _t175 * _t177;
            let _t181 = *&p2.entry_px_times_size_sum;
            _t9 = _t178 + _t181;
            let _t186 = *&p2.size;
            let _t187 = p5 + _t186;
            let _t189 = &mut p2.size;
            *_t189 = _t187;
            let _t194 = (*&p2.size) as u128;
            let _t196 = (_t9 / _t194) as u64;
            let _t198 = &mut p2.avg_acquire_entry_px;
            *_t198 = _t196;
            _t19 = &mut p2.entry_px_times_size_sum;
            *_t19 = _t9
        };
        if (*&p2.size != 0) {
            let _t110 = *&p2.is_long;
            let _t113 = *&p2.avg_acquire_entry_px;
            adl_tracker::add_position(p0, p1, _t110, _t113)
        };
        let _t21 = &mut p2.unrealized_funding_amount_before_last_update;
        *_t21 = p6;
        let _t22 = &mut p2.funding_index_at_last_update;
        *_t22 = p7;
    }
    friend fun validate_backstop_liquidate_isolated_position(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: address, p2: address, p3: &PerpPosition, p4: u64, p5: bool, p6: bool): UpdatePositionResult {
        let _t17 = *&p3.size;
        let (_t18,_t19,_t20,_t21) = get_pnl_and_funding_for_decrease(p3, p4, _t17);
        let _t10 = _t18;
        let (_t23,_t24) = i64::into_inner(_t10);
        p4 = _t24;
        let _t11 = collateral_balance_sheet::balance_of(p0, p2);
        let _t12 = 0;
        if (!_t23) {
            if (p4 > _t11) {
                _t12 = p4 - _t11;
                let _t35 = &mut _t10;
                let _t37 = i64::new_positive(_t12);
                i64::add_inplace(_t35, _t37)
            }};
        let _t41 = *&p3.market;
        let _t44 = option::none<i64::I64>();
        let _t47 = fee_distribution::zero_fees(p2);
        let _t49 = option::some<i64::I64>(_t10);
        let _t51 = option::some<i64::I64>(_t19);
        UpdatePositionResult::Success{account: p1, market: _t41, is_isolated: true, position_address: p2, margin_delta: _t44, backstop_liquidator_covered_loss: _t12, fee_distribution: _t47, realized_pnl: _t49, realized_funding_cost: _t51, unrealized_funding_cost: _t20, updated_funding_index: _t21, volume_delta: 0u128, is_taker: p6}
    }
    fun validate_crossed_position_update(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: &liquidation_config::LiquidationConfig, p2: address, p3: address, p4: object::Object<perp_market::PerpMarket>, p5: u64, p6: bool, p7: bool, p8: u64, p9: option::Option<builder_code_registry::BuilderCode>, p10: bool): UpdatePositionResult
        acquires AccountInfo
        acquires CrossedPosition
    {
        let _t11 = &borrow_global<CrossedPosition>(p3).positions;
        let _t12 = _t11;
        let _t13 = false;
        let _t14 = 0;
        let _t15 = 0;
        let _t16 = vector::length<PerpPosition>(_t12);
        'l0: loop {
            loop {
                if (!(_t15 < _t16)) break 'l0;
                let _t37 = &vector::borrow<PerpPosition>(_t12, _t15).market;
                let _t38 = &p4;
                if (_t37 == _t38) break;
                _t15 = _t15 + 1;
                continue
            };
            _t13 = true;
            _t14 = _t15;
            break
        };
        if (_t13) {
            let _t19;
            let _t18 = *vector::borrow<PerpPosition>(_t11, _t14);
            if (*&(&_t18).is_long == p6) _t19 = true else _t19 = *&(&_t18).size == 0;
            loop {
                let _t20;
                if (_t19) _t20 = validate_increase_crossed_position(p0, p2, p3, _t18, p5, p7, p8, p6, p9) else if (*&(&_t18).size >= p8) if (is_position_liquidatable_crossed(p0, p1, p2, p10)) break else {
                    let _t82 = &_t18;
                    _t20 = validate_decrease_crossed_position(p0, p2, _t82, p5, p7, p8, p9, false)
                } else {
                    let _t92 = &_t18;
                    let _t98 = *&(&_t18).size;
                    let _t99 = p8 - _t98;
                    _t20 = validate_flip_crossed_position(p0, p2, _t92, p5, p7, _t99, p6, p9)
                };
                return _t20
            };
            return UpdatePositionResult::Liquidatable{}
        };
        let _t112 = perp_market_config::get_max_leverage(p4);
        let _t21 = new_empty_perp_position(p4, _t112);
        validate_increase_crossed_position(p0, p2, p3, _t21, p5, p7, p8, p6, p9)
    }
    friend fun validate_increase_crossed_position(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: address, p2: address, p3: PerpPosition, p4: u64, p5: bool, p6: u64, p7: bool, p8: option::Option<builder_code_registry::BuilderCode>): UpdatePositionResult
        acquires AccountInfo
        acquires CrossedPosition
    {
        let _t13 = &p3;
        let _t17 = i64::zero();
        validate_increase_position(p0, p1, false, p2, _t13, p4, p5, p6, _t17, p7, p8)
    }
    friend fun validate_decrease_crossed_position(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: address, p2: &PerpPosition, p3: u64, p4: bool, p5: u64, p6: option::Option<builder_code_registry::BuilderCode>, p7: bool): UpdatePositionResult
        acquires AccountInfo
    {
        let _t13;
        let _t12;
        let (_t22,_t23,_t24,_t25) = get_pnl_and_funding_for_decrease(p2, p3, p5);
        let _t11 = _t22;
        if (p7) {
            _t12 = fee_distribution::zero_fees(p1);
            _t13 = 0u128
        } else {
            let _t18 = perp_market_config::get_sz_precision(*&p2.market);
            let _t93 = &_t18;
            let (_t94,_t95) = get_fee_and_volume_delta(p1, p1, p4, p3, p5, p6, _t93);
            _t13 = _t95;
            _t12 = _t94
        };
        let _t32 = fee_distribution::get_position_fee_delta(&_t12);
        let (_t34,_t35) = i64::into_inner(i64::add(_t11, _t32));
        let _t14 = _t35;
        let _t15 = 0;
        loop {
            if (!_t34) {
                let _t16 = collateral_balance_sheet::balance_of(p0, p1);
                if (_t14 > _t16) {
                    let _t17;
                    if (!p7) break;
                    if (i64::is_negative(&_t11)) _t17 = i64::amount(&_t11) > _t14 else _t17 = false;
                    if (_t17) _t15 = i64::amount(&_t11) - _t16 else _t15 = _t14 - _t16;
                    let _t55 = &mut _t11;
                    let _t57 = i64::new_positive(_t15);
                    i64::add_inplace(_t55, _t57)
                }
            };
            let _t61 = *&p2.market;
            let _t64 = option::none<i64::I64>();
            let _t68 = option::some<i64::I64>(_t11);
            let _t70 = option::some<i64::I64>(_t23);
            return UpdatePositionResult::Success{account: p1, market: _t61, is_isolated: false, position_address: p1, margin_delta: _t64, backstop_liquidator_covered_loss: _t15, fee_distribution: _t12, realized_pnl: _t68, realized_funding_cost: _t70, unrealized_funding_cost: _t24, updated_funding_index: _t25, volume_delta: _t13, is_taker: p4}
        };
        UpdatePositionResult::Liquidatable{}
    }
    friend fun validate_flip_crossed_position(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: address, p2: &PerpPosition, p3: u64, p4: bool, p5: u64, p6: bool, p7: option::Option<builder_code_registry::BuilderCode>): UpdatePositionResult
        acquires AccountInfo
        acquires CrossedPosition
    {
        let _t8 = perp_market_config::get_size_multiplier(*&p2.market);
        let _t26 = *&p2.size;
        let (_t27,_t28,_t29,_t30) = get_pnl_and_funding_for_decrease(p2, p3, _t26);
        let _t11 = _t27;
        let _t36 = *&p2.user_leverage;
        _t8 = margin_required_formula(p5, p3, _t8, _t36);
        let _t42 = option::some<object::Object<perp_market::PerpMarket>>(*&p2.market);
        let _t43 = calculate_cross_margin_required(p1, _t42);
        let _t48 = option::some<object::Object<perp_market::PerpMarket>>(*&p2.market);
        let _t12 = cross_positions_pnl(p1, _t48);
        i64::add_inplace(&mut _t12, _t11);
        let _t60 = *&p2.size + p5;
        let _t13 = perp_market_config::get_sz_precision(*&p2.market);
        let _t66 = &_t13;
        let (_t67,_t68) = get_fee_and_volume_delta(p1, p1, p4, p3, _t60, p7, _t66);
        let _t15 = _t67;
        let _t71 = fee_distribution::get_position_fee_delta(&_t15);
        let _t16 = i64::add(_t12, _t71);
        p3 = collateral_balance_sheet::balance_of(p0, p1);
        p5 = _t43 + _t8;
        if (i64::plus_is_less(p3, _t16, p5)) return UpdatePositionResult::InsufficientMargin{};
        let _t87 = *&p2.market;
        let _t90 = option::none<i64::I64>();
        let _t94 = option::some<i64::I64>(_t11);
        let _t96 = option::some<i64::I64>(_t28);
        let _t97 = i64::zero();
        UpdatePositionResult::Success{account: p1, market: _t87, is_isolated: false, position_address: p1, margin_delta: _t90, backstop_liquidator_covered_loss: 0, fee_distribution: _t15, realized_pnl: _t94, realized_funding_cost: _t96, unrealized_funding_cost: _t97, updated_funding_index: _t30, volume_delta: _t68, is_taker: p4}
    }
    friend fun validate_decrease_isolated_position(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: address, p2: address, p3: &PerpPosition, p4: u64, p5: bool, p6: bool, p7: u64, p8: option::Option<builder_code_registry::BuilderCode>): UpdatePositionResult
        acquires AccountInfo
    {
        let (_t28,_t29,_t30,_t31) = get_pnl_and_funding_for_decrease(p3, p4, p7);
        let _t12 = _t28;
        let _t13 = perp_market_config::get_sz_precision(*&p3.market);
        let _t42 = &_t13;
        let (_t43,_t44) = get_fee_and_volume_delta(p1, p2, p6, p4, p7, p8, _t42);
        let _t15 = _t43;
        let (_t46,_t47) = i64::into_inner(_t12);
        p4 = _t47;
        let _t16 = collateral_balance_sheet::balance_of(p0, p2);
        loop {
            let _t23;
            let _t17;
            if (_t46) _t17 = _t16 + p4 else if (p4 > _t16) break else _t17 = _t16 - p4;
            let _t19 = *&p3.size - p7;
            let _t20 = *&p3.size;
            if (!(_t20 != 0)) {
                let _t122 = error::invalid_argument(4);
                abort _t122
            };
            let _t67 = _t16 as u128;
            let _t69 = _t19 as u128;
            let _t21 = _t67 * _t69;
            let _t22 = _t20 as u128;
            if (_t21 == 0u128) if (_t22 != 0u128) _t23 = 0u128 else {
                let _t112 = error::invalid_argument(4);
                abort _t112
            } else _t23 = (_t21 - 1u128) / _t22 + 1u128;
            let _t24 = i64::new_from_subtraction(_t23 as u64, _t17);
            let _t84 = &mut _t24;
            let _t86 = fee_distribution::get_position_fee_delta(&_t15);
            i64::add_inplace(_t84, _t86);
            if (i64::is_positive_or_zero(&_t24)) return UpdatePositionResult::Liquidatable{};
            let _t94 = *&p3.market;
            let _t98 = option::some<i64::I64>(_t24);
            let _t102 = option::some<i64::I64>(_t12);
            let _t104 = option::some<i64::I64>(_t29);
            return UpdatePositionResult::Success{account: p1, market: _t94, is_isolated: true, position_address: p2, margin_delta: _t98, backstop_liquidator_covered_loss: 0, fee_distribution: _t15, realized_pnl: _t102, realized_funding_cost: _t104, unrealized_funding_cost: _t30, updated_funding_index: _t31, volume_delta: _t44, is_taker: p6}
        };
        UpdatePositionResult::Liquidatable{}
    }
    friend fun validate_flip_isolated_position(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: address, p2: address, p3: &PerpPosition, p4: u64, p5: bool, p6: bool, p7: u64, p8: option::Option<builder_code_registry::BuilderCode>): UpdatePositionResult
        acquires AccountInfo
        acquires CrossedPosition
    {
        let _t19;
        let _t24;
        let _t23;
        let _t14;
        let _t13;
        let _t11;
        let _t10;
        let _t36 = *&p3.size;
        let _t9 = validate_decrease_isolated_position(p0, p1, p2, p3, p4, false, p6, _t36, p8);
        let _t40 = is_update_successful(&_t9);
        'l0: loop {
            let _t18;
            loop {
                if (_t40) {
                    let _t26;
                    let (_t45,_t46,_t47,_t48,_t49,_t50,_t51,_t52,_t53,_t54,_t55) = unwrap_update_result(_t9);
                    _t10 = _t55;
                    _t11 = _t54;
                    let _t12 = _t53;
                    _t13 = _t52;
                    _t14 = _t51;
                    let _t15 = _t50;
                    if (!i64::is_zero(&_t12)) {
                        let _t142 = error::invalid_argument(9);
                        abort _t142
                    };
                    let _t17 = i64::unwrap_or_zero(_t49);
                    _t18 = validate_increase_position(p0, p1, true, p2, p3, p4, p6, p7, _t17, p5, p8);
                    if (!is_update_successful(&_t18)) break;
                    let (_t78,_t79,_t80,_t81,_t82,_t83,_t84,_t85,_t86,_t87,_t88) = unwrap_update_result(_t18);
                    _t19 = _t88;
                    let _t20 = _t84;
                    if (!option::is_none<i64::I64>(&_t20)) {
                        let _t138 = error::invalid_argument(9);
                        abort _t138
                    };
                    _t23 = i64::unwrap_or_zero(_t82);
                    _t23 = i64::add(_t17, _t23);
                    _t24 = fee_distribution::add(&_t15, _t83);
                    let _t25 = collateral_balance_sheet::balance_of(p0, p2);
                    if (!option::is_some<i64::I64>(&_t14)) break 'l0;
                    if (i64::is_positive_or_zero(option::borrow<i64::I64>(&_t14))) _t26 = true else _t26 = i64::amount(option::borrow<i64::I64>(&_t14)) <= _t25;
                    if (_t26) break 'l0;
                    abort 14
                };
                return _t9
            };
            return _t18
        };
        let _t112 = *&p3.market;
        let _t116 = option::some<i64::I64>(_t23);
        let _t121 = i64::zero();
        let _t125 = _t10 + _t19;
        UpdatePositionResult::Success{account: p1, market: _t112, is_isolated: true, position_address: p2, margin_delta: _t116, backstop_liquidator_covered_loss: 0, fee_distribution: _t24, realized_pnl: _t14, realized_funding_cost: _t13, unrealized_funding_cost: _t121, updated_funding_index: _t11, volume_delta: _t125, is_taker: p6}
    }
    fun validate_increase_position(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: address, p2: bool, p3: address, p4: &PerpPosition, p5: u64, p6: bool, p7: u64, p8: i64::I64, p9: bool, p10: option::Option<builder_code_registry::BuilderCode>): UpdatePositionResult
        acquires AccountInfo
        acquires CrossedPosition
    {
        let _t23;
        let _t27 = perp_market_config::get_max_leverage(*&p4.market);
        let _t30 = *&p4.user_leverage;
        'l0: loop {
            loop {
                if (!(_t27 < _t30)) {
                    let _t11 = p7;
                    let _t14 = validate_margin_delta_for_open_position(p0, p1, p4, _t11, p8);
                    if (option::is_none<u64>(&_t14)) break;
                    _t11 = option::destroy_some<u64>(_t14);
                    let (_t51,_t52) = get_position_funding_cost_and_index(p4);
                    let _t15 = _t52;
                    p8 = _t51;
                    let _t16 = perp_market_config::get_sz_precision(*&p4.market);
                    let _t63 = &_t16;
                    let (_t64,_t65) = get_fee_and_volume_delta(p1, p3, p6, p5, p7, p10, _t63);
                    let _t17 = _t65;
                    let _t18 = _t64;
                    if (p2) {
                        let _t70 = *&p4.market;
                        let _t20 = option::some<i64::I64>(i64::new_positive(_t11));
                        let _t21 = option::none<i64::I64>();
                        let _t81 = option::none<i64::I64>();
                        _t23 = UpdatePositionResult::Success{account: p1, market: _t70, is_isolated: true, position_address: p3, margin_delta: _t20, backstop_liquidator_covered_loss: 0, fee_distribution: _t18, realized_pnl: _t81, realized_funding_cost: _t21, unrealized_funding_cost: p8, updated_funding_index: _t15, volume_delta: _t17, is_taker: p6};
                        break 'l0
                    };
                    let _t92 = *&p4.market;
                    let _t95 = option::none<i64::I64>();
                    let _t98 = option::none<i64::I64>();
                    let _t99 = option::none<i64::I64>();
                    _t23 = UpdatePositionResult::Success{account: p1, market: _t92, is_isolated: false, position_address: p3, margin_delta: _t95, backstop_liquidator_covered_loss: 0, fee_distribution: _t18, realized_pnl: _t98, realized_funding_cost: _t99, unrealized_funding_cost: p8, updated_funding_index: _t15, volume_delta: _t17, is_taker: p6};
                    break 'l0
                };
                return UpdatePositionResult::InvalidLeverage{}
            };
            return UpdatePositionResult::InsufficientMargin{}
        };
        _t23
    }
    friend fun validate_increase_isolated_position(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: address, p2: address, p3: &PerpPosition, p4: u64, p5: bool, p6: u64, p7: bool, p8: option::Option<builder_code_registry::BuilderCode>): UpdatePositionResult
        acquires AccountInfo
        acquires CrossedPosition
    {
        let _t17 = i64::zero();
        validate_increase_position(p0, p1, true, p2, p3, p4, p5, p6, _t17, p7, p8)
    }
    fun validate_margin_delta_for_open_position(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: address, p2: &PerpPosition, p3: u64, p4: i64::I64): option::Option<u64>
        acquires CrossedPosition
    {
        let _t6;
        let _t5 = perp_market_config::get_size_multiplier(*&p2.market);
        let _t15 = price_management::get_mark_price(*&p2.market);
        let _t19 = *&p2.user_leverage;
        p3 = margin_required_formula(p3, _t15, _t5, _t19);
        if (is_max_allowed_withdraw_from_cross_margin_at_least(p0, p1, p4, p3)) _t6 = option::some<u64>(p3) else _t6 = option::none<u64>();
        _t6
    }
    fun validate_isolated_position_update(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: &liquidation_config::LiquidationConfig, p2: address, p3: address, p4: object::Object<perp_market::PerpMarket>, p5: u64, p6: bool, p7: bool, p8: u64, p9: option::Option<builder_code_registry::BuilderCode>, p10: bool): UpdatePositionResult
        acquires AccountInfo
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t12;
        let _t17 = is_position_liquidatable_isolated(p0, p1, p3, p10);
        loop {
            if (!_t17) {
                let _t11 = &borrow_global<IsolatedPosition>(p3).position;
                if (!(*&_t11.market == p4)) {
                    let _t83 = error::invalid_argument(0);
                    abort _t83
                };
                if (*&_t11.size == 0) p10 = true else p10 = *&_t11.is_long == p6;
                if (p10) {
                    _t12 = validate_increase_isolated_position(p0, p2, p3, _t11, p5, p7, p8, p6, p9);
                    break
                };
                if (*&_t11.size >= p8) {
                    _t12 = validate_decrease_isolated_position(p0, p2, p3, _t11, p5, p6, p7, p8, p9);
                    break
                };
                let _t71 = *&_t11.size;
                let _t72 = p8 - _t71;
                _t12 = validate_flip_isolated_position(p0, p2, p3, _t11, p5, p6, p7, _t72, p9);
                break
            };
            return UpdatePositionResult::Liquidatable{}
        };
        _t12
    }
    friend fun validate_liquidation_position_update(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: address, p2: object::Object<perp_market::PerpMarket>, p3: u64, p4: bool, p5: bool, p6: u64): UpdatePositionResult
        acquires AccountInfo
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t9;
        let _t7 = isolated_position_address(p1, p2);
        let _t27 = exists<IsolatedPosition>(_t7);
        loop {
            let _t15;
            let _t14;
            let _t13;
            let _t12;
            let _t11;
            let _t10;
            let _t8;
            if (_t27) {
                _t8 = &borrow_global<IsolatedPosition>(_t7).position;
                if (*&_t8.market == p2) {
                    let _t39 = *&_t8.size;
                    if (p6 == _t39) {
                        let _t44 = *&_t8.is_long;
                        if (p4 != _t44) {
                            _t9 = validate_backstop_liquidate_isolated_position(p0, p1, _t7, _t8, p3, p4, p5);
                            break
                        } else {
                            let _t58 = error::invalid_argument(12);
                            abort _t58
                        }
                    } else {
                        let _t62 = error::invalid_argument(3);
                        abort _t62
                    }
                } else {
                    let _t66 = error::invalid_argument(0);
                    abort _t66
                }
            } else {
                _t10 = &borrow_global<CrossedPosition>(p1).positions;
                _t11 = _t10;
                _t12 = false;
                _t13 = 0;
                _t14 = 0;
                _t15 = vector::length<PerpPosition>(_t11)
            };
            'l0: loop {
                loop {
                    if (!(_t14 < _t15)) break 'l0;
                    let _t82 = &vector::borrow<PerpPosition>(_t11, _t14).market;
                    let _t83 = &p2;
                    if (_t82 == _t83) break;
                    _t14 = _t14 + 1;
                    continue
                };
                _t12 = true;
                _t13 = _t14;
                break
            };
            if (!_t12) {
                let _t111 = error::invalid_argument(4);
                abort _t111
            };
            let _t17 = *vector::borrow<PerpPosition>(_t10, _t13);
            _t8 = &_t17;
            let _t19 = option::none<builder_code_registry::BuilderCode>();
            _t9 = validate_decrease_crossed_position(p0, p1, _t8, p3, p5, p6, _t19, true);
            break
        };
        _t9
    }
    friend fun validate_position_update(p0: &collateral_balance_sheet::CollateralBalanceSheet, p1: &liquidation_config::LiquidationConfig, p2: address, p3: object::Object<perp_market::PerpMarket>, p4: u64, p5: bool, p6: bool, p7: u64, p8: option::Option<builder_code_registry::BuilderCode>, p9: bool): UpdatePositionResult
        acquires AccountInfo
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t11;
        perp_market_config::validate_price_and_size_allow_below_min_size(p3, p4, p7);
        let _t10 = isolated_position_address(p2, p3);
        if (exists<IsolatedPosition>(_t10)) _t11 = validate_isolated_position_update(p0, p1, p2, _t10, p3, p4, p5, p6, p7, p8, p9) else _t11 = validate_crossed_position_update(p0, p1, p2, p2, p3, p4, p5, p6, p7, p8, p9);
        _t11
    }
    friend fun validate_reduce_only_update(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: bool, p3: u64): ReduceOnlyValidationResult
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t4 = may_be_find_position(p0, p1);
        let _t10 = option::is_none<PerpPosition>(&_t4);
        'l1: loop {
            let _t5;
            'l2: loop {
                'l0: loop {
                    loop {
                        if (!_t10) {
                            _t5 = option::destroy_some<PerpPosition>(_t4);
                            if (*&(&_t5).size == 0) break;
                            if (*&(&_t5).is_long == p2) break 'l0;
                            if (!(*&(&_t5).size < p3)) break 'l1;
                            break 'l2
                        };
                        return ReduceOnlyValidationResult::ReduceOnlyViolation{}
                    };
                    return ReduceOnlyValidationResult::ReduceOnlyViolation{}
                };
                return ReduceOnlyValidationResult::ReduceOnlyViolation{}
            };
            return ReduceOnlyValidationResult::Success{size: *&(&_t5).size}
        };
        ReduceOnlyValidationResult::Success{size: p3}
    }
    friend fun validate_tp_sl(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: u64, p3: bool): bool
        acquires CrossedPosition
        acquires IsolatedPosition
    {
        let _t5;
        let _t4 = p1;
        let _t16 = isolated_position_address(p0, _t4);
        if (exists<IsolatedPosition>(_t16)) {
            let _t20 = isolated_position_address(p0, _t4);
            _t5 = &borrow_global<IsolatedPosition>(_t20).position
        } else {
            let _t6 = &borrow_global<CrossedPosition>(p0).positions;
            let _t7 = _t6;
            let _t8 = false;
            let _t9 = 0;
            let _t10 = 0;
            let _t11 = vector::length<PerpPosition>(_t7);
            'l0: loop {
                loop {
                    if (!(_t10 < _t11)) break 'l0;
                    let _t42 = &vector::borrow<PerpPosition>(_t7, _t10).market;
                    let _t43 = &_t4;
                    if (_t42 == _t43) break;
                    _t10 = _t10 + 1;
                    continue
                };
                _t8 = true;
                _t9 = _t10;
                break
            };
            if (_t8) _t5 = vector::borrow<PerpPosition>(_t6, _t9) else {
                let _t55 = error::invalid_argument(7);
                abort _t55
            }
        };
        validate_tp_sl_internal(_t5, p2, p3)
    }
}
