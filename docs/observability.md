# Configuring Observability

Monitor and observe the operation of Flux using logs and metrics.

## Logs

The log verbosity and encoding for the Flux controllers can be configured.

```yaml
logging:
  level: info
  encoding: json
```

For more information, check the Flux documentation for [logs](https://fluxcd.io/flux/monitoring/logs/).

## Metrics

The Flux controllers expose Prometheus metrics by default. This package comes pre-configured with the necessary annotations to let Prometheus scrape metrics automatically from the Flux controllers.

For more information, check the Flux documentation for [metrics](https://fluxcd.io/flux/monitoring/metrics/) and [custom metrics](https://fluxcd.io/flux/monitoring/custom-metrics/).
