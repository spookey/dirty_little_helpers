# bootstrap_jail

> host scripts to setup thick jails

Example: The Dataset `data/vm/jails` mounted on `/var/jails`.

## `bjail_dataset` Usage

- Symlink `bjail_dataset.sh` to `/root/bin/bjail_dataset`
- Run with jail name and parent dataset to create & adjust:
  - `bjail_dataset -c data/vm/jails example`
  - the `-c` switch creates datasets, `zfsprops` will be set in any case

Check results via:

```sh
zfs get -r atime,exec,canmount,setuid data/vm/jails/example
```

## `bjail_install` Usage

- Symlink `bjail_install.sh` to `/root/bin/bjail_install`
- Run with jail path and options:
  - `bjail_install -x /var/jails/example`
    - downloads files, checks and extracts `base.txz`
  - `bjail_install -z /usr/share/zoneinfo/Asia/Tokyo /var/jails/example`
    - symlinks jail `etc/localtime` if not present
    - defaults to host
  - `bjail_install -t /var/jails/example`
    - prepare `/etc/fstab.jail` on host with `tmpfs` entry
  - `bjail_install -d /etc/resolv.conf /var/jails/example`
    - copies from host to `etc/resolv.conf`
  - `bjail_install -r /var/jails/example`
    - prepare `etc/rc.conf` with basic settings
  - `bjail_install -m /var/jails/example`
    - creates `etc/motd.template` for jail
