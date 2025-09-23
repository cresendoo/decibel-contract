module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::math {
    use 0x1::error;
    use 0x1::math64;
    struct Precision has copy, drop, store {
        decimals: u8,
        multiplier: u64,
    }
    public fun convert_decimals(p0: u64, p1: &Precision, p2: &Precision, p3: bool): u64 {
        let _t4;
        let _t11 = *&p1.decimals;
        let _t14 = *&p2.decimals;
        if (_t11 == _t14) _t4 = p0 else {
            let _t22 = *&p1.decimals;
            let _t25 = *&p2.decimals;
            if (_t22 > _t25) {
                let _t5 = p0;
                let _t30 = *&p1.multiplier;
                let _t33 = *&p2.multiplier;
                let _t6 = _t30 / _t33;
                if (p3) {
                    let _t7 = _t5;
                    let _t8 = _t6;
                    if (_t7 == 0) if (_t8 != 0) _t4 = 0 else {
                        let _t46 = error::invalid_argument(4);
                        abort _t46
                    } else _t4 = (_t7 - 1) / _t8 + 1
                } else _t4 = _t5 / _t6
            } else {
                let _t60 = *&p2.multiplier;
                let _t63 = *&p1.multiplier;
                let _t64 = _t60 / _t63;
                _t4 = p0 * _t64
            }
        };
        _t4
    }
    public fun get_decimals(p0: &Precision): u8 {
        *&p0.decimals
    }
    public fun get_decimals_multiplier(p0: &Precision): u64 {
        *&p0.multiplier
    }
    public fun new_precision(p0: u8): Precision {
        let _t4 = p0 as u64;
        let _t5 = math64::pow(10, _t4);
        Precision{decimals: p0, multiplier: _t5}
    }
}
