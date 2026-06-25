# podman

Daemonless container engine for developing, managing, and running OCI Containers

## Upgrade Notes
- Go compiler is dynamically fetched during the build phase since a system `go` package doesn't exist in the repositories yet.
- `BUILDTAGS` are specifically configured to exclude dependencies on `gpgme` and `libseccomp`, as well as `btrfs` and `devicemapper` (`containers_image_openpgp exclude_graphdriver_btrfs exclude_graphdriver_devicemapper`).