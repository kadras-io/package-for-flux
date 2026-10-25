# Corporate Proxy

When running Flux behind a corporate proxy, configure the controllers to reach external services through it: Git servers, OCI registries, Helm repositories, buckets, and notification providers.

```yaml
proxy:
  http_proxy: http://proxy.example.com:3128
  https_proxy: http://proxy.example.com:3128
  no_proxy: .cluster.local.,.cluster.local,.svc,10.0.0.0/8
```

The controllers talk to each other through the cluster domain, so include it in `no_proxy`, together with the address of the Kubernetes API server and the Pod and Service networks. See [proxy](https://fluxcd.io/flux/installation/configuration/proxy-setting/).

The proxy settings apply to the HTTP traffic. To reach Git servers via SSH through a SOCKS5 proxy, set the `ALL_PROXY` environment variable of the source and image automation controllers with a ytt overlay (see [configuration.md](configuration.md#ytt-overlays)).
