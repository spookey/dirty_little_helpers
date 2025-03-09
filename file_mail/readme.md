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

Take care of the following, otherwise issues will occur:

* Use some generous `DEFER` value.
  * It takes time to compress the log file.
  * Otherwise the content is empty, so no mail is sent.
* Also keep the forking (`&`) in there.
  * The `newsyslog` process should not be blocked.
  * As `file_mail.sh` does sleep for `DEFER` seconds.

Add some rule for newsyslog:

`/usr/local/etc/newsyslog.conf.d/something.conf`

```plain
# logfilename          [owner:group]    mode count size when  flags [/pid_file] [sig_num]
/var/log/something.log                  644  4     *    @T00  BCXR  /to/wrapper_something.sh
```

Settings inside `/to/wrapper_something.sh` would be then:

```sh
COMPRESSION="xz"
LOG_FILE="/var/log/something.log.0.xz"
```
