module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::pyth_i64;
    struct Price has copy, drop, store {
        price: pyth_i64::I64,
        conf: u64,
        expo: pyth_i64::I64,
        timestamp: u64,
    }
    public fun new(p0: pyth_i64::I64, p1: u64, p2: pyth_i64::I64, p3: u64): Price {
        Price{price: p0, conf: p1, expo: p2, timestamp: p3}
    }
    public fun get_conf(p0: &Price): u64 {
        *&p0.conf
    }
    public fun get_expo(p0: &Price): pyth_i64::I64 {
        *&p0.expo
    }
    public fun get_price(p0: &Price): pyth_i64::I64 {
        *&p0.price
    }
    public fun get_timestamp(p0: &Price): u64 {
        *&p0.timestamp
    }
}
