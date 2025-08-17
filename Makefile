```make
release:
    docker build -t autocap-mobile . && \
    docker run --rm \
        -v $$(pwd):/app \
        -v $$(pwd)/fonts:/app/fonts \
        autocap-mobile \
# 		Appstore required bundles after testing enough the app:
#         bash -c "./scripts/build-release-apk.sh && ./scripts/build-release-aab.sh"
		bash -c "./scripts/build-release-apk.sh"