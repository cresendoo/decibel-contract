module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::clearinghouse_perp {
    use 0x1::object;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market;
    use 0x1::option;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine_types;
    use 0x7::market_types;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market_config;
    use 0x1::string;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::open_interest_tracker;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::i64;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::builder_code_registry;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::accounts_collateral;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions;
    use 0x1::error;
    use 0x7::order_book_types;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::tp_sl_utils;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_management;
    use 0x1::string_utils;
    use 0x1::math64;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::liquidation;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::async_matching_engine;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine;
    friend fun settle_trade(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: address, p3: bool, p4: u64, p5: u64, p6: option::Option<perp_engine_types::OrderMetadata>, p7: option::Option<perp_engine_types::OrderMetadata>): market_types::SettleTradeResult {
        let _t19;
        let _t18;
        let _t17;
        let _t15;
        let _t12;
        let _t11;
        let _t9;
        if (!(p1 != p2)) {
            let _t172 = error::invalid_argument(13);
            abort _t172
        };
        if (!(p5 > 0)) {
            let _t170 = error::invalid_argument(1);
            abort _t170
        };
        if (!option::is_some<perp_engine_types::OrderMetadata>(&p6)) {
            let _t168 = error::invalid_argument(1);
            abort _t168
        };
        let _t8 = option::destroy_some<perp_engine_types::OrderMetadata>(p6);
        if (option::is_none<perp_engine_types::OrderMetadata>(&p7)) _t9 = perp_engine_types::new_default_order_metadata() else _t9 = option::destroy_some<perp_engine_types::OrderMetadata>(p7);
        let _t37 = perp_market_config::can_settle_order(p0, p2, p1);
        'l4: loop {
            'l3: loop {
                'l2: loop {
                    'l1: loop {
                        let _t14;
                        'l0: loop {
                            let _t10;
                            loop {
                                if (_t37) {
                                    _t10 = check_for_invalid_settlement_price(p0, p4, p3);
                                    if (option::is_some<market_types::SettleTradeResult>(&_t10)) break;
                                    let (_t61,_t62,_t63,_t64) = get_reduce_only_settlement_size(p0, p1, p2, p3, p5, _t8, _t9);
                                    _t11 = _t64;
                                    _t12 = _t63;
                                    _t14 = _t61;
                                    if (option::is_some<market_types::SettleTradeResult>(&_t14)) break 'l0;
                                    _t15 = open_interest_tracker::get_max_open_interest_delta_for_market(p0);
                                    let _t76 = option::destroy_some<u64>(_t62);
                                    let (_t78,_t79,_t80) = get_adjusted_size_for_open_interest_cap(p1, p2, p0, p3, _t76, _t15);
                                    _t17 = _t79;
                                    _t15 = _t78;
                                    if (_t15 == 0) break 'l1;
                                    if (_t80) _t12 = option::some<string::String>(string::utf8(vector[77u8, 97u8, 120u8, 32u8, 111u8, 112u8, 101u8, 110u8, 32u8, 105u8, 110u8, 116u8, 101u8, 114u8, 101u8, 115u8, 116u8, 32u8, 118u8, 105u8, 111u8, 108u8, 97u8, 116u8, 105u8, 111u8, 110u8]));
                                    let _t101 = perp_engine_types::get_builder_code_from_metadata(&_t8);
                                    let _t103 = perp_engine_types::use_backstop_liquidation_margin(&_t8);
                                    _t18 = accounts_collateral::validate_position_update(p1, p0, p4, p3, true, _t15, _t101, _t103);
                                    if (!perp_positions::is_update_successful(&_t18)) break 'l2;
                                    let _t121 = perp_engine_types::get_builder_code_from_metadata(&_t9);
                                    let _t123 = perp_engine_types::use_backstop_liquidation_margin(&_t9);
                                    _t19 = accounts_collateral::validate_position_update(p2, p0, p4, !p3, false, _t15, _t121, _t123);
                                    if (!perp_positions::is_update_successful(&_t19)) break 'l3;
                                    let _t20 = perp_positions::unwrap_system_fees(&_t19);
                                    let _t135 = &mut _t20;
                                    let _t137 = perp_positions::unwrap_system_fees(&_t18);
                                    i64::add_inplace(_t135, _t137);
                                    if (!i64::is_strictly_positive(&_t20)) break 'l4;
                                    let _t164 = error::invalid_argument(14);
                                    abort _t164
                                };
                                let _t41 = option::some<string::String>(string::utf8(vector[77u8, 97u8, 114u8, 107u8, 101u8, 116u8, 32u8, 105u8, 115u8, 32u8, 104u8, 97u8, 108u8, 116u8, 101u8, 100u8]));
                                let _t44 = option::some<string::String>(string::utf8(vector[77u8, 97u8, 114u8, 107u8, 101u8, 116u8, 32u8, 105u8, 115u8, 32u8, 104u8, 97u8, 108u8, 116u8, 101u8, 100u8]));
                                return market_types::new_settle_trade_result(0, _t41, _t44)
                            };
                            return option::destroy_some<market_types::SettleTradeResult>(_t10)
                        };
                        return option::destroy_some<market_types::SettleTradeResult>(_t14)
                    };
                    let _t85 = option::none<string::String>();
                    let _t88 = option::some<string::String>(string::utf8(vector[77u8, 97u8, 120u8, 32u8, 111u8, 112u8, 101u8, 110u8, 32u8, 105u8, 110u8, 116u8, 101u8, 114u8, 101u8, 115u8, 116u8, 32u8, 118u8, 105u8, 111u8, 108u8, 97u8, 116u8, 105u8, 111u8, 110u8]));
                    return market_types::new_settle_trade_result(0, _t85, _t88)
                };
                let _t111 = option::some<string::String>(string::utf8(vector[84u8, 97u8, 107u8, 101u8, 114u8, 32u8, 111u8, 114u8, 100u8, 101u8, 114u8, 32u8, 105u8, 115u8, 32u8, 105u8, 110u8, 118u8, 97u8, 108u8, 105u8, 100u8]));
                return market_types::new_settle_trade_result(0, _t11, _t111)
            };
            let _t130 = option::some<string::String>(string::utf8(vector[77u8, 97u8, 107u8, 101u8, 114u8, 32u8, 111u8, 114u8, 100u8, 101u8, 114u8, 32u8, 105u8, 115u8, 32u8, 105u8, 110u8, 118u8, 97u8, 108u8, 105u8, 100u8]));
            return market_types::new_settle_trade_result(0, _t130, _t12)
        };
        accounts_collateral::commit_update_position(p4, p3, _t15, _t18);
        accounts_collateral::commit_update_position(p4, !p3, _t15, _t19);
        let _t152 = &_t8;
        place_child_tp_sl_orders(p0, p1, _t15, _t152);
        let _t156 = &_t9;
        place_child_tp_sl_orders(p0, p2, _t15, _t156);
        open_interest_tracker::mark_open_interest_delta_for_market(p0, _t17);
        market_types::new_settle_trade_result(_t15, _t11, _t12)
    }
    fun check_for_invalid_settlement_price(p0: object::Object<perp_market::PerpMarket>, p1: u64, p2: bool): option::Option<market_types::SettleTradeResult> {
        let _t5;
        let (_t20,_t21) = accounts_collateral::is_allowed_settle_price(p0, p1);
        let _t3 = _t21;
        let _t4 = _t20;
        if (_t4) _t5 = !_t3 else _t5 = true;
        if (_t5) {
            let _t7;
            let _t6;
            let _t16;
            let _t15;
            let _t13;
            let _t11;
            let _t10;
            if (p2) {
                _t6 = _t4;
                _t7 = _t3
            } else {
                _t6 = _t3;
                _t7 = _t4
            };
            let _t8 = price_management::get_mark_price(p0);
            if (_t7) _t10 = option::none<string::String>() else {
                let _t17 = vector[83u8, 101u8, 116u8, 116u8, 108u8, 101u8, 32u8, 112u8, 114u8, 105u8, 99u8, 101u8, 32u8, 40u8, 123u8, 125u8, 41u8, 32u8, 102u8, 111u8, 114u8, 32u8, 123u8, 125u8, 32u8, 105u8, 115u8, 32u8, 116u8, 111u8, 111u8, 32u8, 102u8, 97u8, 114u8, 32u8, 102u8, 114u8, 111u8, 109u8, 32u8, 116u8, 104u8, 101u8, 32u8, 109u8, 97u8, 114u8, 107u8, 32u8, 112u8, 114u8, 105u8, 99u8, 101u8, 32u8, 40u8, 123u8, 125u8, 41u8];
                _t13 = &_t17;
                if (p2) _t15 = vector[115u8, 104u8, 111u8, 114u8, 116u8] else _t15 = vector[108u8, 111u8, 110u8, 103u8];
                _t16 = string::utf8(_t15);
                _t10 = option::some<string::String>(string_utils::format3<u64,string::String,u64>(_t13, p1, _t16, _t8))
            };
            if (_t6) _t11 = option::none<string::String>() else {
                let _t12 = vector[83u8, 101u8, 116u8, 116u8, 108u8, 101u8, 32u8, 112u8, 114u8, 105u8, 99u8, 101u8, 32u8, 40u8, 123u8, 125u8, 41u8, 32u8, 102u8, 111u8, 114u8, 32u8, 123u8, 125u8, 32u8, 105u8, 115u8, 32u8, 116u8, 111u8, 111u8, 32u8, 102u8, 97u8, 114u8, 32u8, 102u8, 114u8, 111u8, 109u8, 32u8, 116u8, 104u8, 101u8, 32u8, 109u8, 97u8, 114u8, 107u8, 32u8, 112u8, 114u8, 105u8, 99u8, 101u8, 32u8, 40u8, 123u8, 125u8, 41u8];
                _t13 = &_t12;
                if (p2) _t15 = vector[108u8, 111u8, 110u8, 103u8] else _t15 = vector[115u8, 104u8, 111u8, 114u8, 116u8];
                _t16 = string::utf8(_t15);
                _t11 = option::some<string::String>(string_utils::format3<u64,string::String,u64>(_t13, p1, _t16, _t8))
            };
            return option::some<market_types::SettleTradeResult>(market_types::new_settle_trade_result(0, _t10, _t11))
        };
        option::none<market_types::SettleTradeResult>()
    }
    fun get_reduce_only_settlement_size(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: address, p3: bool, p4: u64, p5: perp_engine_types::OrderMetadata, p6: perp_engine_types::OrderMetadata): (option::Option<market_types::SettleTradeResult>, option::Option<u64>, option::Option<string::String>, option::Option<string::String>) {
        let _t11;
        let _t10;
        let _t7 = option::none<string::String>();
        let _t8 = option::none<string::String>();
        let _t19 = &mut _t7;
        let _t9 = get_settlement_size_and_reason(p0, p1, p3, p4, p5, _t19);
        let _t22 = option::is_none<u64>(&_t9);
        loop {
            if (_t22) {
                let _t24 = option::none<string::String>();
                let _t27 = option::some<string::String>(string::utf8(vector[84u8, 97u8, 107u8, 101u8, 114u8, 32u8, 114u8, 101u8, 100u8, 117u8, 99u8, 101u8, 32u8, 111u8, 110u8, 108u8, 121u8, 32u8, 118u8, 105u8, 111u8, 108u8, 97u8, 116u8, 105u8, 111u8, 110u8]));
                let _t29 = option::some<market_types::SettleTradeResult>(market_types::new_settle_trade_result(0, _t24, _t27));
                let _t30 = option::none<u64>();
                let _t31 = option::none<string::String>();
                let _t32 = option::none<string::String>();
                return (_t29, _t30, _t31, _t32)
            } else {
                _t10 = option::destroy_some<u64>(_t9);
                let _t41 = &mut _t8;
                _t11 = get_settlement_size_and_reason(p0, p2, !p3, p4, p6, _t41);
                if (!option::is_none<u64>(&_t11)) break
            };
            let _t48 = option::some<string::String>(string::utf8(vector[77u8, 97u8, 107u8, 101u8, 114u8, 32u8, 114u8, 101u8, 100u8, 117u8, 99u8, 101u8, 32u8, 111u8, 110u8, 108u8, 121u8, 32u8, 118u8, 105u8, 111u8, 108u8, 97u8, 116u8, 105u8, 111u8, 110u8]));
            let _t51 = option::some<market_types::SettleTradeResult>(market_types::new_settle_trade_result(0, _t48, _t7));
            let _t52 = option::none<u64>();
            let _t53 = option::none<string::String>();
            let _t54 = option::none<string::String>();
            return (_t51, _t52, _t53, _t54)
        };
        p4 = option::destroy_some<u64>(_t11);
        p4 = math64::min(_t10, p4);
        let _t60 = option::none<market_types::SettleTradeResult>();
        let _t62 = option::some<u64>(p4);
        (_t60, _t62, _t7, _t8)
    }
    fun get_adjusted_size_for_open_interest_cap(p0: address, p1: address, p2: object::Object<perp_market::PerpMarket>, p3: bool, p4: u64, p5: u64): (u64, i64::I64, bool) {
        let _t15 = perp_positions::get_open_interest_delta_for_long(p0, p2, p3, p4);
        let _t21 = perp_positions::get_open_interest_delta_for_long(p1, p2, !p3, p4);
        let _t8 = i64::add(_t15, _t21);
        loop {
            let _t7;
            let _t9;
            if (p4 < p5) {
                _t9 = p4;
                _t7 = _t8;
                p3 = false
            } else if (i64::is_gt(&_t8, p5)) if (i64::is_positive_or_zero(&_t8)) {
                let _t10 = i64::amount(&_t8) - p5;
                if (_t10 >= p4) break else {
                    _t9 = p4 - _t10;
                    _t7 = i64::new_positive(p5);
                    p3 = true
                }
            } else {
                let _t54 = error::invalid_argument(10);
                abort _t54
            } else {
                _t9 = p4;
                _t7 = _t8;
                p3 = false
            };
            return (_t9, _t7, p3)
        };
        let _t45 = i64::zero();
        (0, _t45, true)
    }
    fun place_child_tp_sl_orders(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: u64, p3: &perp_engine_types::OrderMetadata) {
        let _t6;
        let _t4 = perp_engine_types::get_tp_from_metadata(p3);
        let _t5 = perp_engine_types::get_sl_from_metadata(p3);
        if (option::is_none<perp_engine_types::ChildTpSlOrder>(&_t4)) _t6 = option::is_none<perp_engine_types::ChildTpSlOrder>(&_t5) else _t6 = false;
        'l0: loop {
            loop {
                if (!_t6) {
                    let _t10;
                    let _t9;
                    let _t7 = perp_positions::get_position_size(p1, p0);
                    _t7 = math64::min(p2, _t7);
                    if (_t7 == 0) break;
                    if (option::is_some<perp_engine_types::ChildTpSlOrder>(&_t4)) {
                        let (_t34,_t35,_t36,_t37) = perp_engine_types::destroy_child_tp_sl_order(option::destroy_some<perp_engine_types::ChildTpSlOrder>(_t4));
                        let _t8 = _t36;
                        _t9 = _t35;
                        _t10 = _t34;
                        if (perp_positions::validate_tp_sl(p1, p0, _t10, true)) {
                            let _t48 = tp_sl_utils::get_active_tp_sl_status();
                            tp_sl_utils::emit_order_based_event(p0, _t10, _t9, _t8, _t7, _t48, true);
                            let _t55 = option::some<u64>(_t7);
                            let _t58 = option::some<order_book_types::OrderIdType>(_t8);
                            let _t59 = tp_sl_utils::place_tp_sl_order_for_position_internal(p0, p1, _t10, _t9, _t55, true, _t58);
                        }
                    };
                    if (!option::is_some<perp_engine_types::ChildTpSlOrder>(&_t5)) break 'l0;
                    let (_t64,_t65,_t66,_t67) = perp_engine_types::destroy_child_tp_sl_order(option::destroy_some<perp_engine_types::ChildTpSlOrder>(_t5));
                    let _t11 = _t66;
                    _t9 = _t65;
                    _t10 = _t64;
                    if (!perp_positions::validate_tp_sl(p1, p0, _t10, false)) break 'l0;
                    let _t78 = tp_sl_utils::get_active_tp_sl_status();
                    tp_sl_utils::emit_order_based_event(p0, _t10, _t9, _t11, _t7, _t78, false);
                    let _t85 = option::some<u64>(_t7);
                    let _t88 = option::some<order_book_types::OrderIdType>(_t11);
                    let _t89 = tp_sl_utils::place_tp_sl_order_for_position_internal(p0, p1, _t10, _t9, _t85, false, _t88);
                    break 'l0
                };
                return ()
            };
            return ()
        };
    }
    friend fun validate_bulk_order_placement(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: vector<u64>, p3: vector<u64>, p4: vector<u64>, p5: vector<u64>): bool {
        let _t11 = accounts_collateral::backstop_liquidator();
        'l0: loop {
            'l1: loop {
                loop {
                    if (!(p1 == _t11)) {
                        if (0x1::vector::length<u64>(&p2) != 0) {
                            let (_t20,_t21) = get_effective_price_and_size(p3, p2);
                            let _t28 = option::none<builder_code_registry::BuilderCode>();
                            let _t8 = accounts_collateral::validate_position_update(p1, p0, _t20, true, true, _t21, _t28, false);
                            if (!perp_positions::is_update_successful(&_t8)) break 'l0
                        };
                        if (!(0x1::vector::length<u64>(&p4) != 0)) break;
                        let (_t40,_t41) = get_effective_price_and_size(p5, p4);
                        let _t48 = option::none<builder_code_registry::BuilderCode>();
                        let _t9 = accounts_collateral::validate_position_update(p1, p0, _t40, false, true, _t41, _t48, false);
                        if (perp_positions::is_update_successful(&_t9)) break;
                        break 'l1
                    };
                    return true
                };
                return true
            };
            return false
        };
        false
    }
    fun get_effective_price_and_size(p0: vector<u64>, p1: vector<u64>): (u64, u64) {
        let _t7 = 0x1::vector::length<u64>(&p1);
        let _t9 = 0x1::vector::length<u64>(&p0);
        if (!(_t7 == _t9)) {
            let _t61 = error::invalid_argument(1);
            abort _t61
        };
        let _t2 = 0;
        let _t3 = 0u128;
        let _t4 = 0u128;
        loop {
            let _t16 = 0x1::vector::length<u64>(&p0);
            if (!(_t2 < _t16)) break;
            let _t22 = (*0x1::vector::borrow<u64>(&p0, _t2)) as u128;
            let _t27 = (*0x1::vector::borrow<u64>(&p1, _t2)) as u128;
            let _t5 = _t22 * _t27;
            _t3 = _t3 + _t5;
            _t5 = (*0x1::vector::borrow<u64>(&p1, _t2)) as u128;
            _t4 = _t4 + _t5;
            _t2 = _t2 + 1;
            continue
        };
        _t3 = _t3 / _t4;
        if (!(_t3 <= 18446744073709551615u128)) {
            let _t59 = error::invalid_argument(1);
            abort _t59
        };
        if (!(_t4 <= 18446744073709551615u128)) {
            let _t57 = error::invalid_argument(1);
            abort _t57
        };
        let _t53 = _t3 as u64;
        let _t55 = _t4 as u64;
        (_t53, _t55)
    }
    friend fun validate_order_placement(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: bool, p3: bool, p4: u64, p5: order_book_types::TimeInForce, p6: u64, p7: perp_engine_types::OrderMetadata): bool {
        let _t8 = perp_engine_types::get_tp_from_metadata(&p7);
        let _t9 = perp_engine_types::get_sl_from_metadata(&p7);
        if (option::is_some<perp_engine_types::ChildTpSlOrder>(&_t8)) {
            let (_t23,_t24,_t25,_t26) = perp_engine_types::destroy_child_tp_sl_order(option::destroy_some<perp_engine_types::ChildTpSlOrder>(_t8));
            let _t32 = tp_sl_utils::get_inactive_tp_sl_status();
            tp_sl_utils::emit_order_based_event(p0, _t23, _t24, _t25, p6, _t32, true)
        };
        if (option::is_some<perp_engine_types::ChildTpSlOrder>(&_t9)) {
            let (_t38,_t39,_t40,_t41) = perp_engine_types::destroy_child_tp_sl_order(option::destroy_some<perp_engine_types::ChildTpSlOrder>(_t9));
            let _t47 = tp_sl_utils::get_inactive_tp_sl_status();
            tp_sl_utils::emit_order_based_event(p0, _t38, _t39, _t40, p6, _t47, false)
        };
        let _t51 = perp_market_config::can_place_order(p0, p1);
        'l0: loop {
            'l1: loop {
                loop {
                    if (_t51) {
                        let _t54 = order_book_types::immediate_or_cancel();
                        if (p5 == _t54) break;
                        let _t58 = accounts_collateral::backstop_liquidator();
                        if (!(p1 == _t58)) break 'l0;
                        break 'l1
                    };
                    return false
                };
                return true
            };
            return true
        };
        let _t68 = perp_engine_types::get_builder_code_from_metadata(&p7);
        let _t70 = perp_engine_types::use_backstop_liquidation_margin(&p7);
        let _t14 = accounts_collateral::validate_position_update(p1, p0, p4, p3, p2, p6, _t68, _t70);
        perp_positions::is_update_successful(&_t14)
    }
    friend fun close_delisted_position(p0: address, p1: object::Object<perp_market::PerpMarket>) {
        let _t5;
        let _t4;
        let (_t8,_t9) = perp_positions::get_position_size_and_is_long(p0, p1);
        let _t2 = _t9;
        let _t3 = _t8;
        loop {
            if (!(_t3 == 0)) {
                _t4 = price_management::get_mark_price(p1);
                _t5 = accounts_collateral::validate_liquidation_position_update(p0, p1, _t4, !_t2, false, _t3);
                if (perp_positions::is_update_successful(&_t5)) break;
                abort 8
            };
            return ()
        };
        let _t30 = accounts_collateral::backstop_liquidator();
        accounts_collateral::commit_update_position_with_backstop_liquidator(_t4, !_t2, _t3, _t5, _t30);
    }
    fun get_settlement_size_and_reason(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: bool, p3: u64, p4: perp_engine_types::OrderMetadata, p5: &mut option::Option<string::String>): option::Option<u64> {
        let _t7;
        let _t6 = max_settlement_size<perp_engine_types::OrderMetadata>(p0, p1, p2, p3, p4);
        let _t15 = option::is_none<u64>(&_t6);
        loop {
            if (!_t15) {
                _t7 = option::destroy_some<u64>(_t6);
                if (_t7 != p3) {
                    *p5 = option::some<string::String>(string::utf8(vector[84u8, 97u8, 107u8, 101u8, 114u8, 32u8, 114u8, 101u8, 100u8, 117u8, 99u8, 101u8, 32u8, 111u8, 110u8, 108u8, 121u8, 32u8, 118u8, 105u8, 111u8, 108u8, 97u8, 116u8, 105u8, 111u8, 110u8]));
                    break
                };
                break
            };
            return option::none<u64>()
        };
        option::some<u64>(_t7)
    }
    friend fun max_settlement_size<T0: copy + drop + store>(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: bool, p3: u64, p4: perp_engine_types::OrderMetadata): option::Option<u64> {
        let _t6;
        let _t5;
        if (perp_engine_types::is_reduce_only(&p4)) _t5 = false else _t5 = !perp_market_config::is_reduce_only(p0, p1);
        loop {
            if (_t5) return option::some<u64>(p3) else {
                _t6 = accounts_collateral::validate_reduce_only_update(p1, p0, p2, p3);
                if (!perp_positions::is_reduce_only_violation(&_t6)) break
            };
            return option::none<u64>()
        };
        option::some<u64>(perp_positions::get_reduce_only_size(&_t6))
    }
    friend fun market_callbacks(p0: object::Object<perp_market::PerpMarket>): market_types::MarketClearinghouseCallbacks<perp_engine_types::OrderMetadata> {
        let _t2: |address, order_book_types::OrderIdType, address, order_book_types::OrderIdType, u64, bool, u64, u64, option::Option<perp_engine_types::OrderMetadata>, option::Option<perp_engine_types::OrderMetadata>|market_types::SettleTradeResult has copy + drop = |arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9| lambda__1__market_callbacks(p0, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
        let _t4: |address, order_book_types::OrderIdType, bool, bool, u64, order_book_types::TimeInForce, u64, perp_engine_types::OrderMetadata|bool has copy + drop = |arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7| lambda__2__market_callbacks(p0, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7);
        let _t6: |address, vector<u64>, vector<u64>, vector<u64>, vector<u64>|bool has copy + drop = |arg0,arg1,arg2,arg3,arg4| validate_bulk_order_placement(p0, arg0, arg1, arg2, arg3, arg4);
        let _t7: |address, order_book_types::OrderIdType, bool, u64, u64, perp_engine_types::OrderMetadata| has copy + drop = |arg0,arg1,arg2,arg3,arg4,arg5| lambda__3__market_callbacks(arg0, arg1, arg2, arg3, arg4, arg5);
        let _t8: |address, order_book_types::OrderIdType, bool, u64, perp_engine_types::OrderMetadata| has copy + drop = |arg0,arg1,arg2,arg3,arg4| lambda__4__market_callbacks(arg0, arg1, arg2, arg3, arg4);
        let _t9: |address, bool, u64| has copy + drop = |arg0,arg1,arg2| lambda__5__market_callbacks(arg0, arg1, arg2);
        let _t10: |address, order_book_types::OrderIdType, bool, u64, u64| has copy + drop = |arg0,arg1,arg2,arg3,arg4| lambda__6__market_callbacks(arg0, arg1, arg2, arg3, arg4);
        let _t11: |perp_engine_types::OrderMetadata|vector<u8> has copy + drop = |arg0| perp_engine_types::get_order_metadata_bytes(arg0);
        market_types::new_market_clearinghouse_callbacks<perp_engine_types::OrderMetadata>(_t2, _t4, _t6, _t7, _t8, _t9, _t10, _t11)
    }
    fun lambda__1__market_callbacks(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: order_book_types::OrderIdType, p3: address, p4: order_book_types::OrderIdType, p5: u64, p6: bool, p7: u64, p8: u64, p9: option::Option<perp_engine_types::OrderMetadata>, p10: option::Option<perp_engine_types::OrderMetadata>): market_types::SettleTradeResult {
        settle_trade(p0, p1, p3, p6, p7, p8, p9, p10)
    }
    fun lambda__2__market_callbacks(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: order_book_types::OrderIdType, p3: bool, p4: bool, p5: u64, p6: order_book_types::TimeInForce, p7: u64, p8: perp_engine_types::OrderMetadata): bool {
        validate_order_placement(p0, p1, p3, p4, p5, p6, p7, p8)
    }
    fun lambda__3__market_callbacks(p0: address, p1: order_book_types::OrderIdType, p2: bool, p3: u64, p4: u64, p5: perp_engine_types::OrderMetadata) {
        ()
    }
    fun lambda__4__market_callbacks(p0: address, p1: order_book_types::OrderIdType, p2: bool, p3: u64, p4: perp_engine_types::OrderMetadata) {
        ()
    }
    fun lambda__5__market_callbacks(p0: address, p1: bool, p2: u64) {
        ()
    }
    fun lambda__6__market_callbacks(p0: address, p1: order_book_types::OrderIdType, p2: bool, p3: u64, p4: u64) {
        ()
    }
    friend fun settle_liquidation(p0: address, p1: address, p2: object::Object<perp_market::PerpMarket>, p3: bool, p4: u64, p5: u64): option::Option<u64> {
        if (!(p5 > 0)) {
            let _t71 = error::invalid_argument(1);
            abort _t71
        };
        if (!(p0 != p1)) {
            let _t69 = error::invalid_argument(13);
            abort _t69
        };
        let (_t22,_t23,_t24) = get_adjusted_size_for_open_interest_cap(p0, p1, p2, p3, p5, 18446744073709551615);
        let _t7 = _t22;
        if (!(_t7 > 0)) {
            let _t67 = error::invalid_argument(8);
            abort _t67
        };
        let _t34 = option::none<builder_code_registry::BuilderCode>();
        let _t8 = accounts_collateral::validate_position_update(p0, p2, p4, p3, true, _t7, _t34, false);
        if (!perp_positions::is_update_successful(&_t8)) {
            let _t65 = error::invalid_argument(8);
            abort _t65
        };
        let _t9 = accounts_collateral::validate_liquidation_position_update(p1, p2, p4, !p3, false, _t7);
        if (!perp_positions::is_update_successful(&_t9)) return option::none<u64>();
        accounts_collateral::commit_update_position(p4, p3, _t7, _t8);
        accounts_collateral::commit_update_position_with_backstop_liquidator(p4, !p3, _t7, _t9, p0);
        open_interest_tracker::mark_open_interest_delta_for_market(p2, _t23);
        option::some<u64>(_t7)
    }
}
