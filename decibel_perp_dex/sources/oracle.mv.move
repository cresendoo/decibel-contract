module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::oracle {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_identifier;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::math;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::pyth;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::pyth_i64;
    use 0x1::signer;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_market_config;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_engine;
    enum OracleSource has store {
        Internal {
            value: u64,
            allowed_issuer: address,
        }
        Pyth {
            price_identifier: price_identifier::PriceIdentifier,
            max_staleness_secs: u64,
            precision: math::Precision,
        }
    }
    friend fun get_oracle_price(p0: &OracleSource, p1: math::Precision): u64 {
        let _t8;
        if (p0 is Pyth) {
            let _t12 = &p0.price_identifier;
            let _t2 = &p0.precision;
            let _t3 = pyth::get_price_unsafe(*_t12);
            let _t4 = price::get_expo(&_t3);
            let _t5 = price::get_price(&_t3);
            let _t6 = pyth_i64::get_magnitude_if_positive(&_t5);
            let _t7 = *_t2;
            if (pyth_i64::get_is_negative(&_t4)) {
                let _t28 = math::get_decimals(&_t7);
                let _t31 = pyth_i64::get_magnitude_if_negative(&_t4) as u8;
                _t7 = math::new_precision(_t28 + _t31)
            } else {
                let _t41 = math::get_decimals(&p1);
                let _t44 = pyth_i64::get_magnitude_if_positive(&_t4) as u8;
                p1 = math::new_precision(_t41 + _t44)
            };
            let _t35 = &_t7;
            let _t36 = &p1;
            _t8 = math::convert_decimals(_t6, _t35, _t36, true)
        } else if (p0 is Internal) _t8 = *&p0.value else abort 14566554180833181697;
        _t8
    }
    friend fun new_internal_oracle(p0: u64, p1: address): OracleSource {
        OracleSource::Internal{value: p0, allowed_issuer: p1}
    }
    friend fun new_pyth_oracle(p0: vector<u8>, p1: u64, p2: u8): OracleSource {
        let _t4 = price_identifier::from_byte_vec(p0);
        let _t7 = math::new_precision(p2);
        OracleSource::Pyth{price_identifier: _t4, max_staleness_secs: p1, precision: _t7}
    }
    friend fun update_internal_oracle_price(p0: &mut OracleSource, p1: &signer, p2: u64) {
        let _t3;
        loop {
            if (p0 is Internal) {
                _t3 = &mut p0.value;
                let _t4 = &mut p0.allowed_issuer;
                let _t12 = signer::address_of(p1);
                let _t14 = *_t4;
                if (_t12 == _t14) break;
                abort 2
            };
            if (p0 is Pyth) abort 0;
            abort 14566554180833181697
        };
        *_t3 = p2;
    }
    friend fun update_internal_oracle_updater(p0: &mut OracleSource, p1: address) {
        if (!(p0 is Internal)) {
            if (p0 is Pyth) abort 0;
            abort 14566554180833181697
        };
        let _t2 = &mut p0.allowed_issuer;
        *_t2 = p1;
    }
}
