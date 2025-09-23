module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::keccak160 {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::error;
    use 0x1::aptos_hash;
    struct Hash has drop {
        data: vector<u8>,
    }
    public fun new(p0: vector<u8>): Hash {
        if (!(0x1::vector::length<u8>(&p0) == 20)) {
            let _t7 = error::invalid_keccak160_length();
            abort _t7
        };
        Hash{data: p0}
    }
    public fun from_data(p0: vector<u8>): Hash {
        let _t1 = aptos_hash::keccak256(p0);
        while (0x1::vector::length<u8>(&_t1) > 20) {
            let _t9 = 0x1::vector::pop_back<u8>(&mut _t1);
            continue
        };
        new(_t1)
    }
    public fun get_data(p0: &Hash): vector<u8> {
        *&p0.data
    }
    public fun get_hash_length(): u64 {
        20
    }
    public fun is_smaller(p0: &Hash, p1: &Hash): bool {
        let _t2 = 0;
        'l0: loop {
            let _t5;
            let _t7;
            loop {
                let _t3 = get_data(p0);
                let _t13 = 0x1::vector::length<u8>(&_t3);
                if (!(_t2 < _t13)) break 'l0;
                let _t4 = get_data(p0);
                _t5 = *0x1::vector::borrow<u8>(&_t4, _t2);
                let _t6 = get_data(p1);
                _t7 = *0x1::vector::borrow<u8>(&_t6, _t2);
                if (_t5 != _t7) break;
                _t2 = _t2 + 1;
                continue
            };
            return _t5 < _t7
        };
        false
    }
}
