# setup.sh

- Move DNS lookup to `setup.tools`, so that the IPs don't need to be
  specified explicitly when setup.d scripts are executed manually.

- Limit execution of `setup.d` contents to files that have names
  ending in `.sh` (or at least don't execute files with names ending
  in `~`). Files that are unfit for execution may exist in `setup.d`
  by accident, for example as backup files created by certain editors.
