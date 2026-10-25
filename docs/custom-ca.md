# Custom Certificate Authorities

If Flux needs to reach services with certificates signed by a private certificate authority, like a private Git server, OCI registry, or Helm repository, add the PEM-encoded certificates of the authority to the package values.

```yaml
ca_cert_data: |
  -----BEGIN CERTIFICATE-----
  MIICvjCCAaYCCQDhcJuwMw6yZzANBgkqhkiG9w0BAQsFADAhMQswCQYDVQQGEwJE
  ...
  -----END CERTIFICATE-----
```

The certificates are stored in the `flux-ca-certificates` Secret and mounted in all the controllers, which trust them in addition to the system certificate authorities.

To trust a certificate authority for a single source instead, reference a Secret with the `ca.crt` key from the `spec.certSecretRef` field of the Flux resource. See [GitRepository](https://fluxcd.io/flux/components/source/gitrepositories/#cert-secret-reference) and [OCIRepository](https://fluxcd.io/flux/components/source/ocirepositories/#cert-secret-reference).
