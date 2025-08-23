.RECIPEPREFIX := >
.PHONY: release clean ensure-model

MODEL_PATH := android/app/src/main/assets/models/ggml-small.bin
MODEL_URL  := https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin
MODEL_SHA1 :=  55356645c2b361a969dfd0ef2c5a50d530afd8d5
# ^ Replace with the actual SHA256 of the desired ggml-small.bin

# Ensure Whisper model exists and passes checksum
ensure-model:
> @mkdir -p $(dir $(MODEL_PATH))
> @if [ ! -f "$(MODEL_PATH)" ]; then \
>     echo "📥 Model not found. Downloading..."; \
>     curl -L $(MODEL_URL) -o $(MODEL_PATH); \
> fi
> @echo "🔍 Verifying model checksum..."
> @DOWNLOADED_SHA=$$(sha1sum "$(MODEL_PATH)" | awk '{print $$1}'); \
> if [ "$$DOWNLOADED_SHA" != "$(MODEL_SHA1)" ]; then \
>     echo "❌ Checksum mismatch. Re‑downloading..."; \
>     curl -L $(MODEL_URL) -o $(MODEL_PATH); \
>     echo "✔ Model re‑downloaded."; \
> else \
>     echo "✅ Checksum OK."; \
> fi

release: ensure-model
> docker build -t autocap-mobile . --no-cache
> docker run --rm \
>   -v $$(pwd):/app \
>   -v $$(pwd)/fonts:/app/fonts \
>   autocap-mobile \
>   bash -c "./scripts/build-release-apk.sh && ./scripts/build-release-aab.sh"

clean:
> rm -rf android/app/build artifacts $(MODEL_PATH)
