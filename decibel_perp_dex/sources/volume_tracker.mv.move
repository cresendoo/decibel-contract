module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::volume_tracker {
    use 0x1::aggregator_v2;
    use 0x1::table;
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::decibel_time;
    use 0x1::vector;
    struct DayVolume has drop, store {
        day_since_epoch: u64,
        volume: u128,
    }
    struct VolumeHistory has drop, store {
        latest_day_since_epoch: u64,
        latest_day_volume: aggregator_v2::Aggregator<u128>,
        history: vector<DayVolume>,
        total_volume: u128,
    }
    struct VolumeStats has store {
        global_history: VolumeHistory,
        user_taker_volume_history: table::Table<address, VolumeHistory>,
        user_maker_volume_history: table::Table<address, VolumeHistory>,
    }
    public fun initialize(): VolumeStats {
        let _t2 = decibel_time::now_seconds() / 86400;
        let _t5 = aggregator_v2::create_aggregator_with_value<u128>(0u128, 340282366920938463463374607431768211455u128);
        let _t6 = vector::empty<DayVolume>();
        let _t8 = VolumeHistory{latest_day_since_epoch: _t2, latest_day_volume: _t5, history: _t6, total_volume: 0u128};
        let _t9 = table::new<address,VolumeHistory>();
        let _t10 = table::new<address,VolumeHistory>();
        VolumeStats{global_history: _t8, user_taker_volume_history: _t9, user_maker_volume_history: _t10}
    }
    public fun get_global_volume(p0: &mut VolumeStats): u128 {
        let _t1 = &mut p0.global_history;
        let _t2 = decibel_time::now_seconds() / 86400;
        let _t13 = *&_t1.latest_day_since_epoch;
        if (_t2 != _t13) {
            rollover_volume_history(_t1);
            let _t3 = aggregator_v2::read<u128>(&_t1.latest_day_volume);
            if (!aggregator_v2::try_sub<u128>(&mut _t1.latest_day_volume, _t3)) abort 3;
            let _t4 = &mut _t1.latest_day_since_epoch;
            *_t4 = _t2
        };
        *&(&p0.global_history).total_volume
    }
    fun rollover_volume_history(p0: &mut VolumeHistory) {
        let _t1 = decibel_time::now_seconds() / 86400;
        let _t9 = &mut p0.history;
        let _t12 = *&p0.latest_day_since_epoch;
        let _t15 = aggregator_v2::read<u128>(&p0.latest_day_volume);
        let _t16 = DayVolume{day_since_epoch: _t12, volume: _t15};
        vector::push_back<DayVolume>(_t9, _t16);
        let _t2 = aggregator_v2::read<u128>(&p0.latest_day_volume);
        let _t3 = &mut p0.total_volume;
        *_t3 = *_t3 + _t2;
        let _t4 = 0;
        loop {
            let _t31 = vector::length<DayVolume>(&p0.history);
            if (!(_t4 < _t31)) break;
            let _t38 = *&vector::borrow<DayVolume>(&p0.history, _t4).day_since_epoch;
            let _t41 = _t1 - 14;
            if (_t38 < _t41) {
                _t2 = *&vector::borrow<DayVolume>(&p0.history, _t4).volume;
                _t3 = &mut p0.total_volume;
                *_t3 = *_t3 - _t2;
                let _t59 = vector::swap_remove<DayVolume>(&mut p0.history, _t4);
                continue
            };
            _t4 = _t4 + 1;
            continue
        };
    }
    public fun get_maker_volume(p0: &mut VolumeStats, p1: address): u128 {
        let _t2;
        if (table::contains<address,VolumeHistory>(&p0.user_maker_volume_history, p1)) {
            _t2 = table::borrow_mut<address,VolumeHistory>(&mut p0.user_maker_volume_history, p1);
            let _t3 = _t2;
            let _t4 = decibel_time::now_seconds() / 86400;
            let _t24 = *&_t3.latest_day_since_epoch;
            if (_t4 != _t24) {
                rollover_volume_history(_t3);
                let _t5 = aggregator_v2::read<u128>(&_t3.latest_day_volume);
                if (!aggregator_v2::try_sub<u128>(&mut _t3.latest_day_volume, _t5)) abort 3;
                let _t6 = &mut _t3.latest_day_since_epoch;
                *_t6 = _t4
            }
        } else return 0u128;
        *&_t2.total_volume
    }
    public fun get_taker_volume(p0: &mut VolumeStats, p1: address): u128 {
        let _t2;
        if (table::contains<address,VolumeHistory>(&p0.user_taker_volume_history, p1)) {
            _t2 = table::borrow_mut<address,VolumeHistory>(&mut p0.user_taker_volume_history, p1);
            let _t3 = _t2;
            let _t4 = decibel_time::now_seconds() / 86400;
            let _t24 = *&_t3.latest_day_since_epoch;
            if (_t4 != _t24) {
                rollover_volume_history(_t3);
                let _t5 = aggregator_v2::read<u128>(&_t3.latest_day_volume);
                if (!aggregator_v2::try_sub<u128>(&mut _t3.latest_day_volume, _t5)) abort 3;
                let _t6 = &mut _t3.latest_day_since_epoch;
                *_t6 = _t4
            }
        } else return 0u128;
        *&_t2.total_volume
    }
    public fun track_maker_and_global_volume(p0: &mut VolumeStats, p1: address, p2: u128) {
        let _t7;
        let _t6;
        let _t3 = &mut p0.global_history;
        let _t4 = p2;
        let _t5 = decibel_time::now_seconds() / 86400;
        let _t22 = *&_t3.latest_day_since_epoch;
        if (_t5 != _t22) {
            rollover_volume_history(_t3);
            _t6 = aggregator_v2::read<u128>(&_t3.latest_day_volume);
            if (!aggregator_v2::try_sub<u128>(&mut _t3.latest_day_volume, _t6)) abort 3;
            _t7 = &mut _t3.latest_day_since_epoch;
            *_t7 = _t5
        };
        if (_t4 > 0u128) aggregator_v2::add<u128>(&mut _t3.latest_day_volume, _t4);
        let _t8 = &mut p0.user_maker_volume_history;
        let _t9 = p1;
        if (!table::contains<address,VolumeHistory>(freeze(_t8), _t9)) {
            let _t53 = decibel_time::now_seconds() / 86400;
            let _t56 = aggregator_v2::create_aggregator_with_value<u128>(0u128, 340282366920938463463374607431768211455u128);
            let _t57 = vector::empty<DayVolume>();
            let _t59 = VolumeHistory{latest_day_since_epoch: _t53, latest_day_volume: _t56, history: _t57, total_volume: 0u128};
            table::add<address,VolumeHistory>(_t8, _t9, _t59)
        };
        let _t10 = table::borrow_mut<address,VolumeHistory>(_t8, _t9);
        _t6 = p2;
        let _t11 = decibel_time::now_seconds() / 86400;
        let _t70 = *&_t10.latest_day_since_epoch;
        if (_t11 != _t70) {
            rollover_volume_history(_t10);
            let _t12 = aggregator_v2::read<u128>(&_t10.latest_day_volume);
            if (!aggregator_v2::try_sub<u128>(&mut _t10.latest_day_volume, _t12)) abort 3;
            _t7 = &mut _t10.latest_day_since_epoch;
            *_t7 = _t11
        };
        if (_t6 > 0u128) aggregator_v2::add<u128>(&mut _t10.latest_day_volume, _t6);
    }
    public fun track_taker_volume(p0: &mut VolumeStats, p1: address, p2: u128) {
        let _t3 = &mut p0.user_taker_volume_history;
        if (!table::contains<address,VolumeHistory>(freeze(_t3), p1)) {
            let _t18 = decibel_time::now_seconds() / 86400;
            let _t21 = aggregator_v2::create_aggregator_with_value<u128>(0u128, 340282366920938463463374607431768211455u128);
            let _t22 = vector::empty<DayVolume>();
            let _t24 = VolumeHistory{latest_day_since_epoch: _t18, latest_day_volume: _t21, history: _t22, total_volume: 0u128};
            table::add<address,VolumeHistory>(_t3, p1, _t24)
        };
        let _t4 = table::borrow_mut<address,VolumeHistory>(_t3, p1);
        let _t5 = decibel_time::now_seconds() / 86400;
        let _t34 = *&_t4.latest_day_since_epoch;
        if (_t5 != _t34) {
            rollover_volume_history(_t4);
            let _t6 = aggregator_v2::read<u128>(&_t4.latest_day_volume);
            if (!aggregator_v2::try_sub<u128>(&mut _t4.latest_day_volume, _t6)) abort 3;
            let _t7 = &mut _t4.latest_day_since_epoch;
            *_t7 = _t5
        };
        if (p2 > 0u128) aggregator_v2::add<u128>(&mut _t4.latest_day_volume, p2);
    }
    public fun track_volume(p0: &mut VolumeStats, p1: address, p2: address, p3: u128) {
        let _t13;
        let _t8;
        let _t7;
        let _t4 = &mut p0.global_history;
        let _t5 = p3;
        let _t6 = decibel_time::now_seconds() / 86400;
        let _t26 = *&_t4.latest_day_since_epoch;
        if (_t6 != _t26) {
            rollover_volume_history(_t4);
            _t7 = aggregator_v2::read<u128>(&_t4.latest_day_volume);
            if (!aggregator_v2::try_sub<u128>(&mut _t4.latest_day_volume, _t7)) abort 3;
            _t8 = &mut _t4.latest_day_since_epoch;
            *_t8 = _t6
        };
        if (_t5 > 0u128) aggregator_v2::add<u128>(&mut _t4.latest_day_volume, _t5);
        let _t9 = &mut p0.user_taker_volume_history;
        let _t10 = p2;
        if (!table::contains<address,VolumeHistory>(freeze(_t9), _t10)) {
            let _t57 = decibel_time::now_seconds() / 86400;
            let _t60 = aggregator_v2::create_aggregator_with_value<u128>(0u128, 340282366920938463463374607431768211455u128);
            let _t61 = vector::empty<DayVolume>();
            let _t63 = VolumeHistory{latest_day_since_epoch: _t57, latest_day_volume: _t60, history: _t61, total_volume: 0u128};
            table::add<address,VolumeHistory>(_t9, _t10, _t63)
        };
        let _t11 = table::borrow_mut<address,VolumeHistory>(_t9, _t10);
        _t7 = p3;
        let _t12 = decibel_time::now_seconds() / 86400;
        let _t74 = *&_t11.latest_day_since_epoch;
        if (_t12 != _t74) {
            rollover_volume_history(_t11);
            _t13 = aggregator_v2::read<u128>(&_t11.latest_day_volume);
            if (!aggregator_v2::try_sub<u128>(&mut _t11.latest_day_volume, _t13)) abort 3;
            _t8 = &mut _t11.latest_day_since_epoch;
            *_t8 = _t12
        };
        if (_t7 > 0u128) aggregator_v2::add<u128>(&mut _t11.latest_day_volume, _t7);
        _t9 = &mut p0.user_maker_volume_history;
        _t10 = p1;
        if (!table::contains<address,VolumeHistory>(freeze(_t9), _t10)) {
            let _t105 = decibel_time::now_seconds() / 86400;
            let _t108 = aggregator_v2::create_aggregator_with_value<u128>(0u128, 340282366920938463463374607431768211455u128);
            let _t109 = vector::empty<DayVolume>();
            let _t111 = VolumeHistory{latest_day_since_epoch: _t105, latest_day_volume: _t108, history: _t109, total_volume: 0u128};
            table::add<address,VolumeHistory>(_t9, _t10, _t111)
        };
        let _t14 = table::borrow_mut<address,VolumeHistory>(_t9, _t10);
        _t13 = p3;
        let _t15 = decibel_time::now_seconds() / 86400;
        let _t122 = *&_t14.latest_day_since_epoch;
        if (_t15 != _t122) {
            rollover_volume_history(_t14);
            let _t16 = aggregator_v2::read<u128>(&_t14.latest_day_volume);
            if (!aggregator_v2::try_sub<u128>(&mut _t14.latest_day_volume, _t16)) abort 3;
            _t8 = &mut _t14.latest_day_since_epoch;
            *_t8 = _t15
        };
        if (_t13 > 0u128) aggregator_v2::add<u128>(&mut _t14.latest_day_volume, _t13);
    }
}
