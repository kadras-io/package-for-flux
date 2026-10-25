# Security

The controllers are hardened following the [Flux security best practices](https://fluxcd.io/flux/security/best-practices/).

## Pod Security Standards

The controllers comply with the `restricted` [Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/), enforced on the package namespace. Upstream only warns about it.

## Service account tokens

The service account tokens aren't auto-mounted. Each controller mounts a projected token instead, which expires after an hour and is rotated by the kubelet.

## Permissions

The kustomize and helm controllers are bound to the `cluster-admin` ClusterRole, since they apply arbitrary resources. On shared clusters, make them impersonate a service account with fewer permissions in the namespace of each Flux resource, as described in [configuration.md](configuration.md#multi-tenancy-lockdown). See [contextual authorization](https://fluxcd.io/flux/security/contextual-authorization/).

The `flux-view` and `flux-edit` ClusterRoles aggregate the permissions on the Flux resources to the built-in `view`, `edit`, and `admin` ClusterRoles, so that the users can manage the Flux resources in their namespaces. The cluster-wide resources of the package are prefixed with `flux-`.

## Network policies

The package includes the upstream network policies:

* `allow-egress`: allows all the outbound traffic, and the inbound traffic from the Pods in the Flux namespace only, so the artifacts of the source controller can't be downloaded from other namespaces (see [configuration.md](configuration.md#access-to-the-artifacts) to allow it);
* `allow-scraping`: allows the metrics scraping on port 8080, from all namespaces;
* `allow-webhooks`: allows the webhooks of the Receivers to reach the notification controller on port 9292, from all namespaces.

Restrict them further with a ytt overlay (see [configuration.md](configuration.md#ytt-overlays)). The policies only apply if the network plugin of the cluster enforces them.

### Outbound traffic

The outbound traffic isn't restricted, since its destinations depend on the Flux resources:

* all the controllers reach the Kubernetes API server (usually on port 443 or 6443) and the cluster DNS (port 53);
* the source controller, the image controllers, and the source watcher reach Git servers (port 443 or 22), OCI registries, Helm repositories, and buckets;
* the notification controller reaches the notification providers;
* the controllers talk to each other in the Flux namespace.

To restrict it, create your own NetworkPolicies in the Flux namespace: they add up to the ones of the package.

## Secrets

Flux decrypts the secrets stored in Git with [SOPS](https://fluxcd.io/flux/guides/mozilla-sops/), using age or OpenPGP keys stored in Kubernetes Secrets, referenced by each Kustomization. See [secrets management](https://fluxcd.io/flux/security/secrets-management/).

## Kyverno policies

The package can include a Kyverno policy verifying that all the images of the package are signed by the Flux release workflows on GitHub Actions, with [Cosign keyless signatures](https://fluxcd.io/flux/security/#signed-container-images) recorded in the Rekor transparency log. It requires Kyverno 1.19 or later, and access to the Rekor and Sigstore services.

```yaml
policies:
  enabled: true
```
