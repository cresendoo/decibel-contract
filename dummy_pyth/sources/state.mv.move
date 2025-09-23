module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::state {
    use 0x1::table;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_identifier;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_info;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::error;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::pyth;
    struct LatestPriceInfo has key {
        info: table::Table<price_identifier::PriceIdentifier, price_info::PriceInfo>,
    }
    struct StalePriceThreshold has key {
        threshold_secs: u64,
    }
    friend fun init(p0: &signer, p1: u64) {
        let _t4 = StalePriceThreshold{threshold_secs: p1};
        move_to<StalePriceThreshold>(p0, _t4);
        let _t7 = LatestPriceInfo{info: table::new<price_identifier::PriceIdentifier,price_info::PriceInfo>()};
        move_to<LatestPriceInfo>(p0, _t7);
    }
    public fun get_latest_price_info(p0: price_identifier::PriceIdentifier): price_info::PriceInfo
        acquires LatestPriceInfo
    {
        if (!price_info_cached(p0)) {
            let _t9 = error::unknown_price_feed();
            abort _t9
        };
        *table::borrow<price_identifier::PriceIdentifier,price_info::PriceInfo>(&borrow_global<LatestPriceInfo>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).info, p0)
    }
    public fun price_info_cached(p0: price_identifier::PriceIdentifier): bool
        acquires LatestPriceInfo
    {
        table::contains<price_identifier::PriceIdentifier,price_info::PriceInfo>(&borrow_global<LatestPriceInfo>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).info, p0)
    }
    public fun get_stale_price_threshold_secs(): u64
        acquires StalePriceThreshold
    {
        *&borrow_global<StalePriceThreshold>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).threshold_secs
    }
    friend fun set_latest_price_info(p0: price_identifier::PriceIdentifier, p1: price_info::PriceInfo)
        acquires LatestPriceInfo
    {
        table::upsert<price_identifier::PriceIdentifier,price_info::PriceInfo>(&mut borrow_global_mut<LatestPriceInfo>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).info, p0, p1);
    }
    friend fun set_stale_price_threshold_secs(p0: u64)
        acquires StalePriceThreshold
    {
        let _t1 = &mut borrow_global_mut<StalePriceThreshold>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).threshold_secs;
        *_t1 = p0;
    }
}
