module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::testc {
    use 0x1::fungible_asset;
    use 0x1::object;
    use 0x1::primary_fungible_store;
    use 0x1::option;
    use 0x1::string;
    struct TESTCRef has key {
        mint_ref: fungible_asset::MintRef,
        burn_ref: fungible_asset::BurnRef,
        transfer_ref: fungible_asset::TransferRef,
        metadata: object::Object<fungible_asset::Metadata>,
    }
    public fun metadata(): object::Object<fungible_asset::Metadata>
        acquires TESTCRef
    {
        *&borrow_global<TESTCRef>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).metadata
    }
    public fun burn(p0: address, p1: u64)
        acquires TESTCRef
    {
        let _t2 = borrow_global<TESTCRef>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95);
        let _t9 = *&_t2.metadata;
        let _t3 = primary_fungible_store::ensure_primary_store_exists<fungible_asset::Metadata>(p0, _t9);
        fungible_asset::burn_from<fungible_asset::FungibleStore>(&_t2.burn_ref, _t3, p1);
    }
    public fun transfer(p0: &signer, p1: address, p2: u64)
        acquires TESTCRef
    {
        let _t9 = *&borrow_global<TESTCRef>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).metadata;
        primary_fungible_store::transfer<fungible_asset::Metadata>(p0, _t9, p1, p2);
    }
    public fun balance(p0: address): u64
        acquires TESTCRef
    {
        let _t7 = *&borrow_global<TESTCRef>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).metadata;
        primary_fungible_store::balance<fungible_asset::Metadata>(p0, _t7)
    }
    public fun deposit(p0: address, p1: fungible_asset::FungibleAsset) {
        primary_fungible_store::deposit(p0, p1);
    }
    public fun mint(p0: address, p1: u64)
        acquires TESTCRef
    {
        primary_fungible_store::mint(&borrow_global<TESTCRef>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).mint_ref, p0, p1);
    }
    public fun withdraw(p0: &signer, p1: u64): fungible_asset::FungibleAsset
        acquires TESTCRef
    {
        let _t8 = *&borrow_global<TESTCRef>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).metadata;
        primary_fungible_store::withdraw<fungible_asset::Metadata>(p0, _t8, p1)
    }
    fun init_module(p0: &signer) {
        setup_testc(p0);
    }
    public fun setup_testc(p0: &signer) {
        let _t1 = object::create_named_object(p0, vector[84u8, 69u8, 83u8, 84u8, 67u8]);
        let _t9 = &_t1;
        let _t10 = option::none<u128>();
        let _t12 = string::utf8(vector[84u8, 69u8, 83u8, 84u8, 67u8]);
        let _t14 = string::utf8(vector[84u8, 69u8, 83u8, 84u8, 67u8]);
        let _t17 = string::utf8(vector[]);
        let _t19 = string::utf8(vector[]);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(_t9, _t10, _t12, _t14, 6u8, _t17, _t19);
        let _t21 = object::address_from_constructor_ref(&_t1);
        let _t23 = fungible_asset::generate_mint_ref(&_t1);
        let _t25 = fungible_asset::generate_burn_ref(&_t1);
        let _t27 = fungible_asset::generate_transfer_ref(&_t1);
        let _t29 = object::object_from_constructor_ref<fungible_asset::Metadata>(&_t1);
        let _t5 = TESTCRef{mint_ref: _t23, burn_ref: _t25, transfer_ref: _t27, metadata: _t29};
        move_to<TESTCRef>(p0, _t5);
    }
}
