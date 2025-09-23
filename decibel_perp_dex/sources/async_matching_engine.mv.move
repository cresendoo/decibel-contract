module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::async_matching_engine {
    use 0x1::big_ordered_map;
    use 0x7::order_book_types;
    use 0x1::option;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine_types;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::builder_code_registry;
    use 0x1::object;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market;
    use 0x1::signer;
    use 0x7::market;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::clearinghouse_perp;
    use 0x7::market_types;
    use 0x1::event;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::accounts_collateral;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions;
    use 0x1::string;
    use 0x1::debug;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::liquidation;
    use 0x1::error;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::decibel_time;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market_config;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::tp_sl_utils;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_management;
    use 0x7::order_book;
    use 0x7::single_order_book;
    use 0x1::vector;
    use 0x7::single_order_types;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine;
    enum PendingRequest has copy, drop, store {
        Order {
            _0: PendingOrder,
        }
        Twap {
            _0: PendingTwap,
        }
        ContinuedOrder {
            _0: ContinuedPendingOrder,
        }
        Liquidation {
            _0: PendingLiquidation,
        }
    }
    struct PendingOrder has copy, drop, store {
        account: address,
        price: u64,
        orig_size: u64,
        is_buy: bool,
        time_in_force: order_book_types::TimeInForce,
        is_reduce_only: bool,
        order_id: order_book_types::OrderIdType,
        client_order_id: option::Option<u64>,
        trigger_condition: option::Option<order_book_types::TriggerCondition>,
        tp: option::Option<perp_engine_types::ChildTpSlOrder>,
        sl: option::Option<perp_engine_types::ChildTpSlOrder>,
        builder_code: option::Option<builder_code_registry::BuilderCode>,
    }
    struct PendingTwap has copy, drop, store {
        account: address,
        order_id: order_book_types::OrderIdType,
        orig_size: u64,
        remaining_size: u64,
        is_buy: bool,
        is_reduce_only: bool,
        twap_frequency_s: u64,
        twap_end_time_s: u64,
    }
    struct ContinuedPendingOrder has copy, drop, store {
        account: address,
        price: u64,
        orig_size: u64,
        is_buy: bool,
        time_in_force: order_book_types::TimeInForce,
        is_reduce_only: bool,
        order_id: order_book_types::OrderIdType,
        client_order_id: option::Option<u64>,
        remaining_size: u64,
        trigger_condition: option::Option<order_book_types::TriggerCondition>,
        tp: option::Option<perp_engine_types::ChildTpSlOrder>,
        sl: option::Option<perp_engine_types::ChildTpSlOrder>,
        builder_code: option::Option<builder_code_registry::BuilderCode>,
    }
    struct PendingLiquidation has copy, drop, store {
        user: address,
    }
    struct AsyncMatchingEngine has key {
        pending_requests: big_ordered_map::BigOrderedMap<PendingRequestKey, PendingRequest>,
        async_matching_enabled: bool,
        tie_breaker_generator: u128,
    }
    struct PendingRequestKey has copy, drop, store {
        time: u64,
        tie_breaker: u128,
    }
    struct SystemPurgedOrderEvent has drop, store {
        market: object::Object<perp_market::PerpMarket>,
        account: address,
        order_id: order_book_types::OrderIdType,
    }
    friend fun register_market(p0: &signer, p1: bool) {
        let _t2 = AsyncMatchingEngine{pending_requests: big_ordered_map::new_with_config<PendingRequestKey,PendingRequest>(0u16, 16u16, true), async_matching_enabled: p1, tie_breaker_generator: 0u128};
        let _t11 = signer::address_of(p0);
        if (exists<AsyncMatchingEngine>(_t11)) abort 10;
        move_to<AsyncMatchingEngine>(p0, _t2);
    }
    fun place_order_and_update_work_unit(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: u64, p3: u64, p4: u64, p5: bool, p6: order_book_types::TimeInForce, p7: option::Option<order_book_types::TriggerCondition>, p8: perp_engine_types::OrderMetadata, p9: order_book_types::OrderIdType, p10: option::Option<u64>, p11: bool, p12: &mut u32): market::OrderMatchResult {
        let _t16;
        let _t30 = *p12;
        let _t13 = clearinghouse_perp::market_callbacks(p0);
        let _t35 = &_t13;
        let _t14 = perp_market::place_order_with_order_id(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, _t30, false, p11, _t35);
        let _t15 = market::number_of_matches(&_t14);
        p2 = market::number_of_fills(&_t14);
        if (!((_t15 as u64) >= p2)) abort 15;
        if (_t15 == 0u32) {
            _t16 = p12;
            *_t16 = *_t16 - 1u32
        } else {
            _t16 = p12;
            *_t16 = *_t16 - _t15
        };
        _t14
    }
    fun add_taker_order_to_pending(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: u64, p3: u64, p4: bool, p5: order_book_types::TimeInForce, p6: bool, p7: order_book_types::OrderIdType, p8: option::Option<u64>, p9: option::Option<order_book_types::TriggerCondition>, p10: option::Option<perp_engine_types::ChildTpSlOrder>, p11: option::Option<perp_engine_types::ChildTpSlOrder>, p12: option::Option<builder_code_registry::BuilderCode>)
        acquires AsyncMatchingEngine
    {
        let _t13 = new_pending_event_key(p0);
        let _t14 = PendingOrder{account: p1, price: p2, orig_size: p3, is_buy: p4, time_in_force: p5, is_reduce_only: p6, order_id: p7, client_order_id: p8, trigger_condition: p9, tp: p10, sl: p11, builder_code: p12};
        let _t15 = p0;
        let _t33 = object::object_address<perp_market::PerpMarket>(&_t15);
        let _t35 = &mut borrow_global_mut<AsyncMatchingEngine>(_t33).pending_requests;
        let _t38 = PendingRequest::Order{_0: _t14};
        big_ordered_map::add<PendingRequestKey,PendingRequest>(_t35, _t13, _t38);
    }
    fun new_pending_event_key(p0: object::Object<perp_market::PerpMarket>): PendingRequestKey
        acquires AsyncMatchingEngine
    {
        let _t6 = decibel_time::now_microseconds();
        let _t1 = p0;
        let _t9 = object::object_address<perp_market::PerpMarket>(&_t1);
        let _t2 = borrow_global_mut<AsyncMatchingEngine>(_t9);
        let _t3 = &mut _t2.tie_breaker_generator;
        *_t3 = *_t3 + 1u128;
        let _t20 = *&_t2.tie_breaker_generator;
        PendingRequestKey{time: _t6, tie_breaker: _t20}
    }
    friend fun drain_async_queue(p0: object::Object<perp_market::PerpMarket>)
        acquires AsyncMatchingEngine
    {
        let _t1 = p0;
        let _t12 = object::object_address<perp_market::PerpMarket>(&_t1);
        let _t2 = borrow_global_mut<AsyncMatchingEngine>(_t12);
        let _t3 = 0;
        'l0: loop {
            'l1: loop {
                loop {
                    if (big_ordered_map::is_empty<PendingRequestKey,PendingRequest>(&_t2.pending_requests)) break 'l0;
                    if (_t3 >= 100) break 'l1;
                    _t3 = _t3 + 1;
                    let (_t27,_t28) = big_ordered_map::borrow_front<PendingRequestKey,PendingRequest>(&_t2.pending_requests);
                    let _t4 = _t28;
                    let _t5 = _t27;
                    let _t31 = &mut _t2.pending_requests;
                    let _t32 = &_t5;
                    let _t6 = big_ordered_map::remove<PendingRequestKey,PendingRequest>(_t31, _t32);
                    _t4 = &_t6;
                    if (_t4 is Liquidation) {
                        let PendingRequest::Liquidation{_0: _t39} = _t6;
                        continue
                    };
                    if (_t4 is Twap) {
                        let PendingRequest::Twap{_0: _t44} = _t6;
                        let _t7 = _t44;
                        let _t48 = *&(&_t7).account;
                        let _t51 = *&(&_t7).order_id;
                        event::emit<SystemPurgedOrderEvent>(SystemPurgedOrderEvent{market: p0, account: _t48, order_id: _t51});
                        continue
                    };
                    if (_t4 is Order) {
                        let PendingRequest::Order{_0: _t57} = _t6;
                        let _t8 = _t57;
                        let _t61 = *&(&_t8).account;
                        let _t64 = *&(&_t8).order_id;
                        event::emit<SystemPurgedOrderEvent>(SystemPurgedOrderEvent{market: p0, account: _t61, order_id: _t64});
                        continue
                    };
                    if (!(_t4 is ContinuedOrder)) break;
                    let PendingRequest::ContinuedOrder{_0: _t69} = _t6;
                    let _t9 = _t69;
                    let _t73 = *&(&_t9).account;
                    let _t76 = *&(&_t9).order_id;
                    event::emit<SystemPurgedOrderEvent>(SystemPurgedOrderEvent{market: p0, account: _t73, order_id: _t76});
                    continue
                };
                abort 14566554180833181697
            };
            return ()
        };
    }
    friend fun liquidate_position(p0: address, p1: object::Object<perp_market::PerpMarket>)
        acquires AsyncMatchingEngine
    {
        liquidate_position_with_fill_limit(p0, p1, 10u32);
    }
    friend fun liquidate_position_with_fill_limit(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: u32)
        acquires AsyncMatchingEngine
    {
        let _t3 = accounts_collateral::position_status(p0, p1);
        let _t4 = string::utf8(vector[108u8, 105u8, 113u8, 117u8, 105u8, 100u8, 97u8, 116u8, 101u8, 95u8, 112u8, 111u8, 115u8, 105u8, 116u8, 105u8, 111u8, 110u8, 95u8, 119u8, 105u8, 116u8, 104u8, 95u8, 102u8, 105u8, 108u8, 108u8, 95u8, 108u8, 105u8, 109u8, 105u8, 116u8]);
        debug::print<string::String>(&_t4);
        debug::print<perp_positions::AccountStatusDetailed>(&_t3);
        if (!perp_positions::is_account_liquidatable_detailed(&_t3, false)) {
            let _t41 = error::invalid_argument(liquidation::get_enot_liquidatable());
            abort _t41
        };
        let _t19 = accounts_collateral::backstop_liquidator();
        if (!(p0 != _t19)) {
            let _t39 = error::invalid_argument(liquidation::get_ecannot_liquidate_backstop_liquidator());
            abort _t39
        };
        let _t5 = PendingLiquidation{user: p0};
        let _t6 = new_pending_liquidation_key(p1);
        let _t7 = p1;
        let _t27 = object::object_address<perp_market::PerpMarket>(&_t7);
        let _t29 = &mut borrow_global_mut<AsyncMatchingEngine>(_t27).pending_requests;
        let _t32 = PendingRequest::Liquidation{_0: _t5};
        big_ordered_map::add<PendingRequestKey,PendingRequest>(_t29, _t6, _t32);
        if (p2 > 0u32) trigger_matching_internal(p1, p2);
    }
    fun new_pending_liquidation_key(p0: object::Object<perp_market::PerpMarket>): PendingRequestKey
        acquires AsyncMatchingEngine
    {
        let _t1 = p0;
        let _t7 = object::object_address<perp_market::PerpMarket>(&_t1);
        let _t2 = borrow_global_mut<AsyncMatchingEngine>(_t7);
        let _t3 = &mut _t2.tie_breaker_generator;
        *_t3 = *_t3 + 1u128;
        let _t4 = *&_t2.tie_breaker_generator;
        PendingRequestKey{time: 0, tie_breaker: _t4}
    }
    fun trigger_matching_internal(p0: object::Object<perp_market::PerpMarket>, p1: u32)
        acquires AsyncMatchingEngine
    {
        let _t2 = p0;
        let _t32 = object::object_address<perp_market::PerpMarket>(&_t2);
        let _t3 = borrow_global_mut<AsyncMatchingEngine>(_t32);
        let _t4 = decibel_time::now_microseconds();
        if (!(p1 > 0u32)) abort 16;
        let _t5 = p1;
        'l0: loop {
            'l1: loop {
                loop {
                    let _t17;
                    let _t26;
                    let _t25;
                    let _t24;
                    let _t22;
                    let _t21;
                    let _t20;
                    let _t19;
                    let _t18;
                    let _t14;
                    let _t13;
                    let _t16;
                    let _t15;
                    let _t12;
                    let _t11;
                    let _t9;
                    let _t6;
                    if (big_ordered_map::is_empty<PendingRequestKey,PendingRequest>(&_t3.pending_requests)) _t6 = false else _t6 = _t5 > 0u32;
                    if (!_t6) break 'l0;
                    let (_t48,_t49) = big_ordered_map::borrow_front<PendingRequestKey,PendingRequest>(&_t3.pending_requests);
                    let _t7 = _t49;
                    let _t8 = _t48;
                    if (*&_t3.async_matching_enabled) _t9 = *&(&_t8).time >= _t4 else _t9 = false;
                    if (_t9) break 'l1;
                    let _t62 = &mut _t3.pending_requests;
                    let _t63 = &_t8;
                    let _t10 = big_ordered_map::remove<PendingRequestKey,PendingRequest>(_t62, _t63);
                    _t7 = &_t10;
                    if (_t7 is Order) {
                        let PendingRequest::Order{_0: _t70} = _t10;
                        let PendingOrder{account: _t71, price: _t72, orig_size: _t73, is_buy: _t74, time_in_force: _t75, is_reduce_only: _t76, order_id: _t77, client_order_id: _t78, trigger_condition: _t79, tp: _t80, sl: _t81, builder_code: _t82} = _t70;
                        _t11 = _t82;
                        _t12 = _t81;
                        _t13 = _t80;
                        _t14 = _t79;
                        _t15 = _t78;
                        _t16 = _t77;
                        _t17 = _t76;
                        _t18 = _t75;
                        _t19 = _t74;
                        _t20 = _t73;
                        _t21 = _t72;
                        _t22 = _t71;
                        let _t92 = option::none<perp_engine_types::TwapMetadata>();
                        let _t96 = perp_engine_types::new_order_metadata(_t17, _t92, _t13, _t12, _t11);
                        let _t100 = &mut _t5;
                        let (_t102,_t103,_t104,_t105,_t106) = market::destroy_order_match_result(place_order_and_update_work_unit(p0, _t22, _t21, _t20, _t20, _t19, _t18, _t14, _t96, _t16, _t15, true, _t100));
                        let _t23 = _t104;
                        _t24 = _t103;
                        _t16 = _t102;
                        if (option::is_some<market::OrderCancellationReason>(&_t23)) _t25 = market::is_fill_limit_violation(option::destroy_some<market::OrderCancellationReason>(_t23)) else _t25 = false;
                        if (!_t25) continue;
                        _t26 = ContinuedPendingOrder{account: _t22, price: _t21, orig_size: _t20, is_buy: _t19, time_in_force: _t18, is_reduce_only: _t17, order_id: _t16, client_order_id: _t15, remaining_size: _t24, trigger_condition: _t14, tp: _t13, sl: _t12, builder_code: _t11};
                        let _t128 = &mut _t3.pending_requests;
                        let _t131 = PendingRequest::ContinuedOrder{_0: _t26};
                        big_ordered_map::add<PendingRequestKey,PendingRequest>(_t128, _t8, _t131);
                        continue
                    };
                    if (_t7 is Twap) {
                        let PendingRequest::Twap{_0: _t137} = _t10;
                        let _t141 = &mut _t5;
                        trigger_pending_twap(p0, _t3, _t137, _t141, _t8);
                        continue
                    };
                    if (_t7 is ContinuedOrder) {
                        let PendingRequest::ContinuedOrder{_0: _t147} = _t10;
                        let ContinuedPendingOrder{account: _t148, price: _t149, orig_size: _t150, is_buy: _t151, time_in_force: _t152, is_reduce_only: _t153, order_id: _t154, client_order_id: _t155, remaining_size: _t156, trigger_condition: _t157, tp: _t158, sl: _t159, builder_code: _t160} = _t147;
                        _t11 = _t160;
                        _t12 = _t159;
                        _t13 = _t158;
                        _t14 = _t157;
                        _t21 = _t156;
                        _t15 = _t155;
                        _t16 = _t154;
                        _t17 = _t153;
                        _t18 = _t152;
                        _t19 = _t151;
                        _t24 = _t150;
                        _t20 = _t149;
                        _t22 = _t148;
                        let _t170 = option::none<perp_engine_types::TwapMetadata>();
                        let _t174 = perp_engine_types::new_order_metadata(_t17, _t170, _t13, _t12, _t11);
                        let _t178 = &mut _t5;
                        let (_t180,_t181,_t182,_t183,_t184) = market::destroy_order_match_result(place_order_and_update_work_unit(p0, _t22, _t20, _t24, _t21, _t19, _t18, _t14, _t174, _t16, _t15, false, _t178));
                        let _t28 = _t182;
                        _t21 = _t181;
                        _t16 = _t180;
                        if (option::is_some<market::OrderCancellationReason>(&_t28)) _t25 = market::is_fill_limit_violation(option::destroy_some<market::OrderCancellationReason>(_t28)) else _t25 = false;
                        if (!_t25) continue;
                        _t26 = ContinuedPendingOrder{account: _t22, price: _t20, orig_size: _t24, is_buy: _t19, time_in_force: _t18, is_reduce_only: _t17, order_id: _t16, client_order_id: _t15, remaining_size: _t21, trigger_condition: _t14, tp: _t13, sl: _t12, builder_code: _t11};
                        let _t206 = &mut _t3.pending_requests;
                        let _t209 = PendingRequest::ContinuedOrder{_0: _t26};
                        big_ordered_map::add<PendingRequestKey,PendingRequest>(_t206, _t8, _t209);
                        continue
                    };
                    if (!(_t7 is Liquidation)) break;
                    let PendingRequest::Liquidation{_0: _t214} = _t10;
                    let PendingLiquidation{user: _t215} = _t214;
                    _t22 = _t215;
                    let _t218 = &mut _t5;
                    if (!liquidation::liquidate_position_internal(p0, _t22, _t218)) continue;
                    let _t29 = PendingLiquidation{user: _t22};
                    let _t223 = &mut _t3.pending_requests;
                    let _t226 = PendingRequest::Liquidation{_0: _t29};
                    big_ordered_map::add<PendingRequestKey,PendingRequest>(_t223, _t8, _t226);
                    continue
                };
                abort 14566554180833181697
            };
            return ()
        };
    }
    friend fun place_order(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: u64, p3: u64, p4: bool, p5: order_book_types::TimeInForce, p6: bool, p7: option::Option<order_book_types::OrderIdType>, p8: option::Option<u64>, p9: option::Option<u64>, p10: option::Option<u64>, p11: option::Option<u64>, p12: option::Option<u64>, p13: option::Option<u64>, p14: option::Option<builder_code_registry::BuilderCode>): order_book_types::OrderIdType
        acquires AsyncMatchingEngine
    {
        let _t22;
        let _t19;
        let _t16;
        let _t15;
        perp_market_config::validate_price_and_size(p0, p2, p3);
        if (option::is_none<order_book_types::OrderIdType>(&p7)) {
            _t15 = perp_market::next_order_id(p0);
            _t16 = true
        } else {
            _t15 = option::destroy_some<order_book_types::OrderIdType>(p7);
            _t16 = false
        };
        let (_t42,_t43) = tp_sl_utils::validate_and_get_child_tp_sl_orders(p0, _t15, p4, p10, p11, p12, p13);
        let _t17 = _t43;
        let _t18 = _t42;
        if (option::is_some<perp_engine_types::ChildTpSlOrder>(&_t18)) _t19 = true else _t19 = option::is_some<perp_engine_types::ChildTpSlOrder>(&_t17);
        if (_t19) {
            if (p6) abort 12;
            if (!option::is_none<u64>(&p9)) abort 13
        };
        if (option::is_some<builder_code_registry::BuilderCode>(&p14)) {
            let _t55 = option::borrow<builder_code_registry::BuilderCode>(&p14);
            builder_code_registry::validate_builder_code(p1, _t55)
        };
        if (option::is_some<u64>(&p9)) {
            let _t20 = price_management::get_mark_price(p0);
            let _t21 = option::destroy_some<u64>(p9);
            if (p4) {
                if (!(_t20 < _t21)) abort 14;
                _t22 = option::some<order_book_types::TriggerCondition>(order_book_types::price_move_up_condition(_t21))
            } else if (_t20 > _t21) _t22 = option::some<order_book_types::TriggerCondition>(order_book_types::price_move_down_condition(_t21)) else abort 14
        } else _t22 = option::none<order_book_types::TriggerCondition>();
        let _t23 = perp_market::is_taker_order(p0, p2, p4, _t22);
        if (_t16) {
            let _t85 = market_types::order_status_acknowledged();
            let _t24 = string::utf8(vector[]);
            let _t88 = &_t24;
            let _t90 = option::none<perp_engine_types::TwapMetadata>();
            let _t94 = perp_engine_types::new_order_metadata(p6, _t90, _t18, _t17, p14);
            let _t25 = clearinghouse_perp::market_callbacks(p0);
            let _t99 = &_t25;
            perp_market::emit_event_for_order(p0, _t15, p8, p1, p3, p3, p3, p2, p4, _t23, _t85, _t88, _t94, _t22, p5, _t99)
        };
        if (_t23) add_taker_order_to_pending(p0, p1, p2, p3, p4, p5, p6, _t15, p8, _t22, _t18, _t17, p14) else {
            let _t126 = option::none<perp_engine_types::TwapMetadata>();
            let _t130 = perp_engine_types::new_order_metadata(p6, _t126, _t18, _t17, p14);
            let _t26 = clearinghouse_perp::market_callbacks(p0);
            let _t138 = &_t26;
            let _t139 = perp_market::place_order_with_order_id(p0, p1, p2, p3, p3, p4, p5, _t22, _t130, _t15, p8, 10000u32, true, true, _t138);
        };
        trigger_matching(p0, 10u32);
        _t15
    }
    friend fun trigger_matching(p0: object::Object<perp_market::PerpMarket>, p1: u32)
        acquires AsyncMatchingEngine
    {
        trigger_matching_internal(p0, p1);
    }
    fun trigger_pending_twap(p0: object::Object<perp_market::PerpMarket>, p1: &mut AsyncMatchingEngine, p2: PendingTwap, p3: &mut u32, p4: PendingRequestKey) {
        let _t14;
        let PendingTwap{account: _t30, order_id: _t31, orig_size: _t32, remaining_size: _t33, is_buy: _t34, is_reduce_only: _t35, twap_frequency_s: _t36, twap_end_time_s: _t37} = p2;
        let _t5 = _t37;
        let _t6 = _t36;
        let _t7 = _t35;
        let _t8 = _t34;
        let _t9 = _t33;
        let _t10 = _t32;
        let _t11 = _t31;
        let _t12 = _t30;
        let _t13 = decibel_time::now_seconds();
        if (_t13 + _t6 > _t5) _t14 = 1 else _t14 = (_t5 - _t13) / _t6 + 1;
        let _t47 = _t9 / _t14;
        let _t15 = perp_market_config::get_lot_size(p0);
        let _t16 = _t47 / _t15 * _t15;
        let _t17 = perp_market::get_slippage_price(p0, _t8, 300);
        let _t59 = option::is_none<u64>(&_t17);
        'l0: loop {
            let _t21;
            let _t20;
            loop {
                if (!_t59) {
                    let _t28;
                    let _t27;
                    let _t26;
                    let _t25;
                    let _t88 = option::destroy_some<u64>(_t17);
                    _t15 = perp_market_config::round_price_to_ticker(p0, _t88, _t8);
                    let _t97 = order_book_types::immediate_or_cancel();
                    let _t98 = option::none<order_book_types::TriggerCondition>();
                    let _t103 = option::some<perp_engine_types::TwapMetadata>(perp_engine_types::new_twap_metadata(_t6, _t5));
                    let _t104 = option::none<perp_engine_types::ChildTpSlOrder>();
                    let _t105 = option::none<perp_engine_types::ChildTpSlOrder>();
                    let _t106 = option::none<builder_code_registry::BuilderCode>();
                    let _t107 = perp_engine_types::new_order_metadata(_t7, _t103, _t104, _t105, _t106);
                    let _t109 = option::none<u64>();
                    let (_t113,_t114,_t115,_t116,_t117) = market::destroy_order_match_result(place_order_and_update_work_unit(p0, _t12, _t15, _t10, _t16, _t8, _t97, _t98, _t107, _t11, _t109, true, p3));
                    let _t19 = _t115;
                    _t20 = _t113;
                    _t21 = 0;
                    let _t22 = _t116;
                    vector::reverse<u64>(&mut _t22);
                    let _t23 = _t22;
                    let _t24 = vector::length<u64>(&_t23);
                    while (_t24 > 0) {
                        _t25 = vector::pop_back<u64>(&mut _t23);
                        _t21 = _t21 + _t25;
                        _t24 = _t24 - 1
                    };
                    vector::destroy_empty<u64>(_t23);
                    if (option::is_some<market::OrderCancellationReason>(&_t19)) _t26 = market::is_fill_limit_violation(option::destroy_some<market::OrderCancellationReason>(_t19)) else _t26 = false;
                    if (_t26) break;
                    _t24 = _t9 - _t21;
                    _t25 = _t14 - 1;
                    if (option::is_none<market::OrderCancellationReason>(&_t19)) _t27 = true else _t27 = market::is_ioc_violation(option::destroy_some<market::OrderCancellationReason>(_t19));
                    if (_t27) _t28 = _t25 != 0 else _t28 = false;
                    if (!_t28) break 'l0;
                    let _t176 = option::none<u64>();
                    let _t185 = option::some<order_book_types::TriggerCondition>(order_book_types::new_time_based_trigger_condition(decibel_time::now_seconds() + _t6));
                    let _t186 = order_book_types::immediate_or_cancel();
                    let _t191 = option::some<perp_engine_types::TwapMetadata>(perp_engine_types::new_twap_metadata(_t6, _t5));
                    let _t192 = option::none<perp_engine_types::ChildTpSlOrder>();
                    let _t193 = option::none<perp_engine_types::ChildTpSlOrder>();
                    let _t194 = option::none<builder_code_registry::BuilderCode>();
                    let _t195 = perp_engine_types::new_order_metadata(_t7, _t191, _t192, _t193, _t194);
                    let _t196 = order_book::new_single_order_request<perp_engine_types::OrderMetadata>(_t12, _t20, _t176, _t15, _t10, _t24, _t8, _t185, _t186, _t195);
                    perp_market::place_maker_order(p0, _t196);
                    break 'l0
                };
                let _t65 = option::none<u64>();
                let _t74 = option::some<order_book_types::TriggerCondition>(order_book_types::new_time_based_trigger_condition(decibel_time::now_seconds() + _t6));
                let _t75 = order_book_types::immediate_or_cancel();
                let _t80 = option::some<perp_engine_types::TwapMetadata>(perp_engine_types::new_twap_metadata(_t6, _t5));
                let _t81 = option::none<perp_engine_types::ChildTpSlOrder>();
                let _t82 = option::none<perp_engine_types::ChildTpSlOrder>();
                let _t83 = option::none<builder_code_registry::BuilderCode>();
                let _t84 = perp_engine_types::new_order_metadata(_t7, _t80, _t81, _t82, _t83);
                let _t85 = order_book::new_single_order_request<perp_engine_types::OrderMetadata>(_t12, _t11, _t65, 0, _t10, _t16, _t8, _t74, _t75, _t84);
                perp_market::place_maker_order(p0, _t85);
                return ()
            };
            let _t147 = _t16 - _t21;
            p2 = PendingTwap{account: _t12, order_id: _t20, orig_size: _t10, remaining_size: _t147, is_buy: _t8, is_reduce_only: _t7, twap_frequency_s: _t6, twap_end_time_s: _t5};
            let _t154 = &mut p1.pending_requests;
            let _t157 = PendingRequest::Twap{_0: p2};
            big_ordered_map::add<PendingRequestKey,PendingRequest>(_t154, p4, _t157);
            return ()
        };
    }
    friend fun trigger_price_based_conditional_orders(p0: object::Object<perp_market::PerpMarket>, p1: u64)
        acquires AsyncMatchingEngine
    {
        let _t2 = perp_market::take_ready_price_based_orders(p0, p1, 10);
        p1 = 0;
        loop {
            let _t18 = vector::length<single_order_types::SingleOrder<perp_engine_types::OrderMetadata>>(&_t2);
            if (!(p1 < _t18)) break;
            let (_t24,_t25,_t26,_t27,_t28,_t29,_t30,_t31,_t32,_t33,_t34) = single_order_types::destroy_single_order<perp_engine_types::OrderMetadata>(*vector::borrow<single_order_types::SingleOrder<perp_engine_types::OrderMetadata>>(&_t2, p1));
            let _t3 = _t34;
            let _t42 = perp_engine_types::is_reduce_only(&_t3);
            let _t44 = option::some<order_book_types::OrderIdType>(_t25);
            let _t46 = option::none<u64>();
            let _t47 = option::none<u64>();
            let _t48 = option::none<u64>();
            let _t49 = option::none<u64>();
            let _t50 = option::none<u64>();
            let _t52 = perp_engine_types::get_builder_code_from_metadata(&_t3);
            let _t53 = place_order(p0, _t24, _t28, _t29, _t31, _t33, _t42, _t44, _t26, _t46, _t47, _t48, _t49, _t50, _t52);
            p1 = p1 + 1;
            continue
        };
    }
    friend fun trigger_twap_orders(p0: object::Object<perp_market::PerpMarket>)
        acquires AsyncMatchingEngine
    {
        let _t1 = perp_market::take_ready_time_based_orders(p0, 10);
        let _t2 = 0;
        loop {
            let _t20 = vector::length<single_order_types::SingleOrder<perp_engine_types::OrderMetadata>>(&_t1);
            if (!(_t2 < _t20)) break;
            let (_t26,_t27,_t28,_t29,_t30,_t31,_t32,_t33,_t34,_t35,_t36) = single_order_types::destroy_single_order<perp_engine_types::OrderMetadata>(*vector::borrow<single_order_types::SingleOrder<perp_engine_types::OrderMetadata>>(&_t1, _t2));
            let _t3 = _t36;
            let (_t38,_t39) = perp_engine_types::get_twap_from_metadata(&_t3);
            let _t44 = perp_engine_types::is_reduce_only(&_t3);
            let _t11 = PendingTwap{account: _t26, order_id: _t27, orig_size: _t31, remaining_size: _t32, is_buy: _t33, is_reduce_only: _t44, twap_frequency_s: _t38, twap_end_time_s: _t39};
            let _t12 = new_pending_event_key(p0);
            let _t13 = p0;
            let _t52 = object::object_address<perp_market::PerpMarket>(&_t13);
            let _t54 = &mut borrow_global_mut<AsyncMatchingEngine>(_t52).pending_requests;
            let _t57 = PendingRequest::Twap{_0: _t11};
            big_ordered_map::add<PendingRequestKey,PendingRequest>(_t54, _t12, _t57);
            _t2 = _t2 + 1;
            continue
        };
    }
}
