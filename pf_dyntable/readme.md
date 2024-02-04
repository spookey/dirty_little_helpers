# pf dyntable

> Forwarding traffic from jails using `pf` behind some dynamic address.

I have a box at home running some jails.
There is dynamic assignment of IP addresses, so it's difficult to forward
traffic from the jails.

See this [Forum thread](https://www.bsdforen.de/threads/pf-nat-f%C3%BCr-ipv4-und-ipv6-adresse.32344/)!

## Usage

`/etc/pf.conf` example:

```plain
# interfaces
if_ext = "em0"
if_lo0 = "lo0"
if_lo1 = "lo1"

# [...]

# tables for dynamic addresses
table <tbl_ip_ext4> {}
table <tbl_ip_ext6> {}

# [...]

# outbound traffic from jails
nat pass on $if_ext inet from ($if_lo1:network) to any -> <tbl_ip_ext4>
nat pass on $if_ext inet6 from ($if_lo1:network) to any -> <tbl_ip_ext6>
```
