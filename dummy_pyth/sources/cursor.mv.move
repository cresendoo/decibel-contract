module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::cursor {
    use 0x1::vector;
    struct Cursor<T0> {
        data: vector<T0>,
    }
    public fun destroy_empty<T0>(p0: Cursor<T0>) {
        let Cursor<T0>{data: _t2} = p0;
        vector::destroy_empty<T0>(_t2);
    }
    public fun init<T0>(p0: vector<T0>): Cursor<T0> {
        vector::reverse<T0>(&mut p0);
        Cursor<T0>{data: p0}
    }
    public fun rest<T0>(p0: Cursor<T0>): vector<T0> {
        let Cursor<T0>{data: _t3} = p0;
        let _t1 = _t3;
        vector::reverse<T0>(&mut _t1);
        _t1
    }
    public fun poke<T0>(p0: &mut Cursor<T0>): T0 {
        vector::pop_back<T0>(&mut p0.data)
    }
}
