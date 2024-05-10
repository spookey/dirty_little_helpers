# newsys mail

> Send file contents as mail

## Usage

Required arguments are the `from`, `to` and `subject` arguments.

Pass them either as `-f`, `-t` & `-s` or use the environment variables
`MAIL_FROM`, `MAIL_RCPT` & `MAIL_SUBJ`.

Final argument specifies the file to be sent by mail.

### newsyslog

Have $something that produces log files.

Copy the `example_wrapper_newsyslog.sh` script and adjust settings.

Make sure to use some generous `DEFER` value and keep the forking (`&`).
Otherwise issues will occur.

Add some rule for newsyslog:

`/usr/local/etc/newsyslog.conf.d/something.conf`

```plain
# logfilename          [owner:group]    mode count size when  flags [/pid_file] [sig_num]
/var/log/something.log                  644  4     *    @T00  BCXR  /to/wrapper_something.sh
```
