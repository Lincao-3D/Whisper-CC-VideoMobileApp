# syntax=docker/dockerfile:1.7

############################################
# 1) Toolchain base (OpenJDK 17 slim)
############################################
FROM openjdk:17-jdk-slim AS toolchain

ARG DEBIAN_FRONTEND=noninteractive
ARG ANDROID_SDK_VERSION=13114758
ARG ANDROID_PLATFORM=android-34
ARG ANDROID_BUILD_TOOLS=34.0.0
ARG ANDROID_NDK_VERSION=25.2.9519653
ARG CMAKE_VERSION=3.22.1
ARG NODE_VERSION=18.20.8

ENV ANDROID_SDK_ROOT=/opt/android-sdk \
    ANDROID_HOME=/opt/android-sdk \
    GRADLE_USER_HOME=/home/builder/.gradle \
    PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl wget unzip zip git bash coreutils findutils \
      make cmake ninja-build python3 xz-utils dumb-init \
    && rm -rf /var/lib/apt/lists/*

# Node + Yarn (Berry)
RUN cd /tmp && \
    wget -O node.tar.gz "https://nodejs.org/dist/latest-v18.x/node-v${NODE_VERSION}-linux-x64.tar.gz" && \
    echo "27a9f3f14d5e99ad05a07ed3524ba3ee92f8ff8b6db5ff80b00f9feb5ec8097a  node.tar.gz" | sha256sum -c - && \
    tar -xf node.tar.gz -C /usr/local --strip-components=1 && rm -f node.tar.gz && \
    corepack enable && corepack prepare yarn@3.2.0 --activate

ENV CMDLINE_TOOLS_ZIP=commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip

# Android SDK commandline tools
RUN mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools" && \
    cd /tmp && \
    wget -O "${CMDLINE_TOOLS_ZIP}" "https://dl.google.com/android/repository/${CMDLINE_TOOLS_ZIP}" && \
    unzip -qo "${CMDLINE_TOOLS_ZIP}" -d "${ANDROID_SDK_ROOT}/cmdline-tools" && \
    mv "${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools" "${ANDROID_SDK_ROOT}/cmdline-tools/latest" && \
    rm -f "${CMDLINE_TOOLS_ZIP}"

# Non-root user
RUN useradd -ms /bin/bash builder && \
    mkdir -p /home/builder/.gradle /home/builder/.android /home/builder/.cache && \
    chown -R builder:builder /home/builder

USER builder
WORKDIR /app

# Accept licenses
RUN --mount=type=cache,target=/home/builder/.android/cache \
    set +o pipefail && sdkmanager --sdk_root="${ANDROID_SDK_ROOT}" --licenses

# Install required SDK components
RUN --mount=type=cache,target=/opt/android-sdk/.android/cache \
    sdkmanager --sdk_root="${ANDROID_SDK_ROOT}" \
      "platform-tools" \
      "platforms;${ANDROID_PLATFORM}" \
      "build-tools;${ANDROID_BUILD_TOOLS}" \
      "ndk;${ANDROID_NDK_VERSION}" \
      "cmake;${CMAKE_VERSION}"

############################################
# 2) JS dependencies (cache-friendly)
############################################
FROM toolchain AS deps

USER builder
WORKDIR /app

# Copy package files + Yarn configs (including your .yarnrc.yml)
COPY --chown=builder:builder package.json yarn.lock* .yarnrc.yml .yarn/ ./

# Ensure the pinned Yarn binary exists where yarnPath expects it
# (handles cases where .yarn/releases is missing or .dockerignore filtered it)
RUN if [ ! -f .yarn/releases/yarn-3.2.0.cjs ]; then \
      mkdir -p .yarn/releases && \
      curl -fsSLo .yarn/releases/yarn-3.2.0.cjs \
        https://repo.yarnpkg.com/3.2.0/packages/yarnpkg-cli/bin/yarn.js; \
    fi

# Optional: quick sanity
RUN node --version && node .yarn/releases/yarn-3.2.0.cjs --version

# Install deps (no --immutable while you’re iterating)
RUN --mount=type=cache,target=/home/builder/.cache/yarn \
    --mount=type=cache,target=/home/builder/.npm \
    --mount=type=cache,target=/home/builder/.config/yarn \
    yarn install

# Sanity checks to guarantee RN Android folder exists
RUN yarn list --pattern '^react-native$' || true
RUN test -d node_modules/react-native/android && ls -la node_modules/react-native/android

############################################
# 3) Build app
############################################
FROM toolchain AS build

USER builder
WORKDIR /app

# Bring in node_modules and lockfiles from deps stage first (best cache hit)
COPY --from=deps --chown=builder:builder /app /app

# Now copy the app sources
COPY --chown=builder:builder ./android /app/android
COPY --chown=builder:builder ./app /app/app
COPY --chown=builder:builder ./scripts /app/scripts
COPY --chown=builder:builder ./package.json /app/package.json
# If you have metro/babel/ts configs etc., copy them as needed:
# COPY --chown=builder:builder ./babel.config.js ./metro.config.js ./tsconfig.json /app/

WORKDIR /app/android

# Ensure wrapper is executable
RUN chmod +x gradlew

# Clean and ensure wrapper present (optional: keep your project’s Gradle version)
RUN ./gradlew clean --no-daemon --stacktrace --info
# RUN ./gradlew wrapper --gradle-version 8.1.1 --distribution-type all

# Build AAB
RUN --mount=type=cache,target=/home/builder/.gradle/wrapper,uid=1000,gid=1000,mode=0775 \
    --mount=type=cache,target=/home/builder/.gradle/caches,uid=1000,gid=1000,mode=0775 \
    --mount=type=cache,target=/opt/android-sdk/.android/cache,uid=1000,gid=1000,mode=0775 \
    ./gradlew --no-daemon --stacktrace --info :app:bundleRelease

# Build APK
RUN --mount=type=cache,target=/home/builder/.gradle/wrapper,uid=1000,gid=1000,mode=0775 \
    --mount=type=cache,target=/home/builder/.gradle/caches,uid=1000,gid=1000,mode=0775 \
    --mount=type=cache,target=/opt/android-sdk/.android/cache,uid=1000,gid=1000,mode=0775 \
    ./gradlew --no-daemon --stacktrace --info :app:assembleRelease

# Collect artifacts consistently under /app/android/artifacts
RUN mkdir -p /app/android/artifacts \
    && cp app/build/outputs/bundle/release/*.aab /app/android/artifacts/ \
    && cp app/build/outputs/apk/release/*.apk /app/android/artifacts/

# Show Gradle daemon logs if present (non-fatal)
RUN find /home/builder/.gradle/daemon -type f -name 'daemon-*.out.log' \
      -exec sh -c 'echo "=== {} ==="; tail -n +1 "{}"' \; || true

# Inspect artifacts
RUN ls -lah /app/android/artifacts

############################################
# 4) Final artifacts
############################################
FROM scratch AS artifact
COPY --from=build /app/android/artifacts /artifacts
