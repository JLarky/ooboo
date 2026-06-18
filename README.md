# ooboo

Mojo project for a Boo-backed agent control CLI experiment.

`mise` installs the developer toolchain, and `pixi` owns the Mojo environment.

## Install

```bash
mise run install
```

## Mojo

```bash
mise run mojo-version
mise run mojo hello.mojo
mise run hello
mise run ooboo -- --help
mise run ooboo -- run-shell "printf hello"
```
