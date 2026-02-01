# Flux

![Test Workflow](https://github.com/kadras-io/package-for-flux/actions/workflows/test.yml/badge.svg)
![Release Workflow](https://github.com/kadras-io/package-for-flux/actions/workflows/release.yml/badge.svg)
[![The SLSA Level 3 badge](https://slsa.dev/images/gh-badge-level3.svg)](https://slsa.dev/spec/v1.0/levels)
[![The Apache 2.0 license badge](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Follow us on Bluesky](https://img.shields.io/static/v1?label=Bluesky&message=Follow&color=1DA1F2)](https://bsky.app/profile/kadras.bsky.social)

A Carvel package for [Flux](https://fluxcd.io), a continuous deployment solution for Kubernetes powered by the GitOps Toolkit.

## 🚀&nbsp; Getting Started

### Prerequisites

* Kubernetes 1.33+
* Carvel [`kctrl`](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl) CLI.
* Carvel [kapp-controller](https://carvel.dev/kapp-controller) deployed in your Kubernetes cluster. You can install it with Carvel [`kapp`](https://carvel.dev/kapp/docs/latest/install) (recommended choice) or `kubectl`.

  ```shell
  kapp deploy -a kapp-controller -y \
    -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
  ```

### Installation

Add the Kadras [package repository](https://github.com/kadras-io/kadras-packages) to your Kubernetes cluster:

  ```shell
  kctrl package repository add -r kadras-packages \
    --url ghcr.io/kadras-io/kadras-packages \
    -n kadras-system --create-namespace
  ```

<details><summary>Installation without package repository</summary>
The recommended way of installing the Flux package is via the Kadras <a href="https://github.com/kadras-io/kadras-packages">package repository</a>. If you prefer not using the repository, you can add the package definition directly using <a href="https://carvel.dev/kapp/docs/latest/install"><code>kapp</code></a> or <code>kubectl</code>.

  ```shell
  kubectl create namespace kadras-system
  kapp deploy -a flux-package -n kadras-system -y \
    -f https://github.com/kadras-io/package-for-flux/releases/latest/download/metadata.yml \
    -f https://github.com/kadras-io/package-for-flux/releases/latest/download/package.yml
  ```
</details>

Install the Flux package:

  ```shell
  kctrl package install -i flux \
    -p flux.packages.kadras.io \
    -v ${VERSION} \
    -n kadras-system
  ```

> **Note**
> You can find the `${VERSION}` value by retrieving the list of package versions available in the Kadras package repository installed on your cluster.
> 
>   ```shell
>   kctrl package available list -p flux.packages.kadras.io -n kadras-system
>   ```

Verify the installed packages and their status:

  ```shell
  kctrl package installed list -n kadras-system
  ```

## 📙&nbsp; Documentation

Documentation, tutorials and examples for this package are available in the [docs](docs) folder.
For documentation specific to Flux, check out [fluxcd.io](https://fluxcd.io/docs).

## 🎯&nbsp; Configuration

The Flux package can be customized via a `values.yml` file.

  ```yaml
  components:
    kustomize_controller: true
    helm_controller: true
    notification_controller: true
    image_automation_controller: false
    image_reflector_controller: false
  ```

Reference the `values.yml` file from the `kctrl` command when installing or upgrading the package.

  ```shell
  kctrl package install -i flux \
    -p flux.packages.kadras.io \
    -v ${VERSION} \
    -n kadras-system \
    --values-file values.yml
  ```

### Values

The Flux package has the following configurable properties.

<details><summary>Configurable properties</summary>

| Config | Default | Description |
|-------|-------------------|-------------|
| `ca_cert_data` | `""` | PEM-encoded certificate data to trust TLS connections with a custom CA. |
| `optional_components.kustomize_controller` | `true` | Whether to deploy the Kustomize Controller. |
| `optional_components.helm_controller` | `false` | Whether to deploy the Helm Controller. |
| `optional_components.notification_controller` | `false` | Whether to deploy the Notification Controller. |
| `optional_components.image_automation_controller` | `false` | Whether to deploy the Image Automation Controller. |
| `optional_components.image_reflector_controller` | `false` | Whether to deploy the Image Reflector Controller. |
| `policies.include` | `false` | Whether to include the out-of-the-box Kyverno policies to validate and secure the package installation. |

Settings for logging.

| Config | Default | Description |
|-------|-------------------|-------------|
| `logging.level` | `info` | Log verbosity level. Options: `trace`, `debug`, `info`, `error`. |
| `logging.encoding` | `json` | Log encoding format. Options: `console`, `json`. |

Settings for the corporate proxy.

| Config | Default | Description |
|-------|-------------------|-------------|
| `proxy.https_proxy` | `""` | The HTTPS proxy to use for network traffic. |
| `proxy.http_proxy` | `""` | The HTTP proxy to use for network traffic. |
| `proxy.no_proxy` | `""` | A comma-separated list of hostnames, IP addresses, or IP ranges in CIDR format that should not use the proxy. |

</details>

## 🛡️&nbsp; Security

The security process for reporting vulnerabilities is described in [SECURITY.md](SECURITY.md).

## 🖊️&nbsp; License

This project is licensed under the **Apache License 2.0**. See [LICENSE](LICENSE) for more information.
