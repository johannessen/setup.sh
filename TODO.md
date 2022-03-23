# setup.sh

- Move DNS lookup to `setup.tools`, so that the IPs don't need to be
  specified explicitly when setup.d scripts are executed manually.

- Limit execution of `setup.d` contents to files that have names
  ending in `.sh` (or at least don't execute files with names ending
  in `~`). Files that are unfit for execution may exist in `setup.d`
  by accident, for example as backup files created by certain editors.

- Add a mechanism to allow for passing environment variables between setup
  scripts using persistent storage, to avoid their values being lost in
  case of interruption / manual script execution. This mechanism could
  conceivably work in a similar fashion as `setup_insecure_password`; the
  variable storage file would then have to be sourced on the next setup run
  (if it exists).

- Investigate `cpm` to speed up Perl module installation after the brew.
