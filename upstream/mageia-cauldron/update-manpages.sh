#!/bin/sh
#
# Copyright © 2019 Dr. Tobias Quathamer <toddy@debian.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Start with clean directories and no leftover links.txt
rm -rf man* links.txt untranslated.txt

# Download HTML page
page=$(mktemp)
cpio_archive=$(mktemp)
wget --quiet -O "$page" "https://ftp-stud.hs-esslingen.de/pub/Mirrors/Mageia/distrib/cauldron/x86_64/media/core/release/"

# Process packages
while read package; do
	mkdir tmp

  # Discover the correct link in HTML page
	echo "Downloading and updating package '$package'"
  url=$(grep "\"$package-[0-9][^\"]*\.rpm[^.]" "$page" |
  sed -e "s,.*<a href=\"\($package-[^\"]*\).*,\1,")

  url="https://ftp-stud.hs-esslingen.de/pub/Mirrors/Mageia/distrib/cauldron/x86_64/media/core/release/$url"
  wget --quiet --directory-prefix=tmp/downloads "$url"

	# Update the manpages from the package
	latest_rpm=$(ls tmp/downloads/$package-*.rpm)
	if [ -z $latest_rpm ]; then
		echo "Warning: Could not find .rpm for package '$package'"
	else
		rpm2cpio $latest_rpm > $cpio_archive
		cd tmp && bsdcpio -i --make-directories < "$cpio_archive"
		cd ..
		../move-manpages.sh "$package"
	fi
	# Finally, remove the tarball, so that the regexp
	# matching does not match the wrong tarball.
	# See pacman and pacman-contrib for an example.
	rm -rf tmp
done < packages.txt
rm "$page" "$cpio_archive"
