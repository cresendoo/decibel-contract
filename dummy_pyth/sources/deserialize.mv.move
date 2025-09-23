module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::deserialize {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::cursor;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::pyth_i64;
    public fun deserialize_u16(p0: &mut cursor::Cursor<u8>): u64 {
        let _t1 = 0;
        let _t2 = 0;
        while (_t2 < 2) {
            let _t3 = cursor::poke<u8>(p0);
            let _t13 = _t1 << 8u8;
            let _t15 = _t3 as u64;
            _t1 = _t13 + _t15;
            _t2 = _t2 + 1;
            continue
        };
        _t1
    }
    public fun deserialize_u32(p0: &mut cursor::Cursor<u8>): u64 {
        let _t1 = 0;
        let _t2 = 0;
        while (_t2 < 4) {
            let _t3 = cursor::poke<u8>(p0);
            let _t13 = _t1 << 8u8;
            let _t15 = _t3 as u64;
            _t1 = _t13 + _t15;
            _t2 = _t2 + 1;
            continue
        };
        _t1
    }
    public fun deserialize_u64(p0: &mut cursor::Cursor<u8>): u64 {
        let _t1 = 0;
        let _t2 = 0;
        while (_t2 < 8) {
            let _t3 = cursor::poke<u8>(p0);
            let _t13 = _t1 << 8u8;
            let _t15 = _t3 as u64;
            _t1 = _t13 + _t15;
            _t2 = _t2 + 1;
            continue
        };
        _t1
    }
    public fun deserialize_u8(p0: &mut cursor::Cursor<u8>): u8 {
        cursor::poke<u8>(p0)
    }
    public fun deserialize_vector(p0: &mut cursor::Cursor<u8>, p1: u64): vector<u8> {
        let _t2 = 0x1::vector::empty<u8>();
        while (p1 > 0) {
            let _t7 = &mut _t2;
            let _t9 = cursor::poke<u8>(p0);
            0x1::vector::push_back<u8>(_t7, _t9);
            p1 = p1 - 1;
            continue
        };
        _t2
    }
    public fun deserialize_i32(p0: &mut cursor::Cursor<u8>): pyth_i64::I64 {
        let _t2;
        let _t1 = deserialize_u32(p0);
        if (_t1 >> 31u8 == 1) _t2 = pyth_i64::from_u64(18446744069414584320 + _t1) else _t2 = pyth_i64::from_u64(_t1);
        _t2
    }
    public fun deserialize_pyth_i64(p0: &mut cursor::Cursor<u8>): pyth_i64::I64 {
        pyth_i64::from_u64(deserialize_u64(p0))
    }
}
