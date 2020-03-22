# pf auth

> Use ``/var/log/auth.log`` to prevent ssh bruteforce attacks.


## Remarks

* Make sure to have ``net/py-ipaddress`` installed when running
  ``filter_ipaddr.py`` with ``python2``


## Usage

``/etc/pf.conf`` example:

```
table <tbl_block> persist {}

[...]

block drop in from <tbl_block> to any
```

Add the script to the crontab.
