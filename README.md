# Decibel


## Decompile
```bash
aptos init # rest url: https://api.netna.staging.aptoslabs.com/v1
aptos move download --account 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95 --package decibel_perp_dex -b
aptos move decompile --package-path decibel_perp_dex/bytecode_modules --decompiler-version v2 --output-dir decibel_perp_dex/sources
aptos move download --account 0xb8a5788314451ce4d2fbbad32e1bad88d4184b73943b7fe5166eab93cf1a5a95 --package dummy_pyth -b
aptos move decompile --package-path dummy_pyth/bytecode_modules --decompiler-version v2 --output-dir dummy_pyth/sources
```

## Package Compile
```bash
aptos move compile --package-dir dummy_pyth --named-addresses decibel_dex=0x4e110 --compiler-version v2
aptos move compile --package-dir decibel_perp_dex --named-addresses decibel_dex=0x4e110 --compiler-version v2
```