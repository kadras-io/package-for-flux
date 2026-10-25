# High Availability

The package runs 1 replica of each Flux controller, as recommended by Flux. The controllers follow an active/passive model based on leader election, so additional replicas would only be standby, without improving the throughput. Instead:

* the source controller and the source watcher store the artifacts they serve on a local volume, so additional replicas would serve artifacts they don't have;
* the controllers recover from a restart by reconciling the Flux resources again, while the workloads they manage keep running;
* a PodDisruptionBudget with a single replica would block the node drains, so the package doesn't create one.

To scale Flux, increase the concurrency and resources of the controllers ([vertical scaling](configuration.md#vertical-scaling)), or split the Flux resources among multiple instances of the controllers ([sharding](configuration.md#sharding)).

## Priority

All the controllers run with the `system-cluster-critical` [priority class](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/), since they reconcile the state of the cluster. The upstream `critical-pods` ResourceQuota allows this priority class in the Flux namespace, on clusters that only allow it in `kube-system` by default.

## Resources

Tune the resources with a ytt overlay, as described in [configuration.md](configuration.md#resources).
