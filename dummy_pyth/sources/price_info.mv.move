module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_info {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_feed;
    struct PriceInfo has copy, drop, store {
        attestation_time: u64,
        arrival_time: u64,
        price_feed: price_feed::PriceFeed,
    }
    public fun new(p0: u64, p1: u64, p2: price_feed::PriceFeed): PriceInfo {
        PriceInfo{attestation_time: p0, arrival_time: p1, price_feed: p2}
    }
    public fun get_arrival_time(p0: &PriceInfo): u64 {
        *&p0.arrival_time
    }
    public fun get_attestation_time(p0: &PriceInfo): u64 {
        *&p0.attestation_time
    }
    public fun get_price_feed(p0: &PriceInfo): &price_feed::PriceFeed {
        &p0.price_feed
    }
}
