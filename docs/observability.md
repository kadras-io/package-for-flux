# Observability

## Logs

The log level and format apply to all the Flux controllers.

```yaml
observability:
  logging:
    level: info
    format: json
```

* `level` is one of `error`, `info`, `debug`, `trace`.
* `format` is one of `text` and `json`. Flux calls the text format `console`.

The JSON logs include the kind, namespace, and name of the reconciled Flux resource. See [logs](https://fluxcd.io/flux/monitoring/logs/). The controllers also record [Kubernetes events](https://fluxcd.io/flux/monitoring/events/) on the Flux resources, and send them to the notification controller, which forwards them to external systems via [alerts](https://fluxcd.io/flux/monitoring/alerts/).

## Metrics

All the controllers expose metrics in the Prometheus format on port 8080 (`/metrics`), on the `http-prom` container port. Their Pods are annotated for Prometheus scraping (`prometheus.io/scrape`, `prometheus.io/port`). To remove the annotations:

```yaml
observability:
  metrics:
    enabled: false
```

If you use the Prometheus Operator, create a PodMonitor instead:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: flux
  namespace: flux-system
spec:
  selector:
    matchLabels:
      app.kubernetes.io/part-of: flux
  podMetricsEndpoints:
    - port: http-prom
```

The controllers expose the duration of the reconciliations and the controller-runtime metrics. For the status of each Flux resource, Flux recommends [kube-state-metrics custom resource metrics](https://fluxcd.io/flux/monitoring/custom-metrics/). See [metrics](https://fluxcd.io/flux/monitoring/metrics/) and the Grafana dashboards in the [Flux monitoring example](https://github.com/fluxcd/flux2-monitoring-example).
