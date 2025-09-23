module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::i64 {
    use 0x1::error;
    use 0x1::option;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::fee_distribution;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::trading_fees_manager;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::spread_ema;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_management;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::perp_positions;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::accounts_collateral;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::open_interest_tracker;
    friend 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::clearinghouse_perp;
    struct I64 has copy, drop, store {
        is_positive: bool,
        amount: u64,
    }
    friend fun amount(p0: &I64): u64 {
        *&p0.amount
    }
    friend fun new(p0: bool, p1: u64): I64 {
        let _t2;
        if (p1 == 0) _t2 = zero() else _t2 = I64{is_positive: p0, amount: p1};
        _t2
    }
    friend fun zero(): I64 {
        I64{is_positive: true, amount: 0}
    }
    friend fun is_eq(p0: &I64, p1: &I64): bool {
        let _t2;
        let _t5 = *&p0.is_positive;
        let _t8 = *&p1.is_positive;
        if (_t5 == _t8) {
            let _t12 = *&p0.amount;
            let _t15 = *&p1.amount;
            _t2 = _t12 == _t15
        } else _t2 = false;
        _t2
    }
    friend fun is_gt(p0: &I64, p1: u64): bool {
        let _t2;
        if (*&p0.is_positive) _t2 = *&p0.amount > p1 else _t2 = false;
        _t2
    }
    friend fun is_lt(p0: &I64, p1: u64): bool {
        let _t2;
        if (*&p0.is_positive) _t2 = *&p0.amount < p1 else _t2 = true;
        _t2
    }
    friend fun add(p0: I64, p1: I64): I64 {
        add_inplace(&mut p0, p1);
        p0
    }
    friend fun add_inplace(p0: &mut I64, p1: I64) {
        let _t3;
        let _t2;
        let _t6 = *&p0.is_positive;
        let _t9 = *&(&p1).is_positive;
        if (_t6 == _t9) {
            _t2 = *&(&p1).amount;
            _t3 = &mut p0.amount;
            *_t3 = *_t3 + _t2
        } else {
            let _t23 = *&p0.amount;
            let _t26 = *&(&p1).amount;
            if (_t23 >= _t26) {
                _t2 = *&(&p1).amount;
                _t3 = &mut p0.amount;
                *_t3 = *_t3 - _t2;
                if (*&p0.amount == 0) {
                    let _t45 = &mut p0.is_positive;
                    *_t45 = true
                }
            } else {
                let _t49 = *&(&p1).amount;
                let _t52 = *&p0.amount;
                let _t53 = _t49 - _t52;
                let _t55 = &mut p0.amount;
                *_t55 = _t53;
                let _t58 = *&(&p1).is_positive;
                let _t60 = &mut p0.is_positive;
                *_t60 = _t58
            }
        };
    }
    friend fun is_zero(p0: &I64): bool {
        *&p0.amount == 0
    }
    friend fun max(p0: I64, p1: I64): I64 {
        let _t3;
        let _t2;
        if (*&(&p0).is_positive) _t2 = *&(&p1).is_positive else _t2 = false;
        loop {
            let _t4;
            if (_t2) {
                let _t14 = *&(&p0).amount;
                let _t17 = *&(&p1).amount;
                if (_t14 >= _t17) {
                    _t3 = p0;
                    break
                };
                _t3 = p1;
                break
            };
            if (*&(&p0).is_positive) _t4 = false else _t4 = !*&(&p1).is_positive;
            if (_t4) {
                let _t32 = *&(&p0).amount;
                let _t35 = *&(&p1).amount;
                if (_t32 <= _t35) {
                    _t3 = p0;
                    break
                };
                _t3 = p1;
                break
            };
            if (*&(&p0).is_positive) {
                _t3 = p0;
                break
            };
            _t3 = p1;
            break
        };
        _t3
    }
    friend fun sub(p0: I64, p1: I64): I64 {
        sub_inplace(&mut p0, p1);
        p0
    }
    friend fun sub_inplace(p0: &mut I64, p1: I64) {
        negative_inplace(&mut p1);
        add_inplace(p0, p1);
    }
    friend fun into_inner(p0: I64): (bool, u64) {
        let _t3 = *&(&p0).is_positive;
        let _t6 = *&(&p0).amount;
        (_t3, _t6)
    }
    friend fun is_gte(p0: &I64, p1: u64): bool {
        let _t2;
        if (*&p0.is_positive) _t2 = *&p0.amount >= p1 else _t2 = false;
        _t2
    }
    friend fun is_lte(p0: &I64, p1: u64): bool {
        let _t2;
        if (*&p0.is_positive) _t2 = *&p0.amount <= p1 else _t2 = true;
        _t2
    }
    friend fun is_negative(p0: &I64): bool {
        !*&p0.is_positive
    }
    friend fun is_positive_or_zero(p0: &I64): bool {
        *&p0.is_positive
    }
    friend fun is_strictly_positive(p0: &I64): bool {
        let _t1;
        if (*&p0.is_positive) _t1 = *&p0.amount > 0 else _t1 = false;
        _t1
    }
    friend fun mul_div_inplace(p0: &mut I64, p1: u64, p2: u64) {
        let _t3 = *&p0.amount;
        if (!(p2 != 0)) {
            let _t32 = error::invalid_argument(4);
            abort _t32
        };
        let _t11 = _t3 as u128;
        let _t13 = p1 as u128;
        let _t14 = _t11 * _t13;
        let _t16 = p2 as u128;
        let _t18 = (_t14 / _t16) as u64;
        let _t20 = &mut p0.amount;
        *_t20 = _t18;
        if (*&p0.amount == 0) {
            let _t28 = &mut p0.is_positive;
            *_t28 = true
        };
    }
    friend fun mul_inplace(p0: &mut I64, p1: u64) {
        let _t2 = &mut p0.amount;
        *_t2 = *_t2 * p1;
        if (*&p0.amount == 0) {
            let _t17 = &mut p0.is_positive;
            *_t17 = true
        };
    }
    friend fun negative(p0: &I64): I64 {
        let _t1;
        if (*&p0.amount > 0) {
            let _t10 = !*&p0.is_positive;
            let _t13 = *&p0.amount;
            _t1 = new(_t10, _t13)
        } else _t1 = zero();
        _t1
    }
    friend fun negative_inplace(p0: &mut I64) {
        if (*&p0.amount > 0) {
            let _t9 = !*&p0.is_positive;
            let _t11 = &mut p0.is_positive;
            *_t11 = _t9
        };
    }
    friend fun new_from_subtraction(p0: u64, p1: u64): I64 {
        let _t2;
        if (p0 >= p1) {
            let _t9 = p0 - p1;
            _t2 = I64{is_positive: true, amount: _t9}
        } else {
            let _t15 = p1 - p0;
            _t2 = I64{is_positive: false, amount: _t15}
        };
        _t2
    }
    friend fun new_negative(p0: u64): I64 {
        let _t1;
        if (p0 == 0) _t1 = zero() else _t1 = I64{is_positive: false, amount: p0};
        _t1
    }
    friend fun new_positive(p0: u64): I64 {
        I64{is_positive: true, amount: p0}
    }
    friend fun plus_is_less(p0: u64, p1: I64, p2: u64): bool {
        let _t3;
        if (*&(&p1).is_positive) {
            let _t8 = p0 as u128;
            let _t12 = (*&(&p1).amount) as u128;
            let _t13 = _t8 + _t12;
            let _t15 = p2 as u128;
            _t3 = _t13 < _t15
        } else {
            let _t19 = p0 as u128;
            let _t21 = p2 as u128;
            let _t25 = (*&(&p1).amount) as u128;
            let _t26 = _t21 + _t25;
            _t3 = _t19 < _t26
        };
        _t3
    }
    friend fun unwrap_or_zero(p0: option::Option<I64>): I64 {
        let _t1;
        if (option::is_none<I64>(&p0)) _t1 = zero() else _t1 = option::destroy_some<I64>(p0);
        _t1
    }
}
