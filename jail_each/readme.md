# jail_each

> run the same command across all jails

Great for running `pkg` or `freebsd-update` on everything

## Usage

- Symlink `jail_each.sh` to `/root/bin/jail_each`
- Run e.G. `jail_each -b pkg upgrade` to keep everything
  up to date
- See `jail_each -h` for options
