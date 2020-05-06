setup.sh
========

Script framework to help setup a Debian Linux box.

Upon execution, `setup.sh` will run all setup scripts inside the
`setup.d` directory.

The `setup.d` scripts have certain tools available to them that
may make configuration easier (`setup.tools`). One such tool is
`setup_copy`, which copies a config file specified by path (e. g.
`/etc/postfix/virtual-mysql.cf`) from the setup directory to the
corresponding position in the file system.

`setup.sh` supports two separate directory trees as source for
configuration files and scripts. *This* repository represents the
"global" tree, which contains settings that are similar or identical
for many hosts. A "local" tree should be added to configure a
specific host.

`setup.sh` will automatically detect whether a config file or script
is available only in the global tree, only in the local tree, or
available in both. In the latter case, preference will be given to
the local tree.

`setup.sh` runs all `setup.d` scripts in the same shell execution
environment using the `.` command. This means that it's possible
to set an environment variable in one script and use it in another
script. However, if execution of `setup.sh` is aborted due to an
error condition, the environment will be lost and such variables
may have to be set manually using `export`.


Prerequisites
-------------

This version of `setup.sh` is designed for Debian 10 "buster".

When executed, `setup.sh` expects the following:

- `$HOSTNAME_VPS` contains the host's fully-qualified domain name
- The FQDN resolves to `A` and `AAAA` records
- `$SETUPPATH` contains the file system path to the "local" tree
- The "local" tree contains the files:
  - `credentials.private` (with passwords and user accounts)
  - `backup.tar` (backup of databases and server configuration)
  - `srv.tar` (backup of `/srv` data)

The environment variables are best supplied by a shell script in
the "local" tree (see `setup.example/setup.sh`).


Using setup.sh for custom hosts
-------------------------------

First of all, you need to understand that this repository's `master`
branch may change at an time in a way that is not compatible with
your situation. As a user of setup.sh, you are encouraged to **clone
or fork this repository,** create a new branch in your clone or fork
and only work with the "local" tree inside a new custom directory in
that branch. This insulates your project from any upstream changes.
For a demonstration of how this custom directory may look, see
`setup.example`.

Another safe option might be to use this repository (or a fork) as
a git submodule to your own project's repository. But this might
be a bit harder to use.


Rationale
---------

`setup.sh` is not only useful for setting up a host for the first
time. It can also be used as part of an emergency response plan:
In case normal operation of the host is seriously disrupted, you
can simply start over with a clean slate. Assuming a current backup
is available, `setup.sh` will quickly bring the host into a defined
safe state.

However, note that upstream changes to the software used on the
host may cause trouble. Major updates to the OS distribution are
a particular problem. Frequent trials of `setup.sh` in a testing
environment should help to identify and fix any issues early.


Copying
-------

First version of `setup.sh` written in 2014 by Arne Johannessen.

No rights reserved.  
See LICENSE for details.

