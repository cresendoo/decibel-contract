module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::external_address {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::cursor;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::deserialize;
    use 0x1::vector;
    struct ExternalAddress has copy, drop, store {
        external_address: vector<u8>,
    }
    public fun deserialize(p0: &mut cursor::Cursor<u8>): ExternalAddress {
        from_bytes(deserialize::deserialize_vector(p0, 32))
    }
    public fun from_bytes(p0: vector<u8>): ExternalAddress {
        left_pad(&p0)
    }
    public fun left_pad(p0: &vector<u8>): ExternalAddress {
        ExternalAddress{external_address: pad_left_32(p0)}
    }
    public fun get_bytes(p0: &ExternalAddress): vector<u8> {
        *&p0.external_address
    }
    public fun pad_left_32(p0: &vector<u8>): vector<u8> {
        let _t1 = vector::length<u8>(p0);
        if (!(_t1 <= 32)) abort 0;
        let _t2 = vector::empty<u8>();
        let _t3 = 32 - _t1;
        while (_t3 > 0) {
            vector::push_back<u8>(&mut _t2, 0u8);
            _t3 = _t3 - 1
        };
        let _t21 = &mut _t2;
        let _t23 = *p0;
        vector::append<u8>(_t21, _t23);
        _t2
    }
}
