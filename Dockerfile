# syntax=docker/dockerfile:1.7

############################################
# 1) Base toolchain image
############################################
FROM eclipse-temurin:17-jdk-jammy AS toolchain

# Pinned versions for determinism
ARG NODE_VER=18.20.3
ARG ANDROID_SDK_VERSION=11076708
ARG ANDROID_PLATFORM=android-34
ARG ANDROID_BUILD_TOOLS=34.0.0
ARG ANDROID_NDK_VERSION=25.2.9519653
ARG CMAKE_VERSION=3.22.1

ENV DEBIAN_FRONTEND=noninteractive \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    ANDROID_HOME=/opt/android-sdk \
    GRADLE_USER_HOME=/opt/.gradle

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl unzip wget xz-utils python3 make cmake ninja-build build-essential \
    ca-certificates locales gnupg && \
    rm -rf /var/lib/apt/lists/*

# Node & Yarn (pinned)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get update && apt-get install -y nodejs && \
    npm i -g yarn@1.22.22

# Android SDK (cmdline-tools)
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget -O /tmp/cmdline-tools.zip \
      https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip && \
    unzip /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

ENV PATH=$PATH:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator

# Accept licenses and install components
RUN yes | sdkmanager --licenses
RUN sdkmanager \
  "platform-tools" \
  "platforms;${ANDROID_PLATFORM}" \
  "build-tools;${ANDROID_BUILD_TOOLS}" \
  "ndk;${ANDROID_NDK_VERSION}" \
  "cmake;${CMAKE_VERSION}"

# Non-root user for builds
RUN useradd -ms /bin/bash builder && mkdir -p /home/builder && chown -R builder:builder /home/builder /opt/.gradle
USER builder
WORKDIR /app

############################################
# 2) Build dependencies (JS + Gradle caches)
############################################
FROM toolchain AS deps
COPY --chown=builder:builder package.json yarn.lock .
RUN yarn install --frozen-lockfile --production=false

# Pre-warm Gradle wrapper & caches (copy minimal android files)
COPY --chown=builder:builder android/gradle android/gradle
COPY --chown=builder:builder android/gradle.properties android/gradle.properties
COPY --chown=builder:builder android/gradlew android/gradlew
RUN chmod +x android/gradlew && mkdir -p android/.gradle

############################################
# 3) App build stage (release)
############################################
FROM deps AS build
# Copy whole project for deterministic build
COPY --chown=builder:builder . .
RUN chmod +x scripts/*.sh

# Optional: put user-provided fonts into assets for release builds
RUN mkdir -p android/app/src/main/assets/fonts && \
    if [ -d "fonts" ]; then cp -r fonts/* android/app/src/main/assets/fonts/ || true; fi

# Build release AAB/APK (signing handled by env/gradle if provided)
ARG BUILD_VARIANT=Release
ENV BUILD_VARIANT=${BUILD_VARIANT}

# Build bundle (AAB) and APK to /app/artifacts
RUN mkdir -p artifacts && \
    bash scripts/build-release-aab.sh && \
    bash scripts/build-release-apk.sh && \
    ls -lah artifacts

############################################
# 4) Minimal artifact image (optional for CI artifacts)
############################################
FROM scratch AS artifact
COPY --from=build /app/artifacts /