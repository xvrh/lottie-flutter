PUB_CACHE="$(mktemp -d)"
export PUB_CACHE
COPY_DIR="$(mktemp -d)"

(cd /build && git ls-files | xargs -I '{}' cp -pR --parents '{}' "$COPY_DIR")
cd "$COPY_DIR" || exit
flutter test --update-goldens test
cp -pR test/* /build/test

cd example || exit
flutter test --update-goldens test
cp -pR test/* /build/example/test
