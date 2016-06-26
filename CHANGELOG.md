1.3.12-r3:
- Update: Deluge 1.3.12 (git-34e12fcb38bb9e555116a89a2f6813dd402aaa08)
- Update libraries
- Add SSL support for the Python virtualenv
- Switch from LD_LIBRARY_PATH to using runpath instead

1.3.12-r2:
- Add ARM support!
- Update: Deluge 1.3.12 (git-86b1b75fb8f4bfe565f66e6112bbe5d54cdc8b23)
- Updated dependencies

1.3.12-r1:
- Update: Deluge 1.3.12 (git-560318a5a7c7a263442dd936415cb3d6a4e9ad7a)

1.3.12:
- Update: Deluge 1.3.12 (git-099a4eb8c62e33e003fb2cb44ff1e3cec6aa3564)
- Fix: Deluge logging
- Fix: Deluge did not start during boot
- Fix: upgrade / uninstall bug (Deluge wasn't stopped properly)

1.3.11-r1:
- Update: libtorrent-rasterbar 1.0.6
- Fix: works with python 2.7.10
- Fix: restarting of service

1.3.11:
- Update: Deluge 1.3.11
- Fix: Remove Deluge configuration when uninstalling app

1.3.10:
- Deluge: Security update for POODLE vulnerability

1.3.9:
- Update: Deluge 1.3.9
- Update: libtorrent-rasterbar 0.16.17
- Fix Deluge config directory permissions
- Create files with world read/write permissions to prevent cases where a user could not move/delete files.

1.3.7-r2:
- Rewrote start-stop script for better control
- Added back the Python dependency
- Included binaries for unrar and p7zip

1.3.7-r1:
- Fixed a bug with filenames being wrongly encoded by Python
- Switch back to using ASUSTOR Python package

1.3.7:
- Update Deluge to the official 1.3.7 release.

1.3.6:
- Initial release for ADM, based on 1.3-stable branch.

Changelog can be found at: http://git.deluge-torrent.org/deluge/log/?h=1.3-stable
