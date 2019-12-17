#! /usr/bin/env nix-shell
#! nix-shell -i python -p "python3.withPackages (ps: with ps; [ lxml ])"

import base64
import json
import subprocess
from codecs import iterdecode
from os import scandir
from os.path import dirname, splitext
from lxml import etree
from lxml.etree import HTMLParser
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
with urlopen('https://cros-updates-serving.appspot.com/') as resp:
    document = etree.parse(resp, HTMLParser())

    # bgcolor="lightgreen" is set on the most up-to-date version for
    # each channel, so find a lightgreen cell in the "Stable" column.
    (platform_version, chrome_version) = document.xpath("""
        (//table[@id="cros-updates"]/tr/td[1 + count(
            //table[@id="cros-updates"]/thead/tr[1]/th[text() = "Stable"]
            /preceding-sibling::*)
        ][@bgcolor="lightgreen"])[1]/text()
    """)

chrome_major_version = match(r'\d+', chrome_version)[0]
chromeos_tip_build = match(r'\d+', platform_version)[0]

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
    xml = base64.decodebytes(resp.read())
    root = etree.fromstring(xml)
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
