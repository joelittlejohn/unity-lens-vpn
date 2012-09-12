# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# vim: filetype=python fenc=utf-8 expandtab shiftwidth=4 :
### BEGIN LICENSE
# Copyright (C) 2012 Michael Wild <themiwi@users.sourceforge.net>
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
### END LICENSE

import logging
import optparse

import gettext
from gettext import gettext as _
gettext.textdomain('unity-lens-vpn')

import dbus

from singlet.lens import SingleScopeLens, IconViewCategory, ListViewCategory

from unity_lens_vpn import unity_lens_vpnconfig

class VpnLens(SingleScopeLens):

    class Meta:
        name = 'vpn'
        description = 'VPN Lens'
        search_hint = 'Activate and deactivate VPN connections'
        icon = 'network-vpn-symbolic'
        search_on_blank=True

    vpn_category = ListViewCategory("VPN Connections", 'network-vpn-symbolic')

    _BUS_ID = 'org.freedesktop.NetworkManager'
    _ROOT_PATH = dbus.ObjectPath('/')
    _NM_PATH = '/org/freedesktop/NetworkManager'
    _SETTINGS_PATH = _NM_PATH + '/Settings'
    _BUS = dbus.SystemBus()

    def __init__(self):
        SingleScopeLens.__init__(self)
        self._lens.props.search_in_global = True

    def global_search(self, search, results):
        if len(search):
            self.search(search, results)

    def search(self, search, results):
        settings = self._BUS.get_object(self._BUS_ID, self._SETTINGS_PATH)
        for c in settings.ListConnections():
            conn = self._BUS.get_object(self._BUS_ID, c).GetSettings()['connection']
            name = conn['id']
            if conn['type'] == 'vpn' and name.lower().count(search.lower()):
                results.append(str(c),
                    'network-vpn-symbolic',
                    self.vpn_category,
                    'application/x-vpn',
                    name,
                    '%s VPN connection'%name,
                    '')

    def handle_uri(self, scope, uri):
        nm = self._BUS.get_object(self._BUS_ID, self._NM_PATH)
        nm.ActivateConnection(dbus.ObjectPath(uri), self._ROOT_PATH, self._ROOT_PATH)
        return self.hide_dash_response()
