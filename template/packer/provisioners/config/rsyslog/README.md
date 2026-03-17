# rsyslog Multi-OS Configuration Bundle

## Included Files

### RedHat / Rocky
- rsyslog_redhat_stop.conf
- rsyslog_redhat_split.conf

### Debian / Ubuntu
- rsyslog_debian_stop.conf
- rsyslog_debian_split.conf

## Modes

### stop
Drop Kubernetes noisy logs completely.

### split
Send Kubernetes logs to `k8s-log` topic and normal logs to `system-log`.

## Filtered k8s programs

- kubelet
- containerd
- kube-proxy
- calico*

## Deployment

Copy selected file to:

`/etc/rsyslog.conf`

Then restart:

`sudo systemctl restart rsyslog`

## Validation

`rsyslogd -N1`
