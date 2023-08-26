# Using a Corporate Proxy

When running Flux behind a corporate proxy, you can configure the controllers to proxy communications with external services.

```yaml
proxy:
  http_proxy: "proxy.kadras.io"
  https_proxy: "proxy.kadras.io"
  no_proxy: ".cluster.local., .cluster.local, .svc"
```

For more information, check the Flux documentation for configuring a [proxy](https://fluxcd.io/flux/installation/configuration/proxy-setting/).
