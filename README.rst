build
=====

A buildroot is a root filesystem designed to be used as a chroot to build
packages within.

It assumes that you have already configured a bootstrap. This should already
exist on TKLDev by default. Otherwise please see the `bootstrap`_ repo.

Build buildroot for current release
-----------------------------------

This requires that the TurnKey dependencies have been built and uploaded to the
TurnKey repos.::

    make clean
    make

By default ``make`` builds to the ``pkg_install`` target, if you intend on using
this buildroot directly, you can build straight to the ``install`` target (which
installs the buildroot to ``$FAB_PATH/buildroots/$(basename $RELEASE)``::

    make install

Build buildroot for transition (new release)
--------------------------------------------

This assumes that the TurnKey dependencies are not yet available via the
TurnKey apt repo. If the source code isn't already available locally
(in '/turnkey/public/${pkg}') it will be cloned from GitHub.::

    export RELEASE=debian/::CODENAME::
    make clean
    make

Note by default this assumes the turnkeylinux repos are not available so will
build each of the dependencies from source.

Copy generated buildroot to buildroots folder
---------------------------------------------

Once the buildroot is complete, then it needs to be copied to the desired
location (default: ${FAB_PATH}/buildroots/::CODENAME::).

Whether building a transition or not the ``install`` target does this for you::

    make install

.. _bootstrap: https://github.com/turnkeylinux/bootstrap
