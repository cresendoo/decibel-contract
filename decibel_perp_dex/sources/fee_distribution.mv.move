module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::fee_distribution {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::i64;
    use 0x1::option;
    use 0x1::error;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::collateral_balance_sheet;
    use 0x1::fungible_asset;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::fee_treasury;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::trading_fees_manager;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions;
    enum FeeDistribution has copy, drop, store {
        V1 {
            position_address: address,
            position_fee_delta: i64::I64,
            treasury_fee_delta: i64::I64,
            backstop_vault_fees: u64,
            builder_or_referrer_fees: option::Option<FeeWithDestination>,
        }
    }
    struct FeeWithDestination has copy, drop, store {
        address: address,
        fees: u64,
    }
    friend fun add(p0: &FeeDistribution, p1: FeeDistribution): FeeDistribution {
        let _t6;
        let _t9 = *&p0.position_address;
        let _t12 = *&(&p1).position_address;
        if (!(_t9 == _t12)) {
            let _t96 = error::invalid_argument(3);
            abort _t96
        };
        let _t16 = option::is_none<FeeWithDestination>(&p0.builder_or_referrer_fees);
        let _t19 = option::is_none<FeeWithDestination>(&(&p1).builder_or_referrer_fees);
        if (!(_t16 == _t19)) {
            let _t93 = error::invalid_argument(4);
            abort _t93
        };
        if (option::is_some<FeeWithDestination>(&p0.builder_or_referrer_fees)) {
            let _t28 = *&option::borrow<FeeWithDestination>(&p0.builder_or_referrer_fees).address;
            let _t33 = *&option::borrow<FeeWithDestination>(&(&p1).builder_or_referrer_fees).address;
            if (!(_t28 == _t33)) {
                let _t90 = error::invalid_argument(3);
                abort _t90
            }
        };
        let _t2 = *&p0.position_address;
        let _t40 = *&p0.position_fee_delta;
        let _t43 = *&(&p1).position_fee_delta;
        let _t3 = i64::add(_t40, _t43);
        let _t47 = *&p0.treasury_fee_delta;
        let _t50 = *&(&p1).treasury_fee_delta;
        let _t4 = i64::add(_t47, _t50);
        let _t54 = *&p0.backstop_vault_fees;
        let _t57 = *&(&p1).backstop_vault_fees;
        let _t5 = _t54 + _t57;
        if (option::is_some<FeeWithDestination>(&p0.builder_or_referrer_fees)) {
            let _t66 = *&option::borrow<FeeWithDestination>(&p0.builder_or_referrer_fees).address;
            let _t71 = *&option::borrow<FeeWithDestination>(&p0.builder_or_referrer_fees).fees;
            let _t76 = *&option::borrow<FeeWithDestination>(&(&p1).builder_or_referrer_fees).fees;
            let _t77 = _t71 + _t76;
            _t6 = option::some<FeeWithDestination>(FeeWithDestination{address: _t66, fees: _t77})
        } else _t6 = option::none<FeeWithDestination>();
        FeeDistribution::V1{position_address: _t2, position_fee_delta: _t3, treasury_fee_delta: _t4, backstop_vault_fees: _t5, builder_or_referrer_fees: _t6}
    }
    friend fun distribute_fees(p0: &FeeDistribution, p1: &mut collateral_balance_sheet::CollateralBalanceSheet, p2: collateral_balance_sheet::CollateralBalanceType, p3: address) {
        let _t18 = i64::is_zero(&p0.position_fee_delta);
        'l0: loop {
            loop {
                if (!_t18) {
                    let _t5;
                    let _t14;
                    let _t13;
                    let _t12;
                    let _t10;
                    let _t9;
                    let (_t24,_t25) = i64::into_inner(*&p0.position_fee_delta);
                    if (_t24) {
                        _t5 = p1;
                        let _t29 = *&p0.position_address;
                        let _t6 = collateral_balance_sheet::change_type_fee();
                        _t9 = _t25;
                        _t10 = _t29;
                        let _t11 = collateral_balance_sheet::withdraw_collateral_unchecked(_t5, _t10, _t9, true, p2, _t6);
                        let (_t44,_t45) = i64::into_inner(*&p0.treasury_fee_delta);
                        _t9 = _t45;
                        if (_t44) {
                            _t9 = collateral_balance_sheet::convert_balance_to_fungible_amount(freeze(p1), _t9, true);
                            if (_t9 > 0) {
                                _t12 = fee_treasury::withdraw_fees(_t9);
                                fungible_asset::merge(&mut _t11, _t12)
                            }
                        };
                        _t14 = p0;
                        _t5 = p1;
                        _t13 = &mut _t11;
                        _t10 = p3;
                        if (*&_t14.backstop_vault_fees > 0) {
                            let _t68 = freeze(_t5);
                            let _t71 = *&_t14.backstop_vault_fees;
                            _t9 = collateral_balance_sheet::convert_balance_to_fungible_amount(_t68, _t71, false);
                            _t12 = fungible_asset::extract(_t13, _t9);
                            let _t81 = collateral_balance_sheet::balance_type_cross(_t10);
                            distribute_fees_to_address(_t5, _t12, _t10, _t81)
                        };
                        if (option::is_some<FeeWithDestination>(&_t14.builder_or_referrer_fees)) {
                            let FeeWithDestination{address: _t89, fees: _t90} = option::destroy_some<FeeWithDestination>(*&_t14.builder_or_referrer_fees);
                            _t9 = _t90;
                            _t10 = _t89;
                            _t9 = collateral_balance_sheet::convert_balance_to_fungible_amount(freeze(_t5), _t9, false);
                            _t12 = fungible_asset::extract(_t13, _t9);
                            let _t103 = collateral_balance_sheet::balance_type_cross(_t10);
                            distribute_fees_to_address(_t5, _t12, _t10, _t103)
                        };
                        if (fungible_asset::amount(&_t11) > 0) {
                            fee_treasury::deposit_fees(_t11);
                            break
                        };
                        fungible_asset::destroy_zero(_t11);
                        break
                    };
                    let (_t116,_t117) = i64::into_inner(*&p0.treasury_fee_delta);
                    if (!_t116) {
                        let _t189 = error::invalid_argument(1);
                        abort _t189
                    };
                    _t9 = collateral_balance_sheet::convert_balance_to_fungible_amount(freeze(p1), _t117, false);
                    if (_t9 == 0) break 'l0;
                    let _t15 = fee_treasury::withdraw_fees(_t9);
                    _t14 = p0;
                    _t5 = p1;
                    _t13 = &mut _t15;
                    _t10 = p3;
                    if (*&_t14.backstop_vault_fees > 0) {
                        let _t140 = freeze(_t5);
                        let _t143 = *&_t14.backstop_vault_fees;
                        _t9 = collateral_balance_sheet::convert_balance_to_fungible_amount(_t140, _t143, false);
                        _t12 = fungible_asset::extract(_t13, _t9);
                        let _t153 = collateral_balance_sheet::balance_type_cross(_t10);
                        distribute_fees_to_address(_t5, _t12, _t10, _t153)
                    };
                    if (option::is_some<FeeWithDestination>(&_t14.builder_or_referrer_fees)) {
                        let FeeWithDestination{address: _t161, fees: _t162} = option::destroy_some<FeeWithDestination>(*&_t14.builder_or_referrer_fees);
                        _t9 = _t162;
                        _t10 = _t161;
                        _t9 = collateral_balance_sheet::convert_balance_to_fungible_amount(freeze(_t5), _t9, false);
                        _t12 = fungible_asset::extract(_t13, _t9);
                        let _t175 = collateral_balance_sheet::balance_type_cross(_t10);
                        distribute_fees_to_address(_t5, _t12, _t10, _t175)
                    };
                    let _t179 = *&p0.position_address;
                    let _t182 = collateral_balance_sheet::change_type_fee();
                    collateral_balance_sheet::deposit_collateral(p1, _t179, _t15, p2, _t182);
                    break
                };
                return ()
            };
            return ()
        };
    }
    fun distribute_fees_to_address(p0: &mut collateral_balance_sheet::CollateralBalanceSheet, p1: fungible_asset::FungibleAsset, p2: address, p3: collateral_balance_sheet::CollateralBalanceType) {
        let _t8 = collateral_balance_sheet::change_type_fee();
        collateral_balance_sheet::deposit_collateral(p0, p2, p1, p3, _t8);
    }
    friend fun get_backstop_vault_fees(p0: &FeeDistribution): u64 {
        *&p0.backstop_vault_fees
    }
    friend fun get_builder_or_referrer_fees(p0: &FeeDistribution): option::Option<FeeWithDestination> {
        *&p0.builder_or_referrer_fees
    }
    friend fun get_position_address(p0: &FeeDistribution): address {
        *&p0.position_address
    }
    friend fun get_position_fee_delta(p0: &FeeDistribution): i64::I64 {
        *&p0.position_fee_delta
    }
    friend fun get_system_fee_delta(p0: &FeeDistribution): i64::I64 {
        let _t3 = *&p0.treasury_fee_delta;
        let _t7 = i64::new_negative(*&p0.backstop_vault_fees);
        i64::add(_t3, _t7)
    }
    friend fun new_fee_distribution(p0: address, p1: i64::I64, p2: u64, p3: option::Option<FeeWithDestination>): FeeDistribution {
        let _t4 = p2;
        if (option::is_some<FeeWithDestination>(&p3)) {
            let _t5 = option::destroy_some<FeeWithDestination>(p3);
            let _t6 = *&(&_t5).fees;
            _t4 = _t4 + _t6
        };
        let _t7 = i64::negative(&p1);
        let _t21 = &mut _t7;
        let _t23 = i64::new_positive(_t4);
        i64::add_inplace(_t21, _t23);
        FeeDistribution::V1{position_address: p0, position_fee_delta: p1, treasury_fee_delta: _t7, backstop_vault_fees: p2, builder_or_referrer_fees: p3}
    }
    friend fun new_fee_with_destination(p0: address, p1: u64): FeeWithDestination {
        FeeWithDestination{address: p0, fees: p1}
    }
    friend fun zero_fees(p0: address): FeeDistribution {
        let _t2 = i64::zero();
        let _t3 = i64::zero();
        let _t5 = option::none<FeeWithDestination>();
        FeeDistribution::V1{position_address: p0, position_fee_delta: _t2, treasury_fee_delta: _t3, backstop_vault_fees: 0, builder_or_referrer_fees: _t5}
    }
}
