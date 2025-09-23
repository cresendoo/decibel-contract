module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::decibel_time {
    use 0x1::option;
    use 0x1::timestamp;
    use 0x1::signer;
    struct TimeOverride has key {
        time_us: option::Option<u64>,
    }
    public fun now_microseconds(): u64
        acquires TimeOverride
    {
        if (exists<TimeOverride>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) {
            let _t0 = borrow_global<TimeOverride>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95);
            if (option::is_some<u64>(&_t0.time_us)) return *option::borrow<u64>(&_t0.time_us)
        };
        timestamp::now_microseconds()
    }
    public fun now_seconds(): u64
        acquires TimeOverride
    {
        now_microseconds() / 1000000
    }
    fun init_module(p0: &signer) {
        let _t3 = TimeOverride{time_us: option::none<u64>()};
        move_to<TimeOverride>(p0, _t3);
    }
    entry fun increment_time(p0: &signer)
        acquires TimeOverride
    {
        if (!(signer::address_of(p0) == @0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95)) abort 0;
        let _t8 = option::some<u64>(now_microseconds() + 1);
        let _t11 = &mut borrow_global_mut<TimeOverride>(@0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95).time_us;
        *_t11 = _t8;
    }
}
