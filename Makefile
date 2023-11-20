build:
	make -C go-ethereum dev-station

.PHONY: universal xcframework clean

fat-libraries:
	make -C go-ethereum dev-station-fat

clean:
	rm -rf *.a *.xcframework

# https://rhonabwy.com/2023/02/10/creating-an-xcframework/
xcframework:
	rm -rf EVMBridgeLibrary.xcframework
	xcodebuild -create-xcframework \
-library libevm-bridge.a \
-headers EVMBridge \
-output EVMBridgeLibrary.xcframework

# Ask on swift forums why have to do it separately
# I think becuase the release is a symlink
universal: fat-binaries xcframework
	rm -rf .build
	swift build -c release --arch arm64
	sleep 5
	mv .build/arm64-apple-macosx/release/evm-dev-station .build/evm-dev-station-arm64
	swift build -c release --arch x86_64
	sleep 5
	mv .build/x86_64-apple-macosx/release/evm-dev-station .build/evm-dev-station-x86
	lipo -create -output evm-dev-station .build/evm-dev-station-x86 .build/evm-dev-station-arm64
	mv evm-dev-station ../evm-dev-station-binaries
