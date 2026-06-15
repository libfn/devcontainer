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
COPY --from=gcc /etc/ld.so.conf.d/*.conf /etc/ld.so.conf.d/

ENV HOME=/root
WORKDIR ${HOME}
RUN set -ex ;\
    ldconfig -v ;\
    dpkg-divert --divert /usr/bin/gcc.orig --rename /usr/bin/gcc ;\
    dpkg-divert --divert /usr/bin/g++.orig --rename /usr/bin/g++ ;\
    dpkg-divert --divert /usr/bin/gfortran.orig --rename /usr/bin/gfortran ;\
    update-alternatives --install /usr/bin/cc cc /usr/local/bin/gcc 999 ;\
    update-alternatives --install /usr/bin/c++ c++ /usr/local/bin/g++ 999 ;\
    update-alternatives --install \
      /usr/bin/gcc gcc /usr/local/bin/gcc 100 \
      --slave /usr/bin/g++ g++ /usr/local/bin/g++ \
      --slave /usr/bin/gfortran gfortran /usr/local/bin/gfortran \
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
    export DEBIAN_FRONTEND=noninteractive ;\
    CODENAME=$( . /etc/os-release && echo $VERSION_CODENAME ) ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends ca-certificates wget gpg gpg-agent flex ;\
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /etc/apt/keyrings/llvm.gpg ;\
    printf "%s\n%s\n" \
      "deb [signed-by=/etc/apt/keyrings/llvm.gpg] https://apt.llvm.org/${CODENAME}/ llvm-toolchain-${CODENAME}-${CLANG_RELEASE} main" \
      "deb-src [signed-by=/etc/apt/keyrings/llvm.gpg] https://apt.llvm.org/${CODENAME}/ llvm-toolchain-${CODENAME}-${CLANG_RELEASE} main" \
      | tee /etc/apt/sources.list.d/llvm.list ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends \
      lsb-release libc6-dev less vim xxd curl git grep sed gdb zsh lcov make cmake ninja-build openssh-client ccache jq zip unzip bzip2 \
      valgrind unifdef python3 python3-pip python3-venv ;\
    apt-get install -t llvm-toolchain-${CODENAME}-${CLANG_RELEASE} -y --no-install-recommends \
      clang-${CLANG_RELEASE} clang-tools-${CLANG_RELEASE} clang-tidy-${CLANG_RELEASE} clang-format-${CLANG_RELEASE} \
      clangd-${CLANG_RELEASE} libc++-${CLANG_RELEASE}-dev libc++abi-${CLANG_RELEASE}-dev llvm-${CLANG_RELEASE} \
      libclang-${CLANG_RELEASE}-dev llvm-${CLANG_RELEASE}-dev libclang-rt-${CLANG_RELEASE}-dev ;\
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN set -ex ;\
    export DEBIAN_FRONTEND=noninteractive ;\
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
    wget -O /etc/zsh/newuser.zshrc.recommended https://git.grml.org/f/grml-etc-core/etc/skel/.zshrc ;\
    chsh -s /bin/zsh

ENV VENV=${HOME}/venv
ENV PATH=${VENV}/bin:${PATH}
ENV CCACHE_DIR=${HOME}/.ccache
RUN set -ex ;\
    python3 -m venv ${VENV} ;\
    # versions of pre-commit, clang-format and pre-commit-hooks synced with libfn/functional/ci/pre-commit ;\
    pip --no-cache-dir install 'gcovr<8' 'PyYAML<7' 'pre-commit<5' 'clang-format==22.1.5' 'pre-commit-hooks==5.0.0' clangd shellcheck-py ;\
    # cvise imports these past stdlib ;\
    pip --no-cache-dir install chardet psutil pebble msgspec zstandard ;\
    # enforce fail if clang-format binary used by pre-commit is not installed in the expected location ;\
    $(python -c "import site;print(site.getsitepackages()[0])")/clang_format/data/bin/clang-format --version ;\
    mkdir -p ${CCACHE_DIR}

ARG NODE_RELEASE=24
RUN set -ex ;\
    export DEBIAN_FRONTEND=noninteractive ;\
    curl --proto '=https' --tlsv1.2 -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg ;\
    printf "%s\n%s\n" \
      "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_RELEASE}.x nodistro main" \
      "deb-src [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_RELEASE}.x nodistro main" \
      | tee /etc/apt/sources.list.d/nodesource.list ;\
    printf "%s\n%s\n%s\n" \
      "Package: nodejs" \
      "Pin: origin deb.nodesource.com" \
      "Pin-Priority: 600" \
      | tee /etc/apt/preferences.d/nodejs ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends nodejs ;\
    node -v ;\
    npm -v ;\
    npm install -g prettier ;\
    prettier --version ;\
    npm install -g @augmentcode/auggie @anthropic-ai/claude-code ;\
    auggie --version ;\
    claude --version ;\
    apt-get clean && rm -rf /var/lib/apt/lists/* ;\
    npm cache clean --force

ARG RUST_RELEASE=stable
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:${PATH}
RUN set -ex ;\
    arch=$(uname -m) ;\
    case "$arch" in \
        x86_64)  rustArch='x86_64-unknown-linux-gnu' ;;\
        aarch64) rustArch='aarch64-unknown-linux-gnu' ;;\
        *) echo "unsupported architecture: $arch"; exit 1 ;;\
    esac ;\
    url="https://static.rust-lang.org/rustup/dist/${rustArch}/rustup-init" ;\
    curl --proto '=https' --tlsv1.2 -sSf "${url}" -o rustup-init ;\
    chmod +x rustup-init ;\
    ./rustup-init -y \
      --no-modify-path \
      --default-toolchain ${RUST_RELEASE} \
      --profile minimal \
      --component clippy,rustfmt \
      --target wasm32-unknown-unknown ;\
    rm rustup-init ;\
    chmod -R a+w ${RUSTUP_HOME} ${CARGO_HOME}

ARG GO_RELEASE=1.26.4
ENV PATH=/usr/local/go/bin:${PATH}
RUN set -ex ;\
    url="https://go.dev/dl/go${GO_RELEASE}.linux-$(dpkg --print-architecture).tar.gz" ;\
    curl --proto '=https' --tlsv1.2 -fsSL "${url}" -o go.tgz ;\
    rm -rf /usr/local/go ;\
    tar -C /usr/local -xzf go.tgz ;\
    rm -f go.tgz ;\
    go version

# TREE_SITTER_RELEASE must match tree-sitter/Makefile VERSION at CVISE_COMMIT.
ARG CVISE_COMMIT=64ff7de2
ARG TREE_SITTER_RELEASE=0.25.8
RUN set -ex ;\
    cargo install tree-sitter-cli --version ${TREE_SITTER_RELEASE} --root /usr/local ;\
    git clone https://github.com/marxin/cvise /root/cvise ;\
    git -C /root/cvise checkout ${CVISE_COMMIT} ;\
    cmake -G Ninja -S /root/cvise -B /root/cvise/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH=/usr/lib/llvm-${CLANG_RELEASE} \
      -DCMAKE_C_FLAGS=-Wno-error=sign-compare \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DPython3_EXECUTABLE=${VENV}/bin/python ;\
    cmake --build /root/cvise/build ;\
    cmake --build /root/cvise/build --target install ;\
    rm -rf /root/cvise ;\
    cvise --version

RUN set -ex ;\
    export DEBIAN_FRONTEND=noninteractive ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends qemu-user g++-aarch64-linux-gnu ;\
    apt-get clean && rm -rf /var/lib/apt/lists/*

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
    echo "alias to-gcc='export CC=/usr/bin/gcc; export CXX=/usr/bin/g++; unset CXXFLAGS; env | grep --color=never -E \"^CC=|^CXX=|^CXXFLAGS=\"'" >> ~/.zprofile ;\
    echo "alias to-clang='export CC=/usr/bin/clang; export CXX=/usr/bin/clang++; export CXXFLAGS=-stdlib=libc++; env | grep --color=never -E \"^CC=|^CXX=|^CXXFLAGS=\"'" >> ~/.zprofile ;\
    echo "alias rm-build='realpath . | grep \"^.*/\.build[^/]*$\" &>/dev/null && find -mindepth 1 -maxdepth 1 -type d -not -path ./_deps | xargs rm -rf {} \; && find -mindepth 1 -maxdepth 1 -type f | xargs rm -f {} \;'" >> ~/.zprofile
