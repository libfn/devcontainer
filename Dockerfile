ARG CODENAME=bookworm
ARG GCC_RELEASE=14
ARG GCC_DIST=${GCC_RELEASE}-${CODENAME}
FROM gcc:${GCC_DIST} AS gcc
RUN set -ex ;\
    find /usr/local/ -type f ;\
    cat /etc/ld.so.conf.d/000-local-lib.conf ;\
    cat /etc/os-release ;\
    /usr/local/bin/gcc --version

ARG CODENAME=bookworm
FROM debian:${CODENAME}
COPY --from=gcc /usr/local/ /usr/local/

WORKDIR /root
RUN set -ex ;\
    echo '/usr/local/lib64' > /etc/ld.so.conf.d/000-local-lib.conf; \
    echo '/usr/local/lib' >> /etc/ld.so.conf.d/000-local-lib.conf; \
    ldconfig -v ;\
    dpkg-divert --divert /usr/bin/gcc.orig --rename /usr/bin/gcc ;\
    dpkg-divert --divert /usr/bin/g++.orig --rename /usr/bin/g++ ;\
    dpkg-divert --divert /usr/bin/gfortran.orig --rename /usr/bin/gfortran ;\
    update-alternatives --install /usr/bin/cc cc /usr/local/bin/gcc 999 ;\
    update-alternatives --install \
      /usr/bin/gcc gcc /usr/local/bin/gcc 100 \
      --slave /usr/bin/g++ g++ /usr/local/bin/g++ \
      --slave /usr/bin/gcc-ar gcc-ar /usr/local/bin/gcc-ar \
      --slave /usr/bin/gcc-nm gcc-nm /usr/local/bin/gcc-nm \
      --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/local/bin/gcc-ranlib \
      --slave /usr/bin/gcov gcov /usr/local/bin/gcov \
      --slave /usr/bin/gcov-tool gcov-tool /usr/local/bin/gcov-tool \
      --slave /usr/bin/gcov-dump gcov-dump /usr/local/bin/gcov-dump \
      --slave /usr/bin/lto-dump lto-dump /usr/local/bin/lto-dump ;\
      update-alternatives --auto cc ;\
      update-alternatives --auto gcc

ARG CLANG_RELEASE=19
RUN set -ex ;\
    DEBIAN_FRONTEND=noninteractive ;\
    CODENAME=$( . /etc/os-release && echo $VERSION_CODENAME ) ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends ca-certificates wget gpg ;\
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /etc/apt/keyrings/llvm.gpg ;\
    printf "%s\n%s\n" \
      "deb [signed-by=/etc/apt/keyrings/llvm.gpg] https://apt.llvm.org/${CODENAME}/ llvm-toolchain-${CODENAME}-${CLANG_RELEASE} main" \
      "deb-src [signed-by=/etc/apt/keyrings/llvm.gpg] https://apt.llvm.org/${CODENAME}/ llvm-toolchain-${CODENAME}-${CLANG_RELEASE} main" \
      | tee /etc/apt/sources.list.d/llvm.list ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends \
      lsb-release less vim curl git grep sed gdb zsh lcov cmake ninja-build openssh-client ccache \
      python3 python3-pip python3-venv ;\
    apt-get install -t llvm-toolchain-${CODENAME}-${CLANG_RELEASE} -y --no-install-recommends \
      clang-${CLANG_RELEASE} clang-tools-${CLANG_RELEASE} clang-tidy-${CLANG_RELEASE} clang-format-${CLANG_RELEASE} \
      clangd-${CLANG_RELEASE} libc++-${CLANG_RELEASE}-dev libc++abi-${CLANG_RELEASE}-dev llvm-${CLANG_RELEASE} ;\
    apt-get clean

RUN set -ex ;\
    update-alternatives --install \
      /usr/bin/clang clang /usr/bin/clang-${CLANG_RELEASE} 100 \
      --slave /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_RELEASE} ;\
    update-alternatives --install \
      /usr/bin/llvm-cov llvm-cov /usr/bin/llvm-cov-${CLANG_RELEASE} 100 ;\
    update-alternatives --install \
      /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-${CLANG_RELEASE} 100 ;\
    update-alternatives --install \
      /usr/bin/clang-format clang-format /usr/bin/clang-format-${CLANG_RELEASE} 100 ;\
    update-alternatives --install \
      /usr/bin/clangd clangd /usr/bin/clangd-${CLANG_RELEASE} 100 ;\
    update-alternatives --auto clang ;\
    update-alternatives --auto llvm-cov ;\
    update-alternatives --auto clang-tidy ;\
    update-alternatives --auto clang-format ;\
    update-alternatives --auto clangd

RUN set -ex ;\
    wget -O /etc/zsh/zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc ;\
    wget -O /etc/zsh/newuser.zshrc.recommended  https://git.grml.org/f/grml-etc-core/etc/skel/.zshrc ;\
    chsh -s /bin/zsh

ARG HOME
ENV HOME=${HOME}
WORKDIR ${HOME}

ENV VENV=${HOME}/venv
ENV PATH=${VENV}/bin:${PATH}
ENV CCACHE_DIR=${HOME}/.ccache
RUN set -ex ;\
    python3 -m venv ${VENV}  ;\
    pip --no-cache-dir install 'gcovr<8'  ;\
    mkdir -p ${CCACHE_DIR}

ENV EDITOR=vim
ENV VISUAL=vim
ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++
ENV CMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/ccache
ENV CMAKE_GENERATOR=Ninja
ENV CMAKE_BUILD_TYPE=Debug

RUN cp /etc/zsh/newuser.zshrc.recommended .zshrc ;\
    touch .zshrc.local ;\
    ln -s .profile .zprofile ;\
    echo "alias to-gcc='export CC=/usr/bin/gcc; export CXX=/usr/bin/g++; env | grep --color=never -E \"^CC=|^CXX=\"'" >> ~/.zprofile ;\
    echo "alias to-clang='export CC=/usr/bin/clang; export CXX=/usr/bin/clang++; env | grep --color=never -E \"^CC=|^CXX=\"'" >> ~/.zprofile ;\
    echo "alias rm-build='realpath . | grep \"^.*/\.build[^/]*$\" &>/dev/null && find -mindepth 1 -maxdepth 1 -type d -not -path ./_deps | xargs rm -rf {} \; && find -mindepth 1 -maxdepth 1 -type f | xargs rm -f {} \;'" >> ~/.zprofile
