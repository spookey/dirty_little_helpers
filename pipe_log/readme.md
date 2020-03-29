# pipe log

> collect output of high frequency (cron) jobs and generate summary


## Remarks

Redirection is difficult, so only one pipe is used.
Do not forget about ``2>&1`` if errors should end up in the log file.


## Usage

* Create multiple cron jobs, at least two
    * At least one to collect data
    * One to output generated summary

Collect:

```
/some/command 2>&1 | /some/where/pipe_log/pipe_log.sh  -t "/what/ever.log"
```

Output:

```
/some/where/pipe_log/pipe_log.sh -t "/what/ever.log" -ed
```
