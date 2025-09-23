module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::vaa {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::cursor;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::deserialize;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::external_address;
    public fun parse_payload(p0: vector<u8>): vector<u8> {
        let _t1 = cursor::init<u8>(p0);
        if (!(deserialize::deserialize_u8(&mut _t1) == 1u8)) abort 6;
        let _t11 = deserialize::deserialize_u32(&mut _t1);
        let _t2 = deserialize::deserialize_u8(&mut _t1);
        while (_t2 > 0u8) {
            let _t18 = deserialize::deserialize_u8(&mut _t1);
            let _t21 = deserialize::deserialize_vector(&mut _t1, 64);
            let _t23 = deserialize::deserialize_u8(&mut _t1);
            _t2 = _t2 - 1u8;
            continue
        };
        let _t3 = cursor::init<u8>(cursor::rest<u8>(_t1));
        let _t31 = deserialize::deserialize_u32(&mut _t3);
        let _t33 = deserialize::deserialize_u32(&mut _t3);
        let _t35 = deserialize::deserialize_u16(&mut _t3);
        let _t37 = external_address::deserialize(&mut _t3);
        let _t39 = deserialize::deserialize_u64(&mut _t3);
        let _t41 = deserialize::deserialize_u8(&mut _t3);
        cursor::rest<u8>(_t3)
    }
}
