module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_status {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::error;
    struct PriceStatus has copy, drop, store {
        status: u64,
    }
    public fun from_u64(p0: u64): PriceStatus {
        if (!(p0 <= 1)) {
            let _t6 = error::invalid_price_status();
            abort _t6
        };
        PriceStatus{status: p0}
    }
    public fun get_status(p0: &PriceStatus): u64 {
        *&p0.status
    }
    public fun new_trading(): PriceStatus {
        PriceStatus{status: 1}
    }
    public fun new_unknown(): PriceStatus {
        PriceStatus{status: 0}
    }
}
