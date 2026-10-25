# Upgrading

Upgrade Flux one minor version at a time, and read the [upgrade guide](https://fluxcd.io/flux/installation/upgrade/) and the [release notes](https://github.com/fluxcd/flux2/releases) of each version first. The Flux controllers are only compatible with the controllers of the same minor version, so they are always upgraded together.

```shell
kctrl package installed update -i flux -v ${VERSION} -n kadras-system
```

Each Flux minor version can remove API versions of its CRDs. Before upgrading, migrate the Flux resources stored in Git with `flux migrate -f <path>`, and the ones stored in the cluster with `flux migrate`, using the [Flux CLI](https://fluxcd.io/flux/cmd/) of the target version. Otherwise, the CRDs can't be updated.

## Uninstalling

The Flux resources have finalizers, handled by the controllers: deleting a Kustomization or a HelmRelease while the controllers run deletes the workloads it applied. Uninstalling the package doesn't delete them. Like `flux uninstall --keep-namespace`, it keeps the CRDs and the Flux namespace, with all the Flux resources and the workloads they manage, and only deletes the controllers. Installing the package again resumes the reconciliation. The same applies to the CRDs of a controller that is disabled.

To also delete the Flux resources, without deleting the workloads, run the [Flux CLI](https://fluxcd.io/flux/installation/uninstall/) after uninstalling the package. It removes the finalizers, the Flux resources, the CRDs, and the namespace.

```shell
flux uninstall --namespace flux-system
```

To delete the workloads managed by Flux too, delete the Flux resources before uninstalling the package, while the controllers still run.
