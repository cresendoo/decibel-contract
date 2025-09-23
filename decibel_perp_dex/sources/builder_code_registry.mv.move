module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::builder_code_registry {
    use 0x1::big_ordered_map;
    use 0x1::signer;
    use 0x1::error;
    use 0x1::option;
    use 0x1::math64;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::trading_fees_manager;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::async_matching_engine;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::dex_accounts;
    struct BuilderAndAccount has copy, drop, store {
        account: address,
        builder: address,
    }
    struct BuilderCode has copy, drop, store {
        builder: address,
        fees: u64,
    }
    struct Registry has store, key {
        global_max_fee: u64,
        approved_max_fees: big_ordered_map::BigOrderedMap<BuilderAndAccount, u64>,
    }
    friend fun initialize(p0: &signer, p1: u64) {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) {
            let _t12 = error::invalid_argument(3);
            abort _t12
        };
        let _t8 = big_ordered_map::new<BuilderAndAccount,u64>();
        let _t9 = Registry{global_max_fee: p1, approved_max_fees: _t8};
        move_to<Registry>(p0, _t9);
    }
    friend fun approve_max_fee(p0: &signer, p1: address, p2: u64)
        acquires Registry
    {
        let _t3 = borrow_global_mut<Registry>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95);
        let _t4 = BuilderAndAccount{account: signer::address_of(p0), builder: p1};
        let _t14 = *&_t3.global_max_fee;
        if (!(p2 <= _t14)) {
            let _t30 = error::invalid_argument(4);
            abort _t30
        };
        let _t17 = &_t3.approved_max_fees;
        let _t18 = &_t4;
        if (big_ordered_map::contains<BuilderAndAccount,u64>(_t17, _t18)) {
            let _t21 = &mut _t3.approved_max_fees;
            let _t22 = &_t4;
            let _t23 = big_ordered_map::remove<BuilderAndAccount,u64>(_t21, _t22);
        };
        big_ordered_map::add<BuilderAndAccount,u64>(&mut _t3.approved_max_fees, _t4, p2);
    }
    public fun get_approved_max_fee(p0: address, p1: address): u64
        acquires Registry
    {
        let _t2 = borrow_global<Registry>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95);
        let _t3 = BuilderAndAccount{account: p0, builder: p1};
        let _t11 = &_t2.approved_max_fees;
        let _t12 = &_t3;
        let _t4 = big_ordered_map::get<BuilderAndAccount,u64>(_t11, _t12);
        if (option::is_none<u64>(&_t4)) return 0;
        let _t19 = option::destroy_some<u64>(_t4);
        let _t22 = *&_t2.global_max_fee;
        math64::min(_t19, _t22)
    }
    friend fun get_builder_fee_for_notional(p0: address, p1: BuilderCode, p2: u128): u64
        acquires Registry
    {
        let _t7 = *&(&p1).builder;
        let _t3 = get_approved_max_fee(p0, _t7);
        if (_t3 == 0) return 0;
        let _t16 = *&(&p1).fees;
        let _t20 = math64::min(_t3, _t16) as u128;
        (p2 * _t20 / 1000000u128) as u64
    }
    friend fun get_builder_from_builder_code(p0: &BuilderCode): address {
        *&p0.builder
    }
    friend fun get_fees_from_builder_code(p0: &BuilderCode): u64 {
        *&p0.fees
    }
    friend fun new_builder_code(p0: address, p1: u64): BuilderCode
        acquires Registry
    {
        let _t2 = borrow_global<Registry>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95);
        if (!(p1 > 0)) {
            let _t20 = error::invalid_argument(1);
            abort _t20
        };
        let _t11 = *&_t2.global_max_fee;
        if (!(p1 <= _t11)) {
            let _t17 = error::invalid_argument(4);
            abort _t17
        };
        BuilderCode{builder: p0, fees: p1}
    }
    friend fun revoke_max_fee(p0: &signer, p1: address)
        acquires Registry
    {
        let _t2 = borrow_global_mut<Registry>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95);
        let _t3 = BuilderAndAccount{account: signer::address_of(p0), builder: p1};
        let _t12 = &_t2.approved_max_fees;
        let _t13 = &_t3;
        let _t4 = big_ordered_map::get<BuilderAndAccount,u64>(_t12, _t13);
        if (option::is_none<u64>(&_t4)) {
            let _t19 = error::invalid_argument(2);
            abort _t19
        };
        let _t21 = &mut _t2.approved_max_fees;
        let _t22 = &_t3;
        let _t23 = big_ordered_map::remove<BuilderAndAccount,u64>(_t21, _t22);
    }
    friend fun validate_builder_code(p0: address, p1: &BuilderCode)
        acquires Registry
    {
        let _t2 = *&p1.fees;
        let _t10 = *&p1.builder;
        let _t3 = get_approved_max_fee(p0, _t10);
        if (!(_t3 != 0)) abort 5;
        if (!(_t2 <= _t3)) {
            let _t19 = error::invalid_argument(4);
            abort _t19
        };
    }
}
