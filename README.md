# Pesonal dotfiles setup
WARNING: `.files` is a terrible repo name.

**First run** — installs everything from scratch:

```
./setup.sh
```

**Subsequent runs** — skips completed steps, finishes instantly:

```
./setup.sh
```

**Re-run everything** — clears all state markers first:

```
./setup.sh --force
```

**Re-run a specific step** — delete its marker and run again:

```
rm ~/.local/state/setup/setup_dotfiles.done && ./setup.sh
```


## Development:

Always ensure that setup.sh and above listed examples are idempotent operations (except ~/.local) folder.

