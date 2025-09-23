module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::event {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_feed;
    use 0x1::event;
    use 0x1::account;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::pyth;
    struct PriceFeedUpdate has drop, store {
        price_feed: price_feed::PriceFeed,
        timestamp: u64,
    }
    struct PriceFeedUpdateHandle has store, key {
        event: event::EventHandle<PriceFeedUpdate>,
    }
    friend fun init(p0: &signer) {
        let _t4 = PriceFeedUpdateHandle{event: account::new_event_handle<PriceFeedUpdate>(p0)};
        move_to<PriceFeedUpdateHandle>(p0, _t4);
    }
    friend fun emit_price_feed_update(p0: price_feed::PriceFeed, p1: u64)
        acquires PriceFeedUpdateHandle
    {
        let _t4 = &mut borrow_global_mut<PriceFeedUpdateHandle>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).event;
        let _t7 = PriceFeedUpdate{price_feed: p0, timestamp: p1};
        event::emit_event<PriceFeedUpdate>(_t4, _t7);
    }
}
