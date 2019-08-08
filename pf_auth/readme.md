# pf auth

> Use ``/var/log/auth.log`` to prevent ssh bruteforce attacks.


Remarks:

* ``filter_ipaddr.py`` should work both in ``python2`` & ``python3``
    * if using ``python2``, make sure to have ``net/py-ipaddress`` installed
* ``pf_auth.sh`` uses full paths for commands so it can run in the crontab


``/etc/pf.conf`` example:

```
table <tbl_sshauth_block> persist {}

[...]

block drop in from <tbl_sshauth_block> to any
```

And run it from the crontab...
