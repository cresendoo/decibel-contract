module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine_types {
    use 0x7::order_book_types;
    use 0x1::option;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::builder_code_registry;
    use 0x1::bcs;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::tp_sl_utils;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::clearinghouse_perp;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::async_matching_engine;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine;
    enum ChildTpSlOrder has copy, drop, store {
        V1 {
            trigger_price: u64,
            parent_order_id: order_book_types::OrderIdType,
            order_id: order_book_types::OrderIdType,
            limit_price: option::Option<u64>,
        }
    }
    enum OrderMetadata has copy, drop, store {
        V1 {
            is_reduce_only: bool,
            use_backstop_liquidation_margin: bool,
            twap: option::Option<TwapMetadata>,
            tp_sl: TpSlMetadata,
            builder_code: option::Option<builder_code_registry::BuilderCode>,
        }
    }
    enum TwapMetadata has copy, drop, store {
        V1 {
            frequency_seconds: u64,
            end_time_seconds: u64,
        }
    }
    enum TpSlMetadata has copy, drop, store {
        V1 {
            tp: option::Option<ChildTpSlOrder>,
            sl: option::Option<ChildTpSlOrder>,
        }
    }
    friend fun is_reduce_only(p0: &OrderMetadata): bool {
        *&p0.is_reduce_only
    }
    friend fun use_backstop_liquidation_margin(p0: &OrderMetadata): bool {
        *&p0.use_backstop_liquidation_margin
    }
    public fun get_order_metadata_bytes(p0: OrderMetadata): vector<u8> {
        bcs::to_bytes<OrderMetadata>(&p0)
    }
    friend fun destroy_child_tp_sl_order(p0: ChildTpSlOrder): (u64, option::Option<u64>, order_book_types::OrderIdType, order_book_types::OrderIdType) {
        let _t3 = *&(&p0).trigger_price;
        let _t6 = *&(&p0).limit_price;
        let _t9 = *&(&p0).order_id;
        let _t12 = *&(&p0).parent_order_id;
        (_t3, _t6, _t9, _t12)
    }
    friend fun get_builder_code_from_metadata(p0: &OrderMetadata): option::Option<builder_code_registry::BuilderCode> {
        *&p0.builder_code
    }
    friend fun get_sl_from_metadata(p0: &OrderMetadata): option::Option<ChildTpSlOrder> {
        *&(&p0.tp_sl).sl
    }
    friend fun get_tp_from_metadata(p0: &OrderMetadata): option::Option<ChildTpSlOrder> {
        *&(&p0.tp_sl).tp
    }
    friend fun get_twap_from_metadata(p0: &OrderMetadata): (u64, u64) {
        let _t1 = option::destroy_some<TwapMetadata>(*&p0.twap);
        let _t8 = *&(&_t1).frequency_seconds;
        let _t11 = *&(&_t1).end_time_seconds;
        (_t8, _t11)
    }
    friend fun new_child_tp_sl_order(p0: u64, p1: option::Option<u64>, p2: order_book_types::OrderIdType, p3: order_book_types::OrderIdType): ChildTpSlOrder {
        ChildTpSlOrder::V1{trigger_price: p0, parent_order_id: p3, order_id: p2, limit_price: p1}
    }
    friend fun new_default_order_metadata(): OrderMetadata {
        let _t0 = option::none<TwapMetadata>();
        let _t5 = new_tp_sl_empty_metadata();
        let _t6 = option::none<builder_code_registry::BuilderCode>();
        OrderMetadata::V1{is_reduce_only: false, use_backstop_liquidation_margin: false, twap: _t0, tp_sl: _t5, builder_code: _t6}
    }
    public fun new_tp_sl_empty_metadata(): TpSlMetadata {
        let _t0 = option::none<ChildTpSlOrder>();
        let _t1 = option::none<ChildTpSlOrder>();
        TpSlMetadata::V1{tp: _t0, sl: _t1}
    }
    public fun new_liquidation_metadata(): OrderMetadata {
        let _t0 = option::none<TwapMetadata>();
        let _t5 = new_tp_sl_empty_metadata();
        let _t6 = option::none<builder_code_registry::BuilderCode>();
        OrderMetadata::V1{is_reduce_only: false, use_backstop_liquidation_margin: true, twap: _t0, tp_sl: _t5, builder_code: _t6}
    }
    friend fun new_order_metadata(p0: bool, p1: option::Option<TwapMetadata>, p2: option::Option<ChildTpSlOrder>, p3: option::Option<ChildTpSlOrder>, p4: option::Option<builder_code_registry::BuilderCode>): OrderMetadata {
        let _t10 = TpSlMetadata::V1{tp: p2, sl: p3};
        OrderMetadata::V1{is_reduce_only: p0, use_backstop_liquidation_margin: false, twap: p1, tp_sl: _t10, builder_code: p4}
    }
    friend fun new_twap_metadata(p0: u64, p1: u64): TwapMetadata {
        TwapMetadata::V1{frequency_seconds: p0, end_time_seconds: p1}
    }
}
