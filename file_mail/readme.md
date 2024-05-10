# newsys mail

> Send logfile content after newsyslog rotation

## Usage

Have $something that produces log files.

Copy the `example_wrapper.sh` script and adjust settings.

Add some rule for newsyslog:

`/usr/local/etc/newsyslog.conf.d/something.conf`

```plain
# logfilename          [owner:group]    mode count size when  flags [/pid_file] [sig_num]
/var/log/something.log                  644  4     *    @T00  BCXR  /to/wrapper_something.sh
```