build:
	make -C go-ethereum dev-station

.PHONY: universal

# Ask on swift forums why have to do it separately
# I think becuase the release is a symlink
universal:
	make -C go-ethereum dev-station-fat
	rm -rf .build
	swift build -c release --arch arm64
	sleep 5
	mv .build/arm64-apple-macosx/release/evm-dev-station .build/evm-dev-station-arm64
	swift build -c release --arch x86_64
	sleep 5
	mv .build/x86_64-apple-macosx/release/evm-dev-station .build/evm-dev-station-x86
	lipo -create -output evm-dev-station .build/evm-dev-station-x86 .build/evm-dev-station-arm64
	mv evm-dev-station ../evm-dev-station-binaries
