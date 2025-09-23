module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::liquidation_config {
    use 0x1::error;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::accounts_collateral;
    enum LiquidationConfig has drop, store {
        V1 {
            backstop_liquidator: address,
            maintenance_margin_leverage_multiplier: u64,
            maintenance_margin_leverage_divisor: u64,
            backstop_margin_maintenance_multiplier: u64,
            backstop_margin_maintenance_divisor: u64,
        }
    }
    friend fun backstop_liquidator(p0: &LiquidationConfig): address {
        *&p0.backstop_liquidator
    }
    friend fun new_config(p0: address): LiquidationConfig {
        LiquidationConfig::V1{backstop_liquidator: p0, maintenance_margin_leverage_multiplier: 1, maintenance_margin_leverage_divisor: 2, backstop_margin_maintenance_multiplier: 1, backstop_margin_maintenance_divisor: 3}
    }
    friend fun get_liquidation_margin(p0: &LiquidationConfig, p1: u64, p2: bool): u64 {
        let _t5;
        loop {
            let _t3;
            if (p2) {
                let _t10 = *&p0.backstop_margin_maintenance_multiplier;
                _t3 = p1 * _t10;
                let _t4 = *&p0.backstop_margin_maintenance_divisor;
                if (!(_t3 == 0)) {
                    _t5 = (_t3 - 1) / _t4 + 1;
                    break
                };
                if (!(_t4 != 0)) {
                    let _t24 = error::invalid_argument(4);
                    abort _t24
                };
                _t5 = 0;
                break
            };
            let _t35 = *&p0.maintenance_margin_leverage_multiplier;
            p1 = p1 * _t35;
            _t3 = *&p0.maintenance_margin_leverage_divisor;
            if (!(p1 == 0)) {
                _t5 = (p1 - 1) / _t3 + 1;
                break
            };
            if (!(_t3 != 0)) {
                let _t48 = error::invalid_argument(4);
                abort _t48
            };
            _t5 = 0;
            break
        };
        _t5
    }
    friend fun get_liquidation_price(p0: &LiquidationConfig, p1: u64, p2: u8, p3: bool): u64 {
        let _t6;
        loop {
            let _t4;
            if (p3) {
                let _t11 = *&p0.backstop_margin_maintenance_multiplier;
                _t4 = p1 * _t11;
                let _t14 = p2 as u64;
                let _t17 = *&p0.backstop_margin_maintenance_divisor;
                let _t5 = _t14 * _t17;
                if (!(_t4 == 0)) {
                    _t6 = (_t4 - 1) / _t5 + 1;
                    break
                };
                if (!(_t5 != 0)) {
                    let _t28 = error::invalid_argument(4);
                    abort _t28
                };
                _t6 = 0;
                break
            };
            let _t39 = *&p0.maintenance_margin_leverage_multiplier;
            p1 = p1 * _t39;
            let _t42 = p2 as u64;
            let _t45 = *&p0.maintenance_margin_leverage_divisor;
            _t4 = _t42 * _t45;
            if (!(p1 == 0)) {
                _t6 = (p1 - 1) / _t4 + 1;
                break
            };
            if (!(_t4 != 0)) {
                let _t55 = error::invalid_argument(4);
                abort _t55
            };
            _t6 = 0;
            break
        };
        _t6
    }
    friend fun update_backstop_liquidator(p0: &mut LiquidationConfig, p1: address) {
        let _t2 = &mut p0.backstop_liquidator;
        *_t2 = p1;
    }
}
