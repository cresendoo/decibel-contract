module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_feed {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_identifier;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price;
    struct PriceFeed has copy, drop, store {
        price_identifier: price_identifier::PriceIdentifier,
        price: price::Price,
        ema_price: price::Price,
    }
    public fun new(p0: price_identifier::PriceIdentifier, p1: price::Price, p2: price::Price): PriceFeed {
        PriceFeed{price_identifier: p0, price: p1, ema_price: p2}
    }
    public fun get_price(p0: &PriceFeed): price::Price {
        *&p0.price
    }
    public fun get_ema_price(p0: &PriceFeed): price::Price {
        *&p0.ema_price
    }
    public fun get_price_identifier(p0: &PriceFeed): &price_identifier::PriceIdentifier {
        &p0.price_identifier
    }
}
