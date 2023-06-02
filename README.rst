build
=====

A buildroot is a root filesystem designed to be used as a chroot to build
packages within.

It assumes that you have already configured a bootstrap. This should already
exist on TKLDev by default. Otherwise please see the `bootstrap`_ repo.

Build buildroot for current release
-----------------------------------

This requires that the TurnKey dependencies have been built and uploaded to the
TurnKey repos (this should generally be the case).::

    make clean
    make

By default ``make`` builds to the ``pkg_install`` target, if you intend on using
this buildroot directly, you can build straight to the ``install`` target (which
installs the buildroot to ``$FAB_PATH/buildroots/$(basename $RELEASE)``::

    make install

Build buildroot for transition (new release)
--------------------------------------------

When doing a distro transition (i.e. preparing for a new major version release
- e.g. moving from one Debian release to the next), things are a little less
straight forward. There are a number of TurnKey specific packages that are
required and may not yet be built. If it's very early in the release, then the
relevant TurnKey repos may not even exist yet.

Before the relevant TurnKey apt repos exist, all TurnKey apt repos can be
disabled by setting NO_TURNKEY_APT_REPO=y (all TKL apt lines will be commented
out). E.g.::

    export RELEASE=debian/::CODENAME::
    make clean
    NO_TURNKEY_APT_REPO=y make install

Note that this will build each of the TurnKey dependencies from source. If the
source code isn't already available locally (in '/turnkey/public/${pkg}') it
will be cloned there from GitHub.

If all the required TurnKey dependencies are available, but only in the
turnkey-testing repo (as is likely early in the transition process), then
set TKL_TESTING=y. E.g.::

    export RELEASE=debian/::CODENAME::
    make clean
    TKL_TESTING=y make install

If the TurnKey apt repos exist and the relevant packages are in the main
TurnKey apt repo, then beyond the need to set the RELEASE, building for a
transition is essentially the same as a normal build. I.e.::

    export RELEASE=debian/::CODENAME::
    make clean
    make install

Copy generated buildroot to buildroots folder
---------------------------------------------

Once the buildroot is built, then it needs to be copied to the desired
location (default: ${FAB_PATH}/buildroots/::CODENAME::).

As noted above, whether building a transition or not the ``install`` target
does this for you. I.e.::

    make install

.. _bootstrap: https://github.com/turnkeylinux/bootstrap
