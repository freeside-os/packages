# fstools package

Freeside Developer and Builder Tools package. Contains the consolidated `fstools` utility in the builder group.

## Upgrade Notes
- Sandbox corruption issue fixed by forcing `straylight` to re-extract `sandbox-root.tgz`.
- Added `fspack.py` shim to correctly route package verification commands to the new consolidated `fstools` binary.
