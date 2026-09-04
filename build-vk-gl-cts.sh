#!/bin/bash

export WORKSPACE=`pwd`
test_apis="$1"

cd $WORKSPACE

# Download android-studio tool
wget https://dl.google.com/dl/android/studio/ide-zips/2025.2.1.8/android-studio-2025.2.1.8-linux.tar.gz
tar -xvzf android-studio-2025.2.1.8-linux.tar.gz

# Download commandline tool
wget https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip
unzip commandlinetools-linux-13114758_latest.zip

# Download Android NDK (r27)
wget https://dl.google.com/android/repository/android-ndk-r27d-linux.zip
unzip android-ndk-r27d-linux.zip

# Install SDK Build Tools
./cmdline-tools/bin/sdkmanager --sdk_root=${WORKSPACE}/android-studio "build-tools;34.0.0"

# Install SDK Platform Tools
./cmdline-tools/bin/sdkmanager --sdk_root=${WORKSPACE}/android-studio "platforms;android-34"

# Install CMake 3.22.1
./cmdline-tools/bin/sdkmanager --sdk_root=${WORKSPACE}/android-studio "cmake;3.22.1"

# Buiding CTS
python3 external/fetch_sources.py

# Run the Vulkan CTS video decode or encode tests
python3 external/fetch_video_decode_samples.py
python3 external/fetch_video_encode_samples.py

# Export JDK 17
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Delete build cache
find . -name CMakeCache.txt -delete
find . -name CMakeFiles -type d -exec rm -rf {} +

# Android: Build type app
case "$test_apis" in
    vulkancts)
        echo "Build Vulkan CTS tests"
        python3 scripts/android/build_apk.py --sdk ${WORKSPACE}/android-studio --ndk ${WORKSPACE}/android-ndk-r27d --abis arm64-v8a
        ;;
    openglcts)
        echo "Build OpenGL CTS tests"
        python scripts/android/build_apk.py --target=openglcts --sdk ${WORKSPACE}/android-studio --ndk ${WORKSPACE}/android-ndk-r27d --abis arm64-v8a
        ;;
    *)
        echo "No conformance tests"
        ;;
esac
