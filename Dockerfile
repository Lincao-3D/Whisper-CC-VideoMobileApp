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

COPY --chown=builder:builder \
     package.json yarn.lock* .yarnrc.yml .yarn/ ./

# bootstrap pinned Yarn binary
RUN if [ ! -f .yarn/releases/yarn-3.2.0.cjs ]; then \
      mkdir -p .yarn/releases && \
      curl -fsSLo .yarn/releases/yarn-3.2.0.cjs \
           https://repo.yarnpkg.com/3.2.0/packages/yarnpkg-cli/bin/yarn.js; \
    fi

# install exactly as locked
RUN --mount=type=cache,target=/home/builder/.cache/yarn \
    --mount=type=cache,target=/home/builder/.npm \
    yarn install --immutable

# sanity checks (using yarn why instead of yarn list)
RUN yarn config get nodeLinker \
    && yarn why react-native \
    && test -d node_modules/react-native/android \
    && ls -la node_modules/react-native/android


############################################
# 3) Build app
############################################
FROM toolchain AS build

USER builder
WORKDIR /app

# 1) Bring in the full JS install (with node_modules + plugin)
COPY --from=deps --chown=builder:builder /app /app

# 2) Copy your native sources
COPY --chown=builder:builder ./android /app/android
COPY --chown=builder:builder ./app     /app/app
COPY --chown=builder:builder ./scripts /app/scripts
COPY --chown=builder:builder ./package.json /app/package.json

# MODIFIED: Replace the symbolic link with a direct copy
# This ensures Gradle can find the directory.
COPY --from=deps --chown=builder:builder /app/node_modules/@react-native/gradle-plugin /app/node_modules/react-native-gradle-plugin

# 4) Patch the wrapper to pull Gradle 8.1.1 instead of the old 8.0
RUN sed -i \
  's@^distributionUrl=.*@distributionUrl=https\://services.gradle.org/distributions/gradle-8.1.1-all.zip@' \
  android/gradle/wrapper/gradle-wrapper.properties

WORKDIR /app/android

# 5) Ensure the wrapper is executable
RUN chmod +x gradlew

# 6) Clean & build with the now-fixed wrapper
RUN ./gradlew clean --no-daemon --stacktrace --info

# AAB
RUN --mount=type=cache,target=/home/builder/.gradle/wrapper,uid=1000,gid=1000,mode=0775 \
    --mount=type=cache,target=/home/builder/.gradle/caches,uid=1000,gid=1000,mode=0775 \
    --mount=type=cache,target=/opt/android-sdk/.android/cache,uid=1000,gid=1000,mode=0775 \
    ./gradlew --no-daemon --stacktrace --info :app:bundleRelease

# APK
RUN --mount=type=cache,target=/home/builder/.gradle/wrapper,uid=1000,gid=1000,mode=0775 \
    --mount=type=cache,target=/home/builder/.gradle/caches,uid=1000,gid=1000,mode=0775 \
    --mount=type=cache,target=/opt/android-sdk/.android/cache,uid=1000,gid=1000,mode=0775 \
    ./gradlew --no-daemon --stacktrace --info :app:assembleRelease

# 7) Collect artifacts
RUN mkdir -p /app/android/artifacts \
    && cp app/build/outputs/bundle/release/*.aab /app/android/artifacts/ \
    && cp app/build/outputs/apk/release/*.apk    /app/android/artifacts/

# Optional: dump daemon logs
RUN find /home/builder/.gradle/daemon -type f -name 'daemon-*.out.log' \
      -exec sh -c 'echo "=== {} ==="; tail -n +1 "{}"' \; || true

# Inspect
RUN ls -lah /app/android/artifacts



############################################
# 4) Final artifacts
############################################
FROM scratch AS artifact
COPY --from=build /app/android/artifacts /artifacts
