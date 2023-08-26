# Configuring High Availability

The Flux controllers supports high availability following an active/passive model based on the leader election strategy. Since only one instance performs work at any given time, one replica for each Pod is enough.

The leader election strategy is enabled by default. You can read more about [vertical scaling](https://fluxcd.io/flux/installation/configuration/vertical-scaling/) and [horizontal scaling](https://fluxcd.io/flux/installation/configuration/sharding/) in the Flux official documentation.
