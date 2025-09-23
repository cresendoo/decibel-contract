module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::liquidation {
    use 0x1::object;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::accounts_collateral;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions;
    use 0x1::vector;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_management;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::clearinghouse_perp;
    use 0x1::option;
    use 0x1::event;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::adl_tracker;
    use 0x1::string;
    use 0x1::debug;
    use 0x7::order_book_types;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine_types;
    use 0x7::market;
    use 0x7::market_types;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::async_matching_engine;
    struct LiquidationEvent has copy, drop, store {
        market: object::Object<perp_market::PerpMarket>,
        is_isolated: bool,
        user: address,
        type: LiquidationType,
    }
    enum LiquidationType has copy, drop, store {
        MarginCall,
        BackstopLiquidation,
    }
    struct MarginCallResult has drop {
        need_backstop_liquidation: bool,
        fill_limit_exhausted: bool,
    }
    fun backstop_liquidation(p0: address, p1: object::Object<perp_market::PerpMarket>) {
        let _t2 = accounts_collateral::backstop_liquidator();
        if (!perp_positions::account_initialized(_t2)) abort 3;
        let _t3 = perp_positions::is_position_isolated(p0, p1);
        let _t4 = perp_positions::positions_to_liquidate(p0, p1);
        vector::reverse<perp_positions::PerpPosition>(&mut _t4);
        let _t5 = _t4;
        let _t6 = vector::length<perp_positions::PerpPosition>(&_t5);
        'l0: loop {
            'l1: loop {
                loop {
                    if (!(_t6 > 0)) break 'l0;
                    let _t7 = vector::pop_back<perp_positions::PerpPosition>(&mut _t5);
                    let _t8 = perp_positions::get_size(&_t7);
                    if (_t8 != 0) {
                        let _t9 = perp_positions::is_long(&_t7);
                        let _t10 = perp_positions::get_market(&_t7);
                        let _t44 = price_management::get_mark_price(_t10);
                        let _t11 = clearinghouse_perp::settle_liquidation(_t2, p0, _t10, _t9, _t44, _t8);
                        if (!option::is_some<u64>(&_t11)) break 'l1;
                        if (!(option::destroy_some<u64>(_t11) == _t8)) break;
                        let _t56 = LiquidationType::BackstopLiquidation{};
                        event::emit<LiquidationEvent>(LiquidationEvent{market: _t10, is_isolated: _t3, user: p0, type: _t56})
                    };
                    _t6 = _t6 - 1;
                    continue
                };
                abort 4
            };
            abort 4
        };
        vector::destroy_empty<perp_positions::PerpPosition>(_t5);
        accounts_collateral::transfer_balance_to_liquidator(_t2, p0, p1);
    }
    public fun backstop_liquidator_adl(p0: object::Object<perp_market::PerpMarket>, p1: u64) {
        let _t2 = accounts_collateral::backstop_liquidator();
        let _t3 = perp_positions::get_position_is_long(_t2, p0);
        if (!(perp_positions::get_position_size(_t2, p0) >= p1)) abort 6;
        let _t4 = 0u32;
        'l0: loop {
            'l1: loop {
                loop {
                    let _t7;
                    if (!(_t4 < 10u32)) break 'l0;
                    p1 = perp_positions::get_position_size(_t2, p0);
                    let _t5 = adl_tracker::get_next_adl_address(p0, !_t3);
                    let _t6 = perp_positions::get_position_size(_t5, p0);
                    if (p1 > _t6) _t7 = _t6 else _t7 = p1;
                    let _t41 = price_management::get_mark_price(p0);
                    let _t8 = clearinghouse_perp::settle_liquidation(_t5, _t2, p0, _t3, _t41, _t7);
                    if (!option::is_some<u64>(&_t8)) break 'l1;
                    if (!(option::destroy_some<u64>(_t8) == _t7)) break;
                    let _t53 = LiquidationType::BackstopLiquidation{};
                    event::emit<LiquidationEvent>(LiquidationEvent{market: p0, is_isolated: false, user: _t5, type: _t53});
                    _t4 = _t4 + 1u32;
                    if (!(_t6 >= p1)) continue;
                    break 'l0
                };
                abort 5
            };
            abort 5
        };
    }
    public fun get_ebackstop_liquidator_not_initialized(): u64 {
        3
    }
    public fun get_ecannot_liquidate_backstop_liquidator(): u64 {
        2
    }
    public fun get_ecannot_settle_backstop_liquidation(): u64 {
        4
    }
    public fun get_ecannot_settle_backstop_liquidation_adl(): u64 {
        5
    }
    public fun get_einvalid_adl_liquidation_size(): u64 {
        6
    }
    public fun get_enot_liquidatable(): u64 {
        1
    }
    friend fun liquidate_position_internal(p0: object::Object<perp_market::PerpMarket>, p1: address, p2: &mut u32): bool {
        let _t3 = accounts_collateral::position_status(p1, p0);
        let _t11 = &_t3;
        let _t4 = margin_call(p1, p0, _t11, p2);
        let _t5 = string::utf8(vector[109u8, 97u8, 114u8, 103u8, 105u8, 110u8, 95u8, 99u8, 97u8, 108u8, 108u8, 32u8, 114u8, 101u8, 115u8, 117u8, 108u8, 116u8]);
        debug::print<string::String>(&_t5);
        debug::print<MarginCallResult>(&_t4);
        let _t20 = *&(&_t4).fill_limit_exhausted;
        loop {
            if (!_t20) {
                if (!*&(&_t4).need_backstop_liquidation) break;
                backstop_liquidation(p1, p0);
                break
            };
            return true
        };
        false
    }
    fun margin_call(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: &perp_positions::AccountStatusDetailed, p3: &mut u32): MarginCallResult {
        let _t10;
        let _t6;
        let _t5;
        let _t19 = perp_positions::is_account_liquidatable_detailed(p2, false);
        'l1: loop {
            'l0: loop {
                loop {
                    if (_t19) {
                        let _t4 = perp_positions::is_position_isolated(p0, p1);
                        if (perp_positions::is_account_liquidatable_detailed(p2, true)) break;
                        _t5 = perp_positions::positions_to_liquidate(p0, p1);
                        _t6 = 0;
                        loop {
                            let _t7;
                            let _t42 = vector::length<perp_positions::PerpPosition>(&_t5);
                            if (_t6 < _t42) _t7 = *p3 > 0u32 else _t7 = false;
                            if (!_t7) break;
                            let _t8 = *vector::borrow<perp_positions::PerpPosition>(&_t5, _t6);
                            let _t9 = perp_positions::get_size(&_t8);
                            if (_t9 != 0) {
                                _t10 = perp_positions::is_long(&_t8);
                                let _t11 = perp_positions::get_market(&_t8);
                                let _t12 = perp_positions::liquidation_price(&_t8, p2);
                                let _t13 = perp_market::next_order_id(_t11);
                                let _t74 = order_book_types::immediate_or_cancel();
                                let _t75 = option::none<order_book_types::TriggerCondition>();
                                let _t76 = perp_engine_types::new_liquidation_metadata();
                                let _t78 = option::none<u64>();
                                let (_t82,_t83,_t84,_t85,_t86) = market::destroy_order_match_result(place_order_and_update_work_unit(_t11, p0, _t12, _t9, _t9, !_t10, _t74, _t75, _t76, _t13, _t78, true, p3));
                                let _t14 = _t85;
                                let _t15 = _t84;
                                if (vector::length<u64>(&_t14) > 0) {
                                    let _t94 = LiquidationType::MarginCall{};
                                    event::emit<LiquidationEvent>(LiquidationEvent{market: _t11, is_isolated: _t4, user: p0, type: _t94})
                                };
                                if (option::is_some<market::OrderCancellationReason>(&_t15)) _t10 = market::is_fill_limit_violation(option::destroy_some<market::OrderCancellationReason>(_t15)) else _t10 = false;
                                if (_t10) break 'l0
                            };
                            _t6 = _t6 + 1;
                            continue
                        };
                        let _t115 = vector::length<perp_positions::PerpPosition>(&_t5);
                        if (_t6 < _t115) {
                            _t10 = false;
                            break 'l1
                        };
                        _t10 = accounts_collateral::is_position_liquidatable(p0, p1, false);
                        break 'l1
                    };
                    return MarginCallResult{need_backstop_liquidation: false, fill_limit_exhausted: false}
                };
                return MarginCallResult{need_backstop_liquidation: true, fill_limit_exhausted: false}
            };
            return MarginCallResult{need_backstop_liquidation: false, fill_limit_exhausted: true}
        };
        let _t120 = vector::length<perp_positions::PerpPosition>(&_t5);
        MarginCallResult{need_backstop_liquidation: _t10, fill_limit_exhausted: _t6 < _t120}
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
}
