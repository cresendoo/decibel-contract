module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::accounts_collateral {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::collateral_balance_sheet;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::liquidation_config;
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x1::signer;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_management;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::trading_fees_manager;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::fee_treasury;
    use 0x1::error;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions;
    use 0x1::option;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::builder_code_registry;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::math;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::i64;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::clearinghouse_perp;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::liquidation;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::async_matching_engine;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine;
    enum GlobalAccountStates has key {
        V1 {
            collateral: collateral_balance_sheet::CollateralBalanceSheet,
            liquidation_config: liquidation_config::LiquidationConfig,
        }
    }
    public fun initialize(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u8, p3: address) {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) {
            let _t26 = error::invalid_argument(4);
            abort _t26
        };
        price_management::new_price_management(p0);
        trading_fees_manager::initialize(p0);
        fee_treasury::initialize(p0, p1);
        if (exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 7;
        let _t18 = collateral_balance_sheet::initialize(p0, p1, p2);
        let _t20 = liquidation_config::new_config(p3);
        let _t21 = GlobalAccountStates::V1{collateral: _t18, liquidation_config: _t20};
        move_to<GlobalAccountStates>(p0, _t21);
    }
    friend fun deposit(p0: &signer, p1: fungible_asset::FungibleAsset)
        acquires GlobalAccountStates
    {
        let _t2 = signer::address_of(p0);
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        let _t9 = &mut borrow_global_mut<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral;
        let _t13 = collateral_balance_sheet::balance_type_cross(_t2);
        let _t14 = collateral_balance_sheet::change_type_user_movement();
        collateral_balance_sheet::deposit_collateral(_t9, _t2, p1, _t13, _t14);
    }
    friend fun backstop_liquidator(): address
        acquires GlobalAccountStates
    {
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        liquidation_config::backstop_liquidator(&borrow_global<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).liquidation_config)
    }
    entry fun update_backstop_liquidator(p0: &signer, p1: address)
        acquires GlobalAccountStates
    {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 4;
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        liquidation_config::update_backstop_liquidator(&mut borrow_global_mut<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).liquidation_config, p1);
    }
    friend fun is_allowed_settle_price(p0: object::Object<perp_market::PerpMarket>, p1: u64): (bool, bool)
        acquires GlobalAccountStates
    {
        let _t6 = &borrow_global<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).liquidation_config;
        let (_t7,_t8) = perp_positions::is_allowed_settle_price(p0, p1, _t6);
        (_t7, _t8)
    }
    friend fun is_position_liquidatable(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: bool): bool
        acquires GlobalAccountStates
    {
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        let _t3 = &borrow_global<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral;
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        let _t16 = &borrow_global<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).liquidation_config;
        perp_positions::is_position_liquidatable(_t3, _t16, p0, p1, p2)
    }
    friend fun position_status(p0: address, p1: object::Object<perp_market::PerpMarket>): perp_positions::AccountStatusDetailed
        acquires GlobalAccountStates
    {
        let _t7 = perp_positions::position_status(&borrow_global<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral, p0, p1);
        let _t10 = &borrow_global<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).liquidation_config;
        perp_positions::add_liquidation_details(_t7, _t10)
    }
    friend fun transfer_balance_to_liquidator(p0: address, p1: address, p2: object::Object<perp_market::PerpMarket>)
        acquires GlobalAccountStates
    {
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        perp_positions::transfer_balance_to_liquidator(&mut borrow_global_mut<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral, p0, p1, p2);
    }
    friend fun validate_liquidation_position_update(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: u64, p3: bool, p4: bool, p5: u64): perp_positions::UpdatePositionResult
        acquires GlobalAccountStates
    {
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        perp_positions::validate_liquidation_position_update(&borrow_global<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral, p0, p1, p2, p3, p4, p5)
    }
    friend fun validate_position_update(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: u64, p3: bool, p4: bool, p5: u64, p6: option::Option<builder_code_registry::BuilderCode>, p7: bool): perp_positions::UpdatePositionResult
        acquires GlobalAccountStates
    {
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        let _t8 = &borrow_global<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral;
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        let _t26 = &borrow_global<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).liquidation_config;
        perp_positions::validate_position_update(_t8, _t26, p0, p1, p2, p3, p4, p5, p6, p7)
    }
    friend fun validate_reduce_only_update(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: bool, p3: u64): perp_positions::ReduceOnlyValidationResult {
        perp_positions::validate_reduce_only_update(p0, p1, p2, p3)
    }
    public fun collateral_asset_metadata(): object::Object<fungible_asset::Metadata>
        acquires GlobalAccountStates
    {
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        collateral_balance_sheet::asset_metadata(&borrow_global<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral)
    }
    public fun collateral_balance_precision(): math::Precision
        acquires GlobalAccountStates
    {
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        collateral_balance_sheet::balance_precision(&borrow_global<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral)
    }
    friend fun commit_update_position(p0: u64, p1: bool, p2: u64, p3: perp_positions::UpdatePositionResult)
        acquires GlobalAccountStates
    {
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        let _t4 = liquidation_config::backstop_liquidator(&borrow_global<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).liquidation_config);
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        perp_positions::commit_update(&mut borrow_global_mut<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral, p0, p1, p2, p3, _t4);
    }
    friend fun commit_update_position_with_backstop_liquidator(p0: u64, p1: bool, p2: u64, p3: perp_positions::UpdatePositionResult, p4: address)
        acquires GlobalAccountStates
    {
        let (_t8,_t9) = perp_positions::extract_backstop_liquidator_covered_loss(p3);
        let _t5 = _t9;
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        let _t6 = borrow_global_mut<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95);
        if (_t5 > 0) {
            if (!collateral_balance_sheet::balance_at_least(&_t6.collateral, p4, _t5)) abort 5;
            let _t23 = &mut _t6.collateral;
            let _t27 = collateral_balance_sheet::balance_type_cross(p4);
            let _t28 = collateral_balance_sheet::change_type_liquidation();
            collateral_balance_sheet::decrease_balance(_t23, p4, _t5, _t27, _t28)
        };
        perp_positions::commit_update(&mut _t6.collateral, p0, p1, p2, _t8, p4);
    }
    friend fun deposit_to_isolated_position_margin(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: fungible_asset::FungibleAsset)
        acquires GlobalAccountStates
    {
        let _t3 = signer::address_of(p0);
        let _t4 = perp_positions::isolated_position_address(_t3, p1);
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        let _t14 = &mut borrow_global_mut<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral;
        let _t19 = collateral_balance_sheet::balance_type_isolated(_t3, p1);
        let _t20 = collateral_balance_sheet::change_type_user_movement();
        collateral_balance_sheet::deposit_collateral(_t14, _t4, p2, _t19, _t20);
    }
    public fun get_account_balance(p0: address): u64
        acquires GlobalAccountStates
    {
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        collateral_balance_sheet::balance_of(&borrow_global<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral, p0)
    }
    public fun get_account_balance_fungible(p0: address): u64
        acquires GlobalAccountStates
    {
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        let _t1 = &borrow_global<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral;
        let _t10 = collateral_balance_sheet::balance_of(_t1, p0);
        collateral_balance_sheet::convert_balance_to_fungible_amount(_t1, _t10, false)
    }
    public fun get_isolated_position_margin(p0: address, p1: object::Object<perp_market::PerpMarket>): u64
        acquires GlobalAccountStates
    {
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        let _t6 = &borrow_global<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral;
        let _t9 = perp_positions::isolated_position_address(p0, p1);
        collateral_balance_sheet::balance_of(_t6, _t9)
    }
    friend fun transfer_margin_fungible_to_isolated_position(p0: address, p1: object::Object<perp_market::PerpMarket>, p2: bool, p3: u64)
        acquires GlobalAccountStates
    {
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        let _t4 = &mut borrow_global_mut<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral;
        let _t5 = collateral_balance_sheet::convert_fungible_to_balance_to_amount(freeze(_t4), p3);
        perp_positions::transfer_margin_to_isolated_position(_t4, p0, p1, p2, _t5);
    }
    friend fun withdraw_fungible(p0: &signer, p1: u64): fungible_asset::FungibleAsset
        acquires GlobalAccountStates
    {
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        let _t2 = &mut borrow_global_mut<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral;
        let _t3 = signer::address_of(p0);
        let _t4 = collateral_balance_sheet::convert_fungible_to_balance_to_amount(freeze(_t2), p1);
        let _t17 = freeze(_t2);
        let _t19 = i64::zero();
        if (!perp_positions::is_max_allowed_withdraw_from_cross_margin_at_least(_t17, _t3, _t19, _t4)) abort 6;
        if (collateral_balance_sheet::balance_of(freeze(_t2), _t3) < _t4) perp_positions::update_crossed_position_pnl(_t2, _t3);
        let _t34 = collateral_balance_sheet::balance_type_cross(_t3);
        let _t35 = collateral_balance_sheet::change_type_user_movement();
        collateral_balance_sheet::withdraw_collateral(_t2, p0, _t4, _t34, _t35)
    }
    friend fun withdraw_fungible_from_isolated_position_margin(p0: &signer, p1: object::Object<perp_market::PerpMarket>, p2: u64): fungible_asset::FungibleAsset
        acquires GlobalAccountStates
    {
        let _t3 = signer::address_of(p0);
        let _t4 = perp_positions::isolated_position_address(_t3, p1);
        if (!exists<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 8;
        let _t5 = &mut borrow_global_mut<GlobalAccountStates>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).collateral;
        let _t6 = collateral_balance_sheet::convert_fungible_to_balance_to_amount(freeze(_t5), p2);
        if (!(perp_positions::max_allowed_withdraw_from_isolated_margin(freeze(_t5), _t4) >= _t6)) abort 6;
        if (collateral_balance_sheet::balance_of(freeze(_t5), _t4) < _t6) perp_positions::update_isolated_position_pnl(_t5, _t4, _t3);
        let _t42 = collateral_balance_sheet::balance_type_isolated(_t3, p1);
        let _t43 = collateral_balance_sheet::change_type_user_movement();
        collateral_balance_sheet::withdraw_collateral_unchecked(_t5, _t4, _t6, false, _t42, _t43)
    }
}
