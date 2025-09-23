module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::batch_price_attestation {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_info;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::cursor;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::deserialize;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::error;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_identifier;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::pyth_i64;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_status;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price;
    use 0x1::timestamp;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_feed;
    struct BatchPriceAttestation {
        header: Header,
        attestation_size: u64,
        attestation_count: u64,
        price_infos: vector<price_info::PriceInfo>,
    }
    struct Header {
        magic: u64,
        version_major: u64,
        version_minor: u64,
        header_size: u64,
        payload_id: u8,
    }
    public fun deserialize(p0: vector<u8>): BatchPriceAttestation {
        let _t1 = cursor::init<u8>(p0);
        let _t2 = deserialize_header(&mut _t1);
        let _t3 = deserialize::deserialize_u16(&mut _t1);
        let _t4 = deserialize::deserialize_u16(&mut _t1);
        let _t5 = 0x1::vector::empty<price_info::PriceInfo>();
        let _t6 = 0;
        while (_t6 < _t3) {
            let _t7 = deserialize_price_info(&mut _t1);
            0x1::vector::push_back<price_info::PriceInfo>(&mut _t5, _t7);
            let _t25 = &mut _t1;
            let _t28 = _t4 - 149;
            let _t29 = deserialize::deserialize_vector(_t25, _t28);
            _t6 = _t6 + 1;
            continue
        };
        cursor::destroy_empty<u8>(_t1);
        BatchPriceAttestation{header: _t2, attestation_size: _t4, attestation_count: _t3, price_infos: _t5}
    }
    public fun destroy(p0: BatchPriceAttestation): vector<price_info::PriceInfo> {
        let BatchPriceAttestation{header: _t3, attestation_size: _t4, attestation_count: _t5, price_infos: _t6} = p0;
        let Header{magic: _t7, version_major: _t8, version_minor: _t9, header_size: _t10, payload_id: _t11} = _t3;
        _t6
    }
    fun deserialize_header(p0: &mut cursor::Cursor<u8>): Header {
        let _t1 = deserialize::deserialize_u32(p0);
        if (!(_t1 == 1345476424)) {
            let _t42 = error::invalid_attestation_magic_value();
            abort _t42
        };
        let _t2 = deserialize::deserialize_u16(p0);
        let _t3 = deserialize::deserialize_u16(p0);
        let _t4 = deserialize::deserialize_u16(p0);
        let _t5 = deserialize::deserialize_u8(p0);
        if (!(_t4 >= 1)) {
            let _t40 = error::invalid_batch_attestation_header_size();
            abort _t40
        };
        let _t6 = _t4 - 1;
        let _t30 = deserialize::deserialize_vector(p0, _t6);
        Header{magic: _t1, version_major: _t2, version_minor: _t3, header_size: _t4, payload_id: _t5}
    }
    fun deserialize_price_info(p0: &mut cursor::Cursor<u8>): price_info::PriceInfo {
        let _t16 = deserialize::deserialize_vector(p0, 32);
        let _t1 = price_identifier::from_byte_vec(deserialize::deserialize_vector(p0, 32));
        let _t22 = deserialize::deserialize_pyth_i64(p0);
        let _t24 = deserialize::deserialize_u64(p0);
        let _t2 = deserialize::deserialize_i32(p0);
        let _t3 = deserialize::deserialize_pyth_i64(p0);
        let _t4 = deserialize::deserialize_u64(p0);
        let _t5 = price_status::from_u64(deserialize::deserialize_u8(p0) as u64);
        let _t36 = deserialize::deserialize_u32(p0);
        let _t38 = deserialize::deserialize_u32(p0);
        let _t6 = deserialize::deserialize_u64(p0);
        let _t7 = deserialize::deserialize_u64(p0);
        let _t8 = deserialize::deserialize_u64(p0);
        let _t9 = deserialize::deserialize_pyth_i64(p0);
        let _t10 = deserialize::deserialize_u64(p0);
        let _t13 = price::new(_t22, _t24, _t2, _t7);
        let _t53 = price_status::new_trading();
        if (_t5 != _t53) _t13 = price::new(_t9, _t10, _t2, _t8);
        let _t61 = price_status::new_trading();
        if (_t5 != _t61) _t7 = _t8;
        let _t65 = timestamp::now_seconds();
        let _t72 = price::new(_t3, _t4, _t2, _t7);
        let _t73 = price_feed::new(_t1, _t13, _t72);
        price_info::new(_t6, _t65, _t73)
    }
    public fun get_attestation_count(p0: &BatchPriceAttestation): u64 {
        *&p0.attestation_count
    }
    public fun get_price_info(p0: &BatchPriceAttestation, p1: u64): &price_info::PriceInfo {
        0x1::vector::borrow<price_info::PriceInfo>(&p0.price_infos, p1)
    }
}
