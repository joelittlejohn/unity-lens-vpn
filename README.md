Unity VPN Lens
==============

This package provides a lens for the Ubuntu Unity Dash that searches and
launches VPN connections defined in the NetworkManager.

Installation
------------

Simply run

    $ python setup.py install

However, it is likely that you are using Ubuntu, so it is better to build the
package and install it properly. Check out the `ubuntu/precise` branch, build
the package and install it:

    $ git checkout ubuntu/precise
    $ debuild -I
    $ dpkg -i ../unity-lens-vpn*.deb

You'll need to have the [`devscripts`](http://apt.ubuntu.com/p/devscripts) and
[`python-distutils-extra`](http://apt.ubuntu.com/p/python-distutils-extra)
packages installed.
