# pf auth

> Use `/var/log/auth.log` to prevent ssh bruteforce attacks.

## Usage

`/etc/pf.conf` example:

```plain
table <tbl_block> persist {}

[...]

block drop in from <tbl_block> to any
```

Add the script to the crontab.
