# Autocap Mobile

Autocap Mobile is a cross‑platform mobile application built with **React Native** and packaged with a reproducible **Docker** toolchain.  
It offers advanced media processing capabilities — including video transcription with **Whisper** — in a compact, size‑optimized form.

---

## ✨ Features

- **Video transcription & subtitles** with Whisper  
  Packed and size‑reduced to meet mobile deployment constraints.
- **Subtitle burning** using FFmpeg directly from the device.
- **Offline‑ready media handling** via `react-native-fs`.
- **Deterministic builds** through pinned Docker image with JVM, Gradle, Android SDK, and NDK.
- **Font asset bundling** with React Native auto‑linking.

---

## 🧩 Engineering Highlights

### Whisper Integration & Size Reduction
Embedding Whisper on mobile requires significant optimization:
- Selective file inclusion in CMake to avoid unused source bloat.
- Stub fallbacks for builds where native code is unavailable.
- Output directory structuring for ABI‑specific JNI libraries.

This approach maintains accuracy while delivering a smaller binary footprint — crucial for mobile app store requirements.

---

### Scalable, Safe Build Environment
- Fully isolated via **Docker** for **CI/CD** pipelines.
- Pinning of Android SDK, NDK, CMake, Gradle wrapper, and JDK ensures reproducibility.
- No dependency on the developer's host environment — builds behave identically on local machines and in cloud agents.
    #### - CI/CD Workflow

Below is the GitHub Actions configuration we use to build the Android APK and AAB inside a deterministic Docker environment.

<!-- WORKFLOW:START -->
```yaml
# GitHub Actions configuration

```yaml
name: Build Android

on:
  push:
    branches: [ main ]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -t autocap-mobile .

      - name: Build APK & AAB
        run: |
          docker run --rm \
            -v ${{ github.workspace }}:/app \
            -v ${{ github.workspace }}/fonts:/app/fonts \
            autocap-mobile \
            bash -c "./scripts/build-release-apk.sh && ./scripts/build-release-aab.sh"

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: android-builds
          path: artifacts/
```
<!-- WORKFLOW:END -->

---

### Development Principles
- **OOP programming** for modular, maintainable code.
- **SOLID principles** applied in React Native modules and native bindings:
  - **S**ingle Responsibility: Separate modules for media handling, transcription, and UI.
  - **O**pen/Closed: Extend features without modifying stable core code.
  - **L**iskov Substitution: Common interfaces for interchangeable native stubs.
  - **I**nterface Segregation: Split native API surfaces by capability.
  - **D**ependency Inversion: High‑level JS modules depend on abstractions, not concretions.
- If integrated into a **Scrum** workflow, the architecture supports clear sprint deliverables (e.g., Whisper size reduction as a sprint goal).

---

## 🛠 Build System
- **Gradle** orchestrates Android builds via the project’s `gradlew` wrapper.
- **JVM** (Java 17) inside the container ensures compatibility with modern Android plugins.

---

## 🚀 Building

**One‑liner using Make**  
```bash
make release
