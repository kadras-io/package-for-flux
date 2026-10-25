# Flux

![Test Workflow](https://github.com/kadras-io/package-for-flux/actions/workflows/test.yml/badge.svg)
![Release Workflow](https://github.com/kadras-io/package-for-flux/actions/workflows/release.yml/badge.svg)
[![The SLSA Level 3 badge](https://slsa.dev/images/gh-badge-level3.svg)](https://slsa.dev/spec/v1.0/levels)
[![The Apache 2.0 license badge](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Follow us on Bluesky](https://img.shields.io/static/v1?label=Bluesky&message=Follow&color=1DA1F2)](https://bsky.app/profile/kadras.bsky.social)

A Carvel package for [Flux](https://fluxcd.io), a continuous deployment solution for Kubernetes powered by the GitOps Toolkit. It keeps clusters in sync with sources of configuration, like Git repositories, OCI artifacts, and Helm charts.

## ✨&nbsp; What's Included

* **GitOps toolkit**. The Flux source, kustomize, helm, and notification controllers, deployed by default, and the optional image reflector, image automation, and source watcher controllers. Each controller can be configured via its flags.
* **Observability**. Structured logs, and metrics annotated for Prometheus scraping.
* **Security**. The controllers comply with the `restricted` [Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/), enforced on their namespace, mount the service account tokens only where needed, and are isolated with the upstream network policies. Optionally, Kyverno verifies the signatures of the Flux images.

## 🚀&nbsp; Getting Started

### Prerequisites

* Kubernetes 1.35+
* Carvel [`kctrl`](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl) CLI.
* Carvel [kapp-controller](https://carvel.dev/kapp-controller) deployed in your Kubernetes cluster. You can install it with Carvel [`kapp`](https://carvel.dev/kapp/docs/latest/install) (recommended choice) or `kubectl`.

```shell
kapp deploy -a kapp-controller -y \
  -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
```

### Dependencies

Flux has no required dependencies. To authenticate with private registries, install [secretgen-controller](https://github.com/kadras-io/package-for-secretgen-controller) from the [Kadras package repository](https://github.com/kadras-io/kadras-packages). To verify the Flux images, install [Kyverno](https://github.com/kadras-io/package-for-kyverno) 1.19 or later.

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
> ```shell
> kctrl package available list -p flux.packages.kadras.io -n kadras-system
> ```

Verify the installed packages and their status:

```shell
kctrl package installed list -n kadras-system
```

### Try It Out

Deploy the [podinfo](https://github.com/stefanprodan/podinfo) application from its OCI artifact:

```shell
kubectl apply -f - <<EOF
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: podinfo
  namespace: default
spec:
  interval: 10m
  url: oci://ghcr.io/stefanprodan/manifests/podinfo
  ref:
    semver: ">=6.0.0"
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo
  namespace: default
spec:
  interval: 10m
  sourceRef:
    kind: OCIRepository
    name: podinfo
  path: ./
  targetNamespace: default
  prune: true
  wait: true
EOF
```

Check that the Kustomization is ready and the application is running:

```shell
kubectl get kustomization podinfo -n default
kubectl get deployment podinfo -n default
```

## 📙&nbsp; Documentation

Documentation, tutorials and examples for this package are available in the [docs](docs) folder.
For documentation specific to Flux, check out [fluxcd.io](https://fluxcd.io/flux).

Features:

* [High availability](docs/high-availability.md)
* [Observability](docs/observability.md)
* [Security](docs/security.md)

Operations:

* [Configuration and ytt overlays](docs/configuration.md)
* [Custom certificate authorities](docs/custom-ca.md)
* [Corporate proxy](docs/corporate-proxy.md)
* [Upgrading and uninstalling](docs/upgrade.md)
* [Verifying the release](docs/verify-release.md)

## 🎯&nbsp; Configuration

The Flux package can be customized via a `values.yml` file.

```yaml
image_reflector_controller:
  enabled: true
image_automation_controller:
  enabled: true
kustomize_controller:
  args:
    no-cross-namespace-refs: true
    no-remote-bases: true
```

Reference the `values.yml` file from the `kctrl` command when installing or upgrading the package.

```shell
kctrl package install -i flux \
  -p flux.packages.kadras.io \
  -v ${VERSION} \
  -n kadras-system \
  --values-file values.yml
```

The flags of each controller can be customized beyond the values, as well as any resource via ytt overlays. See [configuration.md](docs/configuration.md).

### Values

The Flux package has the following configurable properties.

<details><summary>Configurable properties</summary>

<!-- values-table:start -->

| Config | Default | Description |
|--------|---------|-------------|
| `namespace` | `"flux-system"` | The namespace in which to deploy Flux. |
| `source_controller.args` | `{}` | Container flags, merged on top of the ones computed by the package. Set a flag to null to remove it. See https://fluxcd.io/flux/components/source/options/. |
| `kustomize_controller.enabled` | `true` | Whether to deploy the kustomize controller. |
| `kustomize_controller.args` | `{}` | Container flags, merged on top of the ones computed by the package. Set a flag to null to remove it. See https://fluxcd.io/flux/components/kustomize/options/. |
| `helm_controller.enabled` | `true` | Whether to deploy the helm controller. |
| `helm_controller.args` | `{}` | Container flags, merged on top of the ones computed by the package. Set a flag to null to remove it. See https://fluxcd.io/flux/components/helm/options/. |
| `notification_controller.enabled` | `true` | Whether to deploy the notification controller. When disabled, the other controllers don't send events. |
| `notification_controller.args` | `{}` | Container flags, merged on top of the ones computed by the package. Set a flag to null to remove it. See https://fluxcd.io/flux/components/notification/options/. |
| `image_reflector_controller.enabled` | `false` | Whether to deploy the image reflector controller. |
| `image_reflector_controller.args` | `{}` | Container flags, merged on top of the ones computed by the package. Set a flag to null to remove it. See https://fluxcd.io/flux/components/image/options/. |
| `image_automation_controller.enabled` | `false` | Whether to deploy the image automation controller. |
| `image_automation_controller.args` | `{}` | Container flags, merged on top of the ones computed by the package. Set a flag to null to remove it. See https://fluxcd.io/flux/components/image/options/. |
| `source_watcher.enabled` | `false` | Whether to deploy the source watcher. |
| `source_watcher.args` | `{}` | Container flags, merged on top of the ones computed by the package. Set a flag to null to remove it. It accepts the flags common to the Flux controllers, like `concurrent` and `requeue-dependency`. See https://fluxcd.io/flux/components/source/artifactgenerators/. |
| `ca_cert_data` | `""` | PEM-encoded certificates of additional certificate authorities to trust, for example to reach a private Git server, OCI registry, or Helm repository. The system ones are still trusted. |
| `observability.logging.level` | `"info"` | The log level of the controllers. |
| `observability.logging.format` | `"json"` | The format of the logs. |
| `observability.metrics.enabled` | `true` | Whether to annotate the Pods for Prometheus scraping. The controllers always expose metrics on port 8080 (`/metrics`). |
| `policies.enabled` | `false` | Whether to include the Kyverno policies that validate and secure the package installation. They require Kyverno 1.19 or later. |
| `proxy.http_proxy` | `""` | The HTTP proxy to use for network traffic. |
| `proxy.https_proxy` | `""` | The HTTPS proxy to use for network traffic. |
| `proxy.no_proxy` | `""` | A comma-separated list of hostnames, IP addresses, or IP ranges in CIDR format that should not use the proxy. Include the in-cluster domains, since the controllers talk to each other. |

<!-- values-table:end -->

</details>

## 🛠️&nbsp; Development

The development environment is defined with [devenv](https://devenv.sh). Enter it with `devenv shell`, or automatically with [direnv](https://direnv.net) after running `direnv allow`. Run `task --list` to see all the available tasks.

```shell
# Run the unit tests, which render the package and check the result without a cluster.
task test:config

# Create a local kind cluster and run the integration tests on it.
task cluster:setup
task test:integration

# Deploy the package from the local sources to the current cluster.
task dev

# Update the table of configurable values in this README after changing the values schema.
task docs:values
```

The unit tests are described in [test/unit/README.md](test/unit/README.md).

## 🛡️&nbsp; Security

The security process for reporting vulnerabilities is described in [SECURITY.md](SECURITY.md).

## 🖊️&nbsp; License

This project is licensed under the **Apache License 2.0**. See [LICENSE](LICENSE) for more information.
