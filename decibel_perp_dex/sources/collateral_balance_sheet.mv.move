module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::collateral_balance_sheet {
    use 0x1::aggregator_v2;
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::math;
    use 0x1::table;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market;
    use 0x1::primary_fungible_store;
    use 0x1::event;
    use 0x1::dispatchable_fungible_asset;
    use 0x1::signer;
    use 0x1::error;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::fee_distribution;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::accounts_collateral;
    struct CollateralBalanceChangeEvent has drop, store {
        balance_type: CollateralBalanceType,
        delta: u64,
        is_delta_positive: bool,
        balance_after: aggregator_v2::AggregatorSnapshot<u64>,
        change_type: CollateralBalanceChangeType,
    }
    enum CollateralBalanceType has copy, drop, store {
        Cross {
            account: address,
        }
        Isolated {
            account: address,
            market: object::Object<perp_market::PerpMarket>,
        }
        TestOnly,
    }
    enum CollateralBalanceChangeType has copy, drop, store {
        UserMovement,
        Fee,
        PnL,
        Margin,
        Liquidation,
        TestOnly,
    }
    struct CollateralBalanceSheet has store, key {
        asset_type: object::Object<fungible_asset::Metadata>,
        asset_precision: math::Precision,
        store: object::Object<fungible_asset::FungibleStore>,
        store_extend_ref: object::ExtendRef,
        balance_table: table::Table<address, aggregator_v2::Aggregator<u64>>,
        balance_precision: math::Precision,
    }
    friend fun balance_precision(p0: &CollateralBalanceSheet): math::Precision {
        *&p0.balance_precision
    }
    friend fun initialize(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u8): CollateralBalanceSheet {
        let _t3 = object::create_named_object(p0, vector[99u8, 111u8, 108u8, 108u8, 97u8, 116u8, 101u8, 114u8, 97u8, 108u8, 95u8, 98u8, 97u8, 108u8, 97u8, 110u8, 99u8, 101u8, 95u8, 115u8, 104u8, 101u8, 101u8, 116u8]);
        let _t4 = object::generate_extend_ref(&_t3);
        let _t5 = primary_fungible_store::ensure_primary_store_exists<fungible_asset::Metadata>(object::address_from_constructor_ref(&_t3), p1);
        let _t6 = object::generate_signer_for_extending(&_t4);
        fungible_asset::upgrade_store_to_concurrent<fungible_asset::FungibleStore>(&_t6, _t5);
        let _t7 = table::new<address,aggregator_v2::Aggregator<u64>>();
        let _t25 = math::new_precision(fungible_asset::decimals<fungible_asset::Metadata>(p1));
        let _t30 = math::new_precision(p2);
        CollateralBalanceSheet{asset_type: p1, asset_precision: _t25, store: _t5, store_extend_ref: _t4, balance_table: _t7, balance_precision: _t30}
    }
    friend fun asset_metadata(p0: &CollateralBalanceSheet): object::Object<fungible_asset::Metadata> {
        *&p0.asset_type
    }
    friend fun balance_at_least(p0: &CollateralBalanceSheet, p1: address, p2: u64): bool {
        let _t3;
        if (table::contains<address,aggregator_v2::Aggregator<u64>>(&p0.balance_table, p1)) _t3 = aggregator_v2::is_at_least<u64>(table::borrow<address,aggregator_v2::Aggregator<u64>>(&p0.balance_table, p1), p2) else _t3 = false;
        _t3
    }
    friend fun balance_of(p0: &CollateralBalanceSheet, p1: address): u64 {
        let _t2;
        if (table::contains<address,aggregator_v2::Aggregator<u64>>(&p0.balance_table, p1)) _t2 = aggregator_v2::read<u64>(table::borrow<address,aggregator_v2::Aggregator<u64>>(&p0.balance_table, p1)) else _t2 = 0;
        _t2
    }
    friend fun balance_type_cross(p0: address): CollateralBalanceType {
        CollateralBalanceType::Cross{account: p0}
    }
    friend fun balance_type_isolated(p0: address, p1: object::Object<perp_market::PerpMarket>): CollateralBalanceType {
        CollateralBalanceType::Isolated{account: p0, market: p1}
    }
    friend fun change_type_fee(): CollateralBalanceChangeType {
        CollateralBalanceChangeType::Fee{}
    }
    friend fun change_type_liquidation(): CollateralBalanceChangeType {
        CollateralBalanceChangeType::Liquidation{}
    }
    friend fun change_type_margin(): CollateralBalanceChangeType {
        CollateralBalanceChangeType::Margin{}
    }
    friend fun change_type_pnl(): CollateralBalanceChangeType {
        CollateralBalanceChangeType::PnL{}
    }
    friend fun change_type_user_movement(): CollateralBalanceChangeType {
        CollateralBalanceChangeType::UserMovement{}
    }
    friend fun convert_balance_to_fungible_amount(p0: &CollateralBalanceSheet, p1: u64, p2: bool): u64 {
        let _t5 = &p0.balance_precision;
        let _t7 = &p0.asset_precision;
        math::convert_decimals(p1, _t5, _t7, p2)
    }
    friend fun convert_fungible_to_balance_to_amount(p0: &CollateralBalanceSheet, p1: u64): u64 {
        let _t4 = &p0.asset_precision;
        let _t6 = &p0.balance_precision;
        math::convert_decimals(p1, _t4, _t6, false)
    }
    friend fun decrease_balance(p0: &mut CollateralBalanceSheet, p1: address, p2: u64, p3: CollateralBalanceType, p4: CollateralBalanceChangeType) {
        let _t5;
        loop {
            if (!(p2 == 0)) {
                _t5 = table::borrow_mut<address,aggregator_v2::Aggregator<u64>>(&mut p0.balance_table, p1);
                if (aggregator_v2::try_sub<u64>(_t5, p2)) break;
                abort 4
            };
            return ()
        };
        let _t22 = aggregator_v2::snapshot<u64>(freeze(_t5));
        event::emit<CollateralBalanceChangeEvent>(CollateralBalanceChangeEvent{balance_type: p3, delta: p2, is_delta_positive: false, balance_after: _t22, change_type: p4});
    }
    friend fun deposit_collateral(p0: &mut CollateralBalanceSheet, p1: address, p2: fungible_asset::FungibleAsset, p3: CollateralBalanceType, p4: CollateralBalanceChangeType) {
        let _t8 = fungible_asset::metadata_from_asset(&p2);
        let _t11 = *&p0.asset_type;
        if (!(_t8 == _t11)) abort 14566554180833181696;
        let _t14 = freeze(p0);
        let _t15 = &p2;
        let _t5 = fungible_asset_to_balance_amount(_t14, _t15);
        let _t18 = &mut p0.balance_table;
        let _t20 = aggregator_v2::create_unbounded_aggregator<u64>();
        let _t6 = table::borrow_mut_with_default<address,aggregator_v2::Aggregator<u64>>(_t18, p1, _t20);
        aggregator_v2::add<u64>(_t6, _t5);
        let _t29 = aggregator_v2::snapshot<u64>(freeze(_t6));
        event::emit<CollateralBalanceChangeEvent>(CollateralBalanceChangeEvent{balance_type: p3, delta: _t5, is_delta_positive: true, balance_after: _t29, change_type: p4});
        dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(*&p0.store, p2);
    }
    fun fungible_asset_to_balance_amount(p0: &CollateralBalanceSheet, p1: &fungible_asset::FungibleAsset): u64 {
        let _t2 = fungible_asset::amount(p1);
        convert_fungible_to_balance_to_amount(p0, _t2)
    }
    friend fun deposit_to_user(p0: &mut CollateralBalanceSheet, p1: address, p2: u64, p3: CollateralBalanceType, p4: CollateralBalanceChangeType) {
        if (p2 == 0) return ();
        let _t11 = &mut p0.balance_table;
        let _t13 = aggregator_v2::create_unbounded_aggregator<u64>();
        let _t5 = table::borrow_mut_with_default<address,aggregator_v2::Aggregator<u64>>(_t11, p1, _t13);
        aggregator_v2::add<u64>(_t5, p2);
        let _t22 = aggregator_v2::snapshot<u64>(freeze(_t5));
        event::emit<CollateralBalanceChangeEvent>(CollateralBalanceChangeEvent{balance_type: p3, delta: p2, is_delta_positive: true, balance_after: _t22, change_type: p4});
    }
    friend fun transfer_position(p0: &mut CollateralBalanceSheet, p1: address, p2: address, p3: u64, p4: CollateralBalanceType, p5: CollateralBalanceChangeType, p6: CollateralBalanceType, p7: CollateralBalanceChangeType) {
        let _t8;
        loop {
            if (!(p3 == 0)) {
                _t8 = table::borrow_mut<address,aggregator_v2::Aggregator<u64>>(&mut p0.balance_table, p1);
                if (aggregator_v2::try_sub<u64>(_t8, p3)) break;
                abort 3
            };
            return ()
        };
        let _t9 = aggregator_v2::snapshot<u64>(freeze(_t8));
        let _t26 = &mut p0.balance_table;
        let _t28 = aggregator_v2::create_unbounded_aggregator<u64>();
        let _t10 = table::borrow_mut_with_default<address,aggregator_v2::Aggregator<u64>>(_t26, p2, _t28);
        aggregator_v2::add<u64>(_t10, p3);
        event::emit<CollateralBalanceChangeEvent>(CollateralBalanceChangeEvent{balance_type: p6, delta: p3, is_delta_positive: false, balance_after: _t9, change_type: p7});
        let _t43 = aggregator_v2::snapshot<u64>(freeze(_t10));
        event::emit<CollateralBalanceChangeEvent>(CollateralBalanceChangeEvent{balance_type: p4, delta: p3, is_delta_positive: true, balance_after: _t43, change_type: p5});
    }
    friend fun withdraw_collateral(p0: &mut CollateralBalanceSheet, p1: &signer, p2: u64, p3: CollateralBalanceType, p4: CollateralBalanceChangeType): fungible_asset::FungibleAsset {
        let _t7 = signer::address_of(p1);
        withdraw_collateral_unchecked(p0, _t7, p2, false, p3, p4)
    }
    friend fun withdraw_collateral_unchecked(p0: &mut CollateralBalanceSheet, p1: address, p2: u64, p3: bool, p4: CollateralBalanceType, p5: CollateralBalanceChangeType): fungible_asset::FungibleAsset {
        if (!(p2 > 0)) {
            let _t45 = error::invalid_argument(2);
            abort _t45
        };
        let _t6 = table::borrow_mut<address,aggregator_v2::Aggregator<u64>>(&mut p0.balance_table, p1);
        if (!aggregator_v2::try_sub<u64>(_t6, p2)) {
            let _t42 = error::invalid_argument(1);
            abort _t42
        };
        let _t23 = aggregator_v2::snapshot<u64>(freeze(_t6));
        event::emit<CollateralBalanceChangeEvent>(CollateralBalanceChangeEvent{balance_type: p4, delta: p2, is_delta_positive: false, balance_after: _t23, change_type: p5});
        let _t7 = object::generate_signer_for_extending(&p0.store_extend_ref);
        let _t29 = &_t7;
        let _t32 = *&p0.store;
        let _t37 = convert_balance_to_fungible_amount(freeze(p0), p2, p3);
        dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_t29, _t32, _t37)
    }
}
