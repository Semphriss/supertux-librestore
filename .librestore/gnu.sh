#!/usr/bin/env bash

set -e
cd $(dirname $0)/..
DESTDIR="$(realpath "$1")"

if [ ! -d "$DESTDIR" ]; then
  echo "path '$DESTDIR' is not a valid folder"
  exit 1
fi

# Install dependencies
git clone https://github.com/microsoft/vcpkg || true
./vcpkg/bootstrap-vcpkg.sh -disableMetrics
./vcpkg/vcpkg integrate install
./vcpkg/vcpkg install boost-date-time:x64-linux                                \
                      boost-filesystem:x64-linux                               \
                      boost-format:x64-linux                                   \
                      boost-locale:x64-linux                                   \
                      boost-optional:x64-linux                                 \
                      boost-system:x64-linux                                   \
                      curl:x64-linux                                           \
                      --recurse freetype:x64-linux                             \
                      glew:x64-linux                                           \
                      libogg:x64-linux                                         \
                      libpng:x64-linux                                         \
                      libraqm:x64-linux                                        \
                      libvorbis:x64-linux                                      \
                      openal-soft:x64-linux                                    \
                      sdl2:x64-linux                                           \
                      sdl2-image:x64-linux                                     \
                      glm:x64-linux

# Fetch repo
git clone https://github.com/supertux/supertux || true
cd supertux/
if [ ! "$LIBRESTORE_CHECKOUT" = "" ]; then
  git fetch
  git checkout $LIBRESTORE_CHECKOUT
fi

# Build
git submodule update --init --recursive
mkdir -p build.gnu2
cd build.gnu2
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=../../vcpkg/scripts/buildsystems/vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x64-linux -DVCPKG_BUILD=ON ..
make -j$(nproc)
cpack -G STGZ

# Move artifacts
OUTPUT=$(ls SuperTux*.sh | head -1)
mv -u $OUTPUT "$DESTDIR"

# Prepare install and launch scripts
echo "#!/usr/bin/env bash" > "$DESTDIR/install.sh"
echo "set -e" >> "$DESTDIR/install.sh"
echo "\$(dirname \"\$0\")/$OUTPUT --skip-license --exclude-subdir --prefix=\$1" >> "$DESTDIR/install.sh"
echo "cp \$(dirname \"\$0\")/run.sh \$1" >> "$DESTDIR/install.sh"
chmod +x "$DESTDIR/install.sh"

echo "#!/usr/bin/env bash" > "$DESTDIR/run.sh"
echo "set -e" >> "$DESTDIR/run.sh"
echo "\$(dirname \"\$0\")/games/supertux2 --datadir \$(dirname \"\$0\")/share/games/supertux2 --userdir \$1" >> "$DESTDIR/run.sh"
chmod +x "$DESTDIR/run.sh"

