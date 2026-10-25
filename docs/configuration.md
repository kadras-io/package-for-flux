# Configuration

The package values cover the decisions most installations need to make: which controllers to run, observability, trust, and the corporate proxy. Everything else can still be customized in two ways.

## Container flags

Each controller is configured via container flags. The package computes some of them from the values (log level and format, address of the notification controller) and merges them into the upstream ones, then merges `<component>.args` on top, so its flags take precedence. The flags are written without the leading dashes, and a flag set to `null` is removed.

```yaml
source_controller:
  args:
    concurrent: 10
    requeue-dependency: 5s
kustomize_controller:
  args:
    concurrent: 10
    requeue-dependency: 5s
```

Each controller accepts different flags, and an unknown flag, or an unknown feature gate, prevents it from starting. Check the reference of the Flux version you install before adding one: [source](https://fluxcd.io/flux/components/source/options/), [kustomize](https://fluxcd.io/flux/components/kustomize/options/), [helm](https://fluxcd.io/flux/components/helm/options/), [notification](https://fluxcd.io/flux/components/notification/options/), [image](https://fluxcd.io/flux/components/image/options/). A change rolls out the controller.

### Multi-tenancy lockdown

On clusters shared by multiple teams, Flux recommends preventing the Flux resources of a tenant from referencing sources in other namespaces, remote Kustomize bases, and the cluster-admin permissions of the controllers. With `default-service-account`, the kustomize and helm controllers impersonate the given service account in the namespace of each Kustomization and HelmRelease that doesn't set `spec.serviceAccountName`. See [multi-tenancy](https://fluxcd.io/flux/installation/configuration/multitenancy/).

```yaml
kustomize_controller:
  args:
    no-cross-namespace-refs: true
    no-remote-bases: true
    default-service-account: default
helm_controller:
  args:
    no-cross-namespace-refs: true
    default-service-account: default
notification_controller:
  args:
    no-cross-namespace-refs: true
```

Set `no-cross-namespace-refs` on the image controllers and the source watcher too, when enabled. The Flux resources managed by the platform team, in the Flux namespace, then need `spec.serviceAccountName: kustomize-controller` (or `helm-controller`) to keep the permissions of the controller.

### Feature gates

The feature gates of a controller are set in a single `feature-gates` flag, as comma-separated `<gate>=<value>` pairs. For example, to let the helm controller detect when it's about to run out of memory and fail the in-progress releases gracefully, and to allow DNS lookups in the Helm templates:

```yaml
helm_controller:
  args:
    feature-gates: OOMWatch=true,AllowDNSLookups=true
```

See [Helm OOM detection](https://fluxcd.io/flux/installation/configuration/helm-oom-detection/) and [Helm DNS lookups](https://fluxcd.io/flux/installation/configuration/helm-dns-lookup/). DNS lookups are disabled by default because they let the templates reach any host resolvable from the cluster.

### Vertical scaling

When reconciling many resources, increase the number of concurrent reconciliations and reduce the delay between a resource and its dependencies, together with the resources of the controllers (see [Resources](#resources)). The source controller can also cache the Helm repository indexes. See [vertical scaling](https://fluxcd.io/flux/installation/configuration/vertical-scaling/).

```yaml
source_controller:
  args:
    concurrent: 10
    requeue-dependency: 5s
    helm-cache-max-size: 10
    helm-cache-ttl: 60m
    helm-cache-purge-interval: 5m
kustomize_controller:
  args:
    concurrent: 10
    requeue-dependency: 5s
helm_controller:
  args:
    concurrent: 10
    requeue-dependency: 5s
```

## ytt overlays

Any Kubernetes resource of the package can be customized with a [ytt overlay](https://carvel.dev/ytt/docs/latest/ytt-overlays/). Store it in a Secret and reference it from the PackageInstall via the `ext.packaging.carvel.dev/ytt-paths-from-secret-name.0` annotation.

```shell
kubectl create secret generic flux-overlays -n kadras-system --from-file=overlays.yml
kubectl annotate packageinstall flux -n kadras-system \
  ext.packaging.carvel.dev/ytt-paths-from-secret-name.0=flux-overlays
```

All the controllers run in a container named `manager`.

### Resources

The upstream manifest sets resource requests and limits for each controller. The controllers derive their Go memory limit (`GOMEMLIMIT`) from the memory limit, so keep one.

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata": {"name": "kustomize-controller"}})
---
spec:
  template:
    spec:
      containers:
        #@overlay/match by="name"
        - name: manager
          resources:
            limits:
              cpu: 2000m
              memory: 2Gi
```

### In-memory builds

The kustomize controller builds the manifests in its `/tmp` directory. To speed up the builds, back it with memory, which counts towards the memory limit of the controller. See [vertical scaling](https://fluxcd.io/flux/installation/configuration/vertical-scaling/#enable-in-memory-kustomize-builds).

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata": {"name": "kustomize-controller"}})
---
spec:
  template:
    spec:
      volumes:
        #@overlay/match by="name"
        - name: temp
          emptyDir:
            #@overlay/match missing_ok=True
            medium: Memory
```

### Node placement

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment"}), expects=4
---
spec:
  template:
    spec:
      #@overlay/match missing_ok=True
      nodeSelector:
        node-restriction.kubernetes.io/reserved-for: platform
      #@overlay/match missing_ok=True
      tolerations:
        - key: node-restriction.kubernetes.io/reserved-for
          operator: Equal
          value: platform
          effect: NoExecute
```

Use `expects` to match the number of enabled controllers.

### Access to the artifacts

The upstream network policies only allow the Pods in the Flux namespace to download the artifacts served by the source controller. If workloads in other namespaces need them, allow their traffic with a NetworkPolicy in the Flux namespace, created with an overlay or separately. See [security.md](security.md#network-policies).

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-artifacts
  namespace: flux-system
spec:
  podSelector:
    matchLabels:
      app: source-controller
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: my-namespace
    ports:
    - protocol: TCP
      port: 9090
```

### Sharding

To scale beyond a single instance of a controller, Flux supports sharding: additional instances of the source, kustomize, and helm controllers, each reconciling the Flux resources labelled with its shard key. With the package, the main controllers ignore the sharded resources via their flags, and the shard Deployments are added as separate resources, or with an overlay. See [sharding](https://fluxcd.io/flux/installation/configuration/sharding/).

```yaml
source_controller:
  args:
    watch-label-selector: "!sharding.fluxcd.io/key"
kustomize_controller:
  args:
    watch-label-selector: "!sharding.fluxcd.io/key"
helm_controller:
  args:
    watch-label-selector: "!sharding.fluxcd.io/key"
```
