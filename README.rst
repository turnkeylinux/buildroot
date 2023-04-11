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


Build buildroot for transition (new release)
--------------------------------------------

This assumes that the TurnKey dependencies are not yet available via the
TurnKey apt repo. If the source code isn't already available locally
(in '/turnkey/public/${pkg}') it will be cloned from GitHub.::

    export RELEASE=debian/::CODENAME::
    make clean
    make transition

Then install the required packages::

    PACKAGES="turnkey-gitwrapper verseek autoversion"
    mkdir -p build/root.patched/root/builddeps
    for pkg in ${PACKAGES}; do
        LOCAL="/turnkey/public/${pkg}"
        mkdir -p $(dirname ${LOCAL})
        if [[ ! -d "${LOCAL}" ]]; then
            GH_URL=https://github.com/turnkeylinux/${pkg}.git
            git clone ${GH_URL} ${LOCAL}
        fi
        cp -a ${LOCAL} build/root.patched/root/builddeps
    done

    mkdir build/root.patched/root/builddeps
    fab-chroot build/root.patched
    for pkg in $PACKAGES; do
        cd /root/builddeps/${pkg}
        build-deb
        dpkg -i ../${pkg}*.deb || apt --fix-broken install
    done

    rm -rf /root/builddeps
    exit


Copy generated buildroot to buildroots folder
---------------------------------------------

Once the buildroot is complete, then it needs to be copied to the desired
localation (default: ${FAB_PATH}/buildroots/::CODENAME::).::

    RELEASE=${RELEASE:-debian/$(lsb_release -sc)}
    mkdir -p ${FAB_PATH}/buildroots/$(basename $RELEASE)
    rsync --delete -Hac -v build/root.patched/ $FAB_PATH/buildroots/$(basename $RELEASE)/

.. _bootstrap: https://github.com/turnkeylinux/bootstrap
