module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::pyth {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price;
    use 0x1::timestamp;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::error;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_identifier;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::state;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_info;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_feed;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::event;
    use 0x1::signer;
    use 0x1::aptos_coin;
    use 0x1::coin;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::cursor;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::deserialize;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::pyth_i64;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::keccak160;
    use 0x1::vector;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::vaa;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::batch_price_attestation;
    fun abs_diff(p0: u64, p1: u64): u64 {
        if (p0 > p1) return p0 - p1;
        p1 - p0
    }
    fun check_price_is_fresh(p0: &price::Price, p1: u64) {
        let _t2 = timestamp::now_seconds();
        let _t4 = price::get_timestamp(p0);
        if (!(abs_diff(_t2, _t4) < p1)) {
            let _t8 = error::stale_price_update();
            abort _t8
        };
    }
    public fun get_price_no_older_than(p0: price_identifier::PriceIdentifier, p1: u64): price::Price {
        let _t2 = get_price_unsafe(p0);
        check_price_is_fresh(&_t2, p1);
        _t2
    }
    public fun get_price_unsafe(p0: price_identifier::PriceIdentifier): price::Price {
        let _t1 = state::get_latest_price_info(p0);
        price_feed::get_price(price_info::get_price_feed(&_t1))
    }
    fun init_internal(p0: &signer, p1: u64) {
        state::init(p0, p1);
        event::init(p0);
        if (!coin::is_account_registered<aptos_coin::AptosCoin>(signer::address_of(p0))) coin::register<aptos_coin::AptosCoin>(p0);
    }
    fun init_module(p0: &signer) {
        init_internal(p0, 60);
    }
    fun is_fresh_update(p0: &price_info::PriceInfo): bool {
        let _t1 = price_info::get_price_feed(p0);
        let _t2 = price_feed::get_price(_t1);
        let _t3 = price::get_timestamp(&_t2);
        let _t4 = price_feed::get_price_identifier(_t1);
        if (!price_feed_exists(*_t4)) return true;
        let _t5 = get_price_unsafe(*_t4);
        let _t6 = price::get_timestamp(&_t5);
        _t3 > _t6
    }
    public fun price_feed_exists(p0: price_identifier::PriceIdentifier): bool {
        state::price_info_cached(p0)
    }
    fun parse_accumulator_update_message(p0: vector<u8>): price_info::PriceInfo {
        let _t1 = cursor::init<u8>(p0);
        if (!(deserialize::deserialize_u8(&mut _t1) == 0u8)) {
            let _t53 = error::invalid_accumulator_message();
            abort _t53
        };
        let _t21 = price_identifier::from_byte_vec(deserialize::deserialize_vector(&mut _t1, 32));
        let _t23 = deserialize::deserialize_pyth_i64(&mut _t1);
        let _t25 = deserialize::deserialize_u64(&mut _t1);
        let _t2 = deserialize::deserialize_i32(&mut _t1);
        let _t3 = deserialize::deserialize_u64(&mut _t1);
        let _t31 = deserialize::deserialize_pyth_i64(&mut _t1);
        let _t33 = deserialize::deserialize_pyth_i64(&mut _t1);
        let _t35 = deserialize::deserialize_u64(&mut _t1);
        let _t36 = timestamp::now_seconds();
        let _t4 = timestamp::now_seconds();
        let _t40 = price::new(_t23, _t25, _t2, _t3);
        let _t45 = price::new(_t33, _t35, _t2, _t3);
        let _t11 = price_feed::new(_t21, _t40, _t45);
        let _t50 = price_info::new(_t36, _t4, _t11);
        let _t52 = cursor::rest<u8>(_t1);
        _t50
    }
    fun parse_accumulator_updates(p0: &mut cursor::Cursor<u8>): vector<price_info::PriceInfo> {
        let _t1 = deserialize::deserialize_u8(p0);
        let _t2 = vector::empty<price_info::PriceInfo>();
        while (_t1 > 0u8) {
            let _t3 = deserialize::deserialize_u16(p0);
            let _t4 = parse_accumulator_update_message(deserialize::deserialize_vector(p0, _t3));
            vector::push_back<price_info::PriceInfo>(&mut _t2, _t4);
            let _t5 = deserialize::deserialize_u8(p0);
            while (_t5 > 0u8) {
                let _t26 = keccak160::get_hash_length();
                let _t27 = deserialize::deserialize_vector(p0, _t26);
                _t5 = _t5 - 1u8;
                continue
            };
            _t1 = _t1 - 1u8;
            continue
        };
        _t2
    }
    fun parse_and_verify_accumulator_message(p0: &mut cursor::Cursor<u8>): vector<price_info::PriceInfo> {
        if (!(deserialize::deserialize_u8(p0) == 1u8)) {
            let _t29 = error::invalid_accumulator_payload();
            abort _t29
        };
        let _t8 = deserialize::deserialize_u8(p0);
        let _t13 = deserialize::deserialize_u8(p0) as u64;
        let _t14 = deserialize::deserialize_vector(p0, _t13);
        if (!(deserialize::deserialize_u8(p0) == 0u8)) {
            let _t27 = error::invalid_accumulator_payload();
            abort _t27
        };
        let _t2 = deserialize::deserialize_u16(p0);
        let _t23 = deserialize::deserialize_vector(p0, _t2);
        parse_accumulator_updates(p0)
    }
    friend fun update_cache(p0: vector<price_info::PriceInfo>) {
        while (!vector::is_empty<price_info::PriceInfo>(&p0)) {
            let _t1 = vector::pop_back<price_info::PriceInfo>(&mut p0);
            if (!is_fresh_update(&_t1)) continue;
            let _t2 = *price_info::get_price_feed(&_t1);
            state::set_latest_price_info(*price_feed::get_price_identifier(&_t2), _t1);
            let _t17 = timestamp::now_microseconds();
            event::emit_price_feed_update(_t2, _t17);
            continue
        };
        vector::destroy_empty<price_info::PriceInfo>(p0);
    }
    fun update_price_feed_from_single_vaa(p0: vector<u8>): u64 {
        let _t4;
        let _t3;
        let _t1 = cursor::init<u8>(p0);
        if (deserialize::deserialize_u32(&mut _t1) == 1347305813) {
            let _t2 = parse_and_verify_accumulator_message(&mut _t1);
            _t3 = vector::length<price_info::PriceInfo>(&_t2);
            _t4 = _t2
        } else {
            let _t21 = vaa::parse_payload(p0);
            _t3 = 1;
            _t4 = batch_price_attestation::destroy(batch_price_attestation::deserialize(_t21))
        };
        update_cache(_t4);
        let _t18 = cursor::rest<u8>(_t1);
        _t3
    }
    public entry fun update_price_feeds_with_funder(p0: &signer, p1: vector<vector<u8>>) {
        let _t2 = 0;
        while (!vector::is_empty<vector<u8>>(&p1)) {
            let _t10 = update_price_feed_from_single_vaa(vector::pop_back<vector<u8>>(&mut p1));
            _t2 = _t2 + _t10;
            continue
        };
    }
}
