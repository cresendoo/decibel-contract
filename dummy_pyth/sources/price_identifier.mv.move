module 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::price_identifier {
    use 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95::error;
    struct PriceIdentifier has copy, drop, store {
        bytes: vector<u8>,
    }
    public fun from_byte_vec(p0: vector<u8>): PriceIdentifier {
        if (!(0x1::vector::length<u8>(&p0) == 32)) {
            let _t7 = error::incorrect_identifier_length();
            abort _t7
        };
        PriceIdentifier{bytes: p0}
    }
    public fun get_bytes(p0: &PriceIdentifier): vector<u8> {
        *&p0.bytes
    }
}
