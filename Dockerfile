## FFMPEG + VMAF + AV1
FROM ubuntu

# environment
ENV PATH="${PATH}:/root/.local/bin"
ENV TZ=UTC

## Basic Setup
RUN apt-get update -qq && apt-get install -y build-essential git && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

## Base install
RUN apt-get install -y python3 python3-pip python3-setuptools python3-wheel ninja-build doxygen nasm && pip3 install --user meson && pip3 install --upgrade pip && pip3 install numpy scipy matplotlib notebook pandas sympy nose scikit-learn scikit-image h5py sureal

## VMAF
RUN git clone --depth 1 https://github.com/Netflix/vmaf.git vmaf && cd vmaf/libvmaf && meson build --buildtype release && ninja -vC build && ninja -vC build install

## FFMPEG Libraries
RUN cd && \
apt-get -y install \
autoconf \
  automake \
  build-essential \
  cmake \
  git-core \
  libass-dev \
  libfreetype6-dev \
  libsdl2-dev \
  libtool \
  libva-dev \
  libvdpau-dev \
  libvorbis-dev \
  libxcb1-dev \
  libxcb-shm0-dev \
  libxcb-xfixes0-dev \
  pkg-config \
  texinfo \
  wget \
  zlib1g-dev
RUN mkdir -p ~/ffmpeg_sources ~/bin

RUN cd
RUN apt-get install -y yasm libx264-dev libx265-dev libnuma-dev libvpx-dev libfdk-aac-dev libmp3lame-dev libopus-dev ocl-icd-opencl-dev libssl-dev -y

## AV1
RUN cd ~/ffmpeg_sources && \
git -C aom pull 2> /dev/null || git clone --depth 1 https://aomedia.googlesource.com/aom && \
mkdir -p aom_build && \
cd aom_build && \
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED=off -DENABLE_NASM=on ../aom && \
PATH="$HOME/bin:$PATH" make -j4 && \
make -j4 install

## FFMEPG
RUN cd ~/ffmpeg_sources && \
wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
tar xjvf ffmpeg-snapshot.tar.bz2 &&\
cd ffmpeg/ && \
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --extra-libs="-lpthread -lm" \
  --bindir="$HOME/bin" \
  --enable-gpl \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvmaf \
  --enable-version3 \
  --enable-opencl \
  --enable-openssl \
  --enable-libaom \
  --enable-nonfree && \
PATH="$HOME/bin:$PATH" make -j4 && \
make -j4 install && \
hash -r
RUN cd && \
cp bin/ff* /usr/local/bin

## Cleanup
RUN rm -rf ~/ff* && rm -rf /vmaf && rm -rf /ff*

WORKDIR /ffmpeg_working

ENTRYPOINT ["/usr/local/bin/ffmpeg"]
