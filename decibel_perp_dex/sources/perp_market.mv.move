module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market {
    use 0x7::market;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine_types;
    use 0x1::object;
    use 0x7::order_book_types;
    use 0x7::order_book;
    use 0x1::option;
    use 0x7::market_types;
    use 0x7::single_order_book;
    use 0x7::single_order_types;
    use 0x1::string;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::tp_sl_utils;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::liquidation;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::async_matching_engine;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine;
    struct PerpMarket has key {
        market: market::Market<perp_engine_types::OrderMetadata>,
    }
    public fun get_remaining_size(p0: object::Object<PerpMarket>, p1: order_book_types::OrderIdType): u64
        acquires PerpMarket
    {
        let _t2 = p0;
        let _t5 = object::object_address<PerpMarket>(&_t2);
        order_book::get_remaining_size<perp_engine_types::OrderMetadata>(market::get_order_book<perp_engine_types::OrderMetadata>(&borrow_global<PerpMarket>(_t5).market), p1)
    }
    public fun best_bid_price(p0: object::Object<PerpMarket>): option::Option<u64>
        acquires PerpMarket
    {
        let _t1 = p0;
        let _t4 = object::object_address<PerpMarket>(&_t1);
        market::best_bid_price<perp_engine_types::OrderMetadata>(&borrow_global<PerpMarket>(_t4).market)
    }
    public fun best_ask_price(p0: object::Object<PerpMarket>): option::Option<u64>
        acquires PerpMarket
    {
        let _t1 = p0;
        let _t4 = object::object_address<PerpMarket>(&_t1);
        market::best_ask_price<perp_engine_types::OrderMetadata>(&borrow_global<PerpMarket>(_t4).market)
    }
    friend fun decrease_order_size(p0: object::Object<PerpMarket>, p1: &signer, p2: order_book_types::OrderIdType, p3: u64, p4: &market_types::MarketClearinghouseCallbacks<perp_engine_types::OrderMetadata>)
        acquires PerpMarket
    {
        let _t5 = p0;
        let _t8 = object::object_address<PerpMarket>(&_t5);
        market::decrease_order_size<perp_engine_types::OrderMetadata>(&mut borrow_global_mut<PerpMarket>(_t8).market, p1, p2, p3, p4);
    }
    friend fun get_slippage_price(p0: object::Object<PerpMarket>, p1: bool, p2: u64): option::Option<u64>
        acquires PerpMarket
    {
        let _t3 = p0;
        let _t6 = object::object_address<PerpMarket>(&_t3);
        order_book::get_slippage_price<perp_engine_types::OrderMetadata>(market::get_order_book<perp_engine_types::OrderMetadata>(&borrow_global<PerpMarket>(_t6).market), p1, p2)
    }
    friend fun is_taker_order(p0: object::Object<PerpMarket>, p1: u64, p2: bool, p3: option::Option<order_book_types::TriggerCondition>): bool
        acquires PerpMarket
    {
        let _t4 = p0;
        let _t7 = object::object_address<PerpMarket>(&_t4);
        market::is_taker_order<perp_engine_types::OrderMetadata>(freeze(&mut borrow_global_mut<PerpMarket>(_t7).market), p1, p2, p3)
    }
    friend fun place_maker_order(p0: object::Object<PerpMarket>, p1: single_order_book::SingleOrderRequest<perp_engine_types::OrderMetadata>)
        acquires PerpMarket
    {
        let _t2 = p0;
        let _t5 = object::object_address<PerpMarket>(&_t2);
        order_book::place_maker_order<perp_engine_types::OrderMetadata>(market::get_order_book_mut<perp_engine_types::OrderMetadata>(&mut borrow_global_mut<PerpMarket>(_t5).market), p1);
    }
    friend fun place_bulk_order(p0: object::Object<PerpMarket>, p1: address, p2: vector<u64>, p3: vector<u64>, p4: vector<u64>, p5: vector<u64>, p6: &market_types::MarketClearinghouseCallbacks<perp_engine_types::OrderMetadata>): option::Option<order_book_types::OrderIdType>
        acquires PerpMarket
    {
        let _t7 = p0;
        let _t10 = object::object_address<PerpMarket>(&_t7);
        market::place_bulk_order<perp_engine_types::OrderMetadata>(&mut borrow_global_mut<PerpMarket>(_t10).market, p1, p2, p3, p4, p5, p6)
    }
    friend fun take_ready_price_based_orders(p0: object::Object<PerpMarket>, p1: u64, p2: u64): vector<single_order_types::SingleOrder<perp_engine_types::OrderMetadata>>
        acquires PerpMarket
    {
        let _t3 = p0;
        let _t6 = object::object_address<PerpMarket>(&_t3);
        market::take_ready_price_based_orders<perp_engine_types::OrderMetadata>(&mut borrow_global_mut<PerpMarket>(_t6).market, p1, p2)
    }
    friend fun cancel_order(p0: object::Object<PerpMarket>, p1: &signer, p2: order_book_types::OrderIdType, p3: &market_types::MarketClearinghouseCallbacks<perp_engine_types::OrderMetadata>)
        acquires PerpMarket
    {
        let _t4 = p0;
        let _t7 = object::object_address<PerpMarket>(&_t4);
        market::cancel_order<perp_engine_types::OrderMetadata>(&mut borrow_global_mut<PerpMarket>(_t7).market, p1, p2, p3);
    }
    friend fun take_ready_time_based_orders(p0: object::Object<PerpMarket>, p1: u64): vector<single_order_types::SingleOrder<perp_engine_types::OrderMetadata>>
        acquires PerpMarket
    {
        let _t2 = p0;
        let _t5 = object::object_address<PerpMarket>(&_t2);
        market::take_ready_time_based_orders<perp_engine_types::OrderMetadata>(&mut borrow_global_mut<PerpMarket>(_t5).market, p1)
    }
    friend fun emit_event_for_order(p0: object::Object<PerpMarket>, p1: order_book_types::OrderIdType, p2: option::Option<u64>, p3: address, p4: u64, p5: u64, p6: u64, p7: u64, p8: bool, p9: bool, p10: market_types::OrderStatus, p11: &string::String, p12: perp_engine_types::OrderMetadata, p13: option::Option<order_book_types::TriggerCondition>, p14: order_book_types::TimeInForce, p15: &market_types::MarketClearinghouseCallbacks<perp_engine_types::OrderMetadata>)
        acquires PerpMarket
    {
        let _t16 = p0;
        let _t19 = object::object_address<PerpMarket>(&_t16);
        let _t21 = &borrow_global<PerpMarket>(_t19).market;
        let _t34 = option::some<perp_engine_types::OrderMetadata>(p12);
        market::emit_event_for_order<perp_engine_types::OrderMetadata>(_t21, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, _t34, p13, p14, p15);
    }
    friend fun next_order_id(p0: object::Object<PerpMarket>): order_book_types::OrderIdType
        acquires PerpMarket
    {
        let _t1 = p0;
        let _t4 = object::object_address<PerpMarket>(&_t1);
        market::next_order_id<perp_engine_types::OrderMetadata>(&mut borrow_global_mut<PerpMarket>(_t4).market)
    }
    friend fun place_order_with_order_id(p0: object::Object<PerpMarket>, p1: address, p2: u64, p3: u64, p4: u64, p5: bool, p6: order_book_types::TimeInForce, p7: option::Option<order_book_types::TriggerCondition>, p8: perp_engine_types::OrderMetadata, p9: order_book_types::OrderIdType, p10: option::Option<u64>, p11: u32, p12: bool, p13: bool, p14: &market_types::MarketClearinghouseCallbacks<perp_engine_types::OrderMetadata>): market::OrderMatchResult
        acquires PerpMarket
    {
        let _t15 = p0;
        let _t18 = object::object_address<PerpMarket>(&_t15);
        let _t20 = &mut borrow_global_mut<PerpMarket>(_t18).market;
        let _t30 = option::some<order_book_types::OrderIdType>(p9);
        market::place_order_with_order_id<perp_engine_types::OrderMetadata>(_t20, p1, p2, p3, p4, p5, p6, p7, p8, _t30, p10, p11, p12, p13, p14)
    }
    friend fun cancel_client_order(p0: object::Object<PerpMarket>, p1: &signer, p2: u64, p3: &market_types::MarketClearinghouseCallbacks<perp_engine_types::OrderMetadata>)
        acquires PerpMarket
    {
        let _t4 = p0;
        let _t7 = object::object_address<PerpMarket>(&_t4);
        market::cancel_order_with_client_id<perp_engine_types::OrderMetadata>(&mut borrow_global_mut<PerpMarket>(_t7).market, p1, p2, p3);
    }
    friend fun register_market(p0: &signer, p1: market::Market<perp_engine_types::OrderMetadata>) {
        let _t2 = PerpMarket{market: p1};
        move_to<PerpMarket>(p0, _t2);
    }
}
