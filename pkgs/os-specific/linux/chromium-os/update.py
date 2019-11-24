#! /usr/bin/env nix-shell
#! nix-shell -p python3 -i python

import base64
import csv
import json
import subprocess
import xml.etree.ElementTree as ElementTree
from codecs import iterdecode
from operator import itemgetter
from os import scandir
from os.path import dirname, splitext
from re import MULTILINE, fullmatch, match, search
from urllib.request import urlopen

# ChromiumOS components used in Nixpkgs
components = [
    'aosp/platform/external/libchrome',
    'aosp/platform/external/modp_b64',
    'chromiumos/overlays/chromiumos-overlay',
    'chromiumos/platform/crosvm',
    'chromiumos/platform2',
    'chromiumos/third_party/adhd',
    'chromiumos/third_party/kernel',
    'chromiumos/third_party/modemmanager-next',
]

git_root = 'https://chromium.googlesource.com/'
manifest_versions = f'{git_root}chromiumos/manifest-versions'
buildspecs_url = f'{manifest_versions}/+/refs/heads/master/paladin/buildspecs/'

# CrOS version numbers look like this:
# [<chrome-major-version>.]<tip-build>.<branch-build>.<branch-branch-build>
#
# As far as I can tell, branches are where internal Google
# modifications are added to turn Chromium OS into Chrome OS, and
# branch branches are used for fixes for specific devices.  So for
# Chromium OS they will always be 0.  This is a best guess, and is not
# documented.
with urlopen('https://cros-omahaproxy.appspot.com/all') as resp:
    versions = csv.DictReader(iterdecode(resp, 'utf-8'))
    stables = filter(lambda v: v['track'] == 'stable-channel', versions)
    stable = sorted(stables, key=itemgetter('chrome_version'), reverse=True)[0]

chrome_major_version = match(r'\d+', stable['chrome_version'])[0]
chromeos_tip_build = match(r'\d+', stable['chromeos_version'])[0]

# Find the most recent buildspec for the stable Chrome version and
# Chromium OS build number.  Its branch build and branch branch build
# numbers will (almost?) certainly be 0.  It will then end with an rc
# number -- presumably these are release candidates, one of which
# becomes the final release.  Presumably the one with the highest rc
# number.
with urlopen(f'{buildspecs_url}{chrome_major_version}/?format=TEXT') as resp:
    listing = base64.decodebytes(resp.read()).decode('utf-8')
    buildspecs = [(line.split('\t', 1)[1]) for line in listing.splitlines()]
    buildspecs = [s for s in buildspecs if s.startswith(chromeos_tip_build)]
    buildspecs.sort(reverse=True)
    buildspec = splitext(buildspecs[0])[0]

revisions = {}

# Read the buildspec, and extract the git revisions for each component.
with urlopen(f'{buildspecs_url}{chrome_major_version}/{buildspec}.xml?format=TEXT') as resp:
    xml = base64.decodebytes(resp.read()).decode('utf-8')
    root = ElementTree.fromstring(xml)
    for project in root.findall('project'):
        revisions[project.get('name')] = project.get('revision')

# Initialize the data that will be output from this script.  Leave the
# rc number in buildspec so nobody else is subject to the same level
# of confusion I have been.
data = {'version': f'{chrome_major_version}.{buildspec}', 'components': {}}

paths = {}

# Fill in the 'components' dictionary with the output from
# nix-prefetch-git, which can be passed straight to fetchGit when
# imported by Nix.
for component in components:
    name = component.split('/')[-1]
    url = f'{git_root}{component}'
    rev = revisions[component]
    tarball = f'{url}/+archive/{rev}.tar.gz'
    output = subprocess.check_output(['nix-prefetch-url', '--print-path', '--unpack', '--name', name, tarball])
    (sha256, path) = output.decode('utf-8').splitlines()
    paths[component] = path
    data['components'][component] = {
        'name': name,
        'url': url,
        'rev': rev,
        'sha256': sha256,
    }

# Get the version number of libchrome.
chromiumos_overlay = paths['chromiumos/overlays/chromiumos-overlay']
contents = scandir(f'{chromiumos_overlay}/chromeos-base/libchrome')
libchrome_version = lambda name: fullmatch(r'libchrome-(\d+)\.ebuild', name)[1]
ebuilds = [f for f in contents if f.is_file(follow_symlinks=False)]
versions = [libchrome_version(f.name) for f in ebuilds]
latest = sorted(versions, key=int)[-1]
data['components']['aosp/platform/external/libchrome']['version'] = latest

# Get the version number of the kernel.
kernel = paths['chromiumos/third_party/kernel']
makefile = open(f'{kernel}/Makefile').read()
version = search(r'^VERSION = (.+)$', makefile, MULTILINE)[1]
patchlevel = search(r'^PATCHLEVEL = (.*?)$', makefile, MULTILINE)[1]
sublevel = search(r'^SUBLEVEL = (.*?)$', makefile, MULTILINE)[1]
extra = search(r'^EXTRAVERSION =[ \t]*(.*?)$', makefile, MULTILINE)[1]
full_ver = '.'.join(filter(None, [version, patchlevel, sublevel])) + extra
data['components']['chromiumos/third_party/kernel']['version'] = full_ver

# Finally, write the output.
with open(dirname(__file__) + '/upstream-info.json', 'w') as out:
    json.dump(data, out, indent=2)
    out.write('\n')
