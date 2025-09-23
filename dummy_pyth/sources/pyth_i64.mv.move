module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::pyth_i64 {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::error;
    struct I64 has copy, drop, store {
        negative: bool,
        magnitude: u64,
    }
    public fun new(p0: u64, p1: bool): I64 {
        let _t2 = 9223372036854775807;
        if (p1) _t2 = 9223372036854775808;
        if (!(p0 <= _t2)) {
            let _t17 = error::magnitude_too_large();
            abort _t17
        };
        if (p0 == 0) p1 = false;
        I64{negative: p1, magnitude: p0}
    }
    public fun from_u64(p0: u64): I64 {
        let _t1 = p0 >> 63u8 == 1;
        new(parse_magnitude(p0, _t1), _t1)
    }
    fun parse_magnitude(p0: u64, p1: bool): u64 {
        if (!p1) return p0;
        (p0 ^ 18446744073709551615) + 1
    }
    public fun get_is_negative(p0: &I64): bool {
        *&p0.negative
    }
    public fun get_magnitude_if_negative(p0: &I64): u64 {
        if (!*&p0.negative) {
            let _t8 = error::positive_value();
            abort _t8
        };
        *&p0.magnitude
    }
    public fun get_magnitude_if_positive(p0: &I64): u64 {
        if (*&p0.negative) {
            let _t8 = error::negative_value();
            abort _t8
        };
        *&p0.magnitude
    }
}
