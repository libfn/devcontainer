# devcontainer 

Example devcontainer for work with [libfn/functional](https://github.com/libfn/functional).

Useful if your operating system does not directly support the compiler required by [libfn/functional].

[libfn/functional]: https://github.com/libfn/functional

## Security note

This [devcontainer] does not create a user account inside the container, and hence **it could create a security risk**. The recommended way to use it is with a [rootless docker][rootless-docker] or [podman] (which is always rootless). The rootless mode will map the container `root` account into the host account of the _user_ running the container (rather than the host `root` account), hence removing the risk.

**The failure to use the devcontainer in rootless mode will make the host root account an owner of all the files created inside the devcontainer**, making it difficult to manage the development workspace on the host, and possibly creating other risks.

### The recommended way to use this repo is by creating its fork first.

Within own fork, users can [add a non-root user to the container][add-non-root-user] and manage the security risk this way.

[devcontainer]: https://code.visualstudio.com/docs/devcontainers/containers
[rootless-docker]: https://docs.docker.com/engine/security/rootless/
[podman]: https://podman.io/get-started
[add-non-root-user]: https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user

## Content

This [devcontainer] is based on [the official gcc container][gcc-container], with the addition of [clang packages][clang-packages] and other development tools.

Most elements inside the container are subject to taste, for example:
* selection of `vim` editor
* selection of `zsh` shell
* [grml] shell customizations
* `ccache` being used and its cache location `~/.ccache`
* aliases defined in `~/.zprofile`
* location of `~/venv`
* etc.

Similarly most elements of [`devcontainer.json`][devcontainer-json] are subject to taste, for example:
* selection of vscode plugins
* `ccache_data` volume
* bind point for `/tmp`
* bind point for `$SSH_AUTH_SOCK`
* etc.

For this reason, it is **not recommended** to use this repo as-is. Instead, the users are expected to fork this repo, apply customizations as needed, and then use it. In case of a fault being found in this repo, pull requests will be welcome.

[gcc-container]: https://hub.docker.com/_/gcc
[clang-packages]: https://apt.llvm.org/
[grml]: https://grml.org/zsh/
[devcontainer-json]: https://containers.dev/implementors/json_reference/

### If you use this repo, it is your responsibility to know what you are doing.

There are **no explicit or implicit guarantees of any kind**, not even usefulness or basic security.

## License

This repo does not contain source code of a computer program. However, for the avoidance of doubt, it is explicitly put in the public domain with the [Unlicense](https://opensource.org/licenses/Unlicense)

## Future changes

It is likely that the structure or content of this repo will significantly change over time, with no guarantees of any stability (e.g. regarding the available devcontainer functionality, devcontainer compatibility, file locations etc.).

_If you like it, fork it_.
