module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::fee_treasury {
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x1::signer;
    use 0x1::primary_fungible_store;
    use 0x1::error;
    use 0x1::dispatchable_fungible_asset;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::fee_distribution;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::accounts_collateral;
    struct FeeVault has store, key {
        asset_type: object::Object<fungible_asset::Metadata>,
        store: object::Object<fungible_asset::FungibleStore>,
        store_extend_ref: object::ExtendRef,
    }
    friend fun initialize(p0: &signer, p1: object::Object<fungible_asset::Metadata>) {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) {
            let _t30 = error::invalid_argument(3);
            abort _t30
        };
        let _t2 = object::create_named_object(p0, vector[102u8, 101u8, 101u8, 95u8, 118u8, 97u8, 117u8, 108u8, 116u8]);
        let _t3 = object::generate_extend_ref(&_t2);
        let _t4 = primary_fungible_store::ensure_primary_store_exists<fungible_asset::Metadata>(object::address_from_constructor_ref(&_t2), p1);
        let _t5 = object::generate_signer_for_extending(&_t3);
        fungible_asset::upgrade_store_to_concurrent<fungible_asset::FungibleStore>(&_t5, _t4);
        let _t27 = FeeVault{asset_type: p1, store: _t4, store_extend_ref: _t3};
        move_to<FeeVault>(p0, _t27);
    }
    friend fun deposit_fees(p0: fungible_asset::FungibleAsset)
        acquires FeeVault
    {
        let _t1 = borrow_global<FeeVault>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95);
        let _t5 = fungible_asset::metadata_from_asset(&p0);
        let _t8 = *&_t1.asset_type;
        if (!(_t5 == _t8)) abort 14566554180833181696;
        if (!(fungible_asset::amount(&p0) > 0)) {
            let _t20 = error::invalid_argument(1);
            abort _t20
        };
        dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(*&_t1.store, p0);
    }
    public fun get_balance(): u64
        acquires FeeVault
    {
        fungible_asset::balance<fungible_asset::FungibleStore>(*&borrow_global<FeeVault>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).store)
    }
    friend fun withdraw_fees(p0: u64): fungible_asset::FungibleAsset
        acquires FeeVault
    {
        if (!(p0 > 0)) {
            let _t18 = error::invalid_argument(1);
            abort _t18
        };
        let _t1 = borrow_global<FeeVault>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95);
        let _t2 = object::generate_signer_for_extending(&_t1.store_extend_ref);
        let _t11 = &_t2;
        let _t14 = *&_t1.store;
        dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_t11, _t14, p0)
    }
}
