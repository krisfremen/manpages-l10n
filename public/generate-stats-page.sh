#!/bin/sh
#
# Copyright © 2018-2019 Dr. Tobias Quathamer <toddy@debian.org>
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

# Clean all generated files
rm -f *html

# Create header, using MET/MEST
timestamp=$(TZ='Europe/Berlin' date "+%d.%m.%Y, %H:%M Uhr")

# Determine distribution names from upstream directory.
distributions=$(find ../upstream -maxdepth 1 -type d | cut -d/ -f3 | LC_ALL=C sort)
distribution_count=$(echo "$distributions" | wc --words)

# Determine manpage section names
manpage_sections=$(find ../po/man* -maxdepth 1 -type d | cut -d/ -f3 | LC_ALL=C sort)

# Use a tempfile for stats generation
tmppo=$(mktemp)

# Create the index file
cat > index.html <<-END_OF_HEADER
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <link rel="stylesheet" href="bootstrap.min.css">
    <title>Deutsche Übersetzung der Handbuchseiten</title>
  </head>
  <body>
    <div class="container-fluid">
      <h1>Liste der Dateien, die nicht vollständig übersetzt sind</h1>
      <p>Stand: $timestamp</p>
END_OF_HEADER

# Set up files for each distribution
for distribution in $distributions; do
  echo "<p><a class=\"btn btn-primary\" href=\"$distribution.html\">$distribution</a></p>" >> index.html

  cat > $distribution.html <<-END_OF_HEADER
  <!doctype html>
  <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
      <link rel="stylesheet" href="bootstrap.min.css">
      <title>Deutsche Übersetzung der Handbuchseiten</title>
    </head>
    <body>
  	  <div class="container-fluid">
        <h1>Liste der Dateien, die nicht vollständig übersetzt sind</h1>
        <h2>$distribution</h2>
        <p>Stand: $timestamp</p>
        <p>
          <a class="btn btn-primary" href="index.html">Übersicht</a>
        </p>
        <p>
          <a class="btn btn-primary" href="https://salsa.debian.org/manpages-de-team/manpages-de">Git-Repository ansehen</a>
        </p>
END_OF_HEADER

  for manpage_section in $manpage_sections; do
  	section_count=0
    table_rows=""
    translations=$(find "../po/$manpage_section" -name "*.po" | LC_ALL=C sort)
    for translation in $translations; do
      # Create a po file for the specific distribution
      LC_ALL=C msggrep --location="$distribution" "$translation" > "$tmppo"
      # Check if the file has a size > 0
      if [ -s "$tmppo" ]; then
        # Get the stats for that po file
        stats=$(LC_ALL=C msgfmt -cv -o /dev/null "$tmppo" 2>&1)
        # Get the translated messages
        translated=$(echo $stats | sed -e "s/\([0-9]\+\) translated message.*/\1/")
        # Check if there are at least two numbers
        fuzzy_or_untranslated=$(echo $stats | grep "[0-9]\+[^0-9]\+[0-9]\+")
        if [ -n "$fuzzy_or_untranslated" ]; then
        	# Remove the last text part
        	all=$(echo $stats | sed -e "s/[^0-9]\+$//")
        	# Replace all remaining text parts with the plus sign
        	all=$(echo $all | sed -e "s/[^0-9]\+/+/g")
        	# Calculate the sum
        	all=$(echo $all | bc)
        	# Calculate the percentage
        	percentage=$(echo "100 * $translated / $all" | bc)
        	# Calculate needed translations for 80%
        	needed=""
          highlight=""
        	if [ $percentage -lt 80 ]; then
        		needed=$(echo "(800 * $all / 100 + 9) / 10 - $translated" | bc)
            highlight="class=\"table-danger\""
        	fi
          table_rows=$(cat<<-EOF_ROW
          $table_rows
          <tr $highlight>
          <td>$(basename $translation .po)</td>
          <td class="text-right">$percentage%</td>
          <td class="text-right">$needed</td>
          <td>$stats</td>
EOF_ROW
)
          section_count=$(($section_count+1))
        fi
      fi
    done
    if [ $section_count -gt 0 ]; then
			cat >> $distribution.html <<-EOF_TABLE
			<table class="table table-striped table-bordered table-sm">
			  <thead class="thead-dark">
			    <tr>
			      <th scope="col" width="25%">Name</th>
			      <th scope="col" width="10%">Prozent</th>
			      <th scope="col" width="15%">Übersetzungen bis 80%</th>
			      <th scope="col" width="50%">Statistik</th>
			    </tr>
			  </thead>
			  <tbody>
EOF_TABLE
      echo $table_rows >> $distribution.html
      echo "</tbody>" >> $distribution.html
			echo "</table>" >> $distribution.html
      echo '<div class="alert alert-primary" role="alert">' >> $distribution.html
			if [ $section_count -eq 1 ]; then
				echo "1 Datei ist nicht vollständig übersetzt." >> $distribution.html
			else
				echo "$section_count Dateien sind nicht vollständig übersetzt." >> $distribution.html
			fi
      echo "</div>" >> $distribution.html
    fi
  done

  echo "</div>" >> $distribution.html
  echo "</body>" >> $distribution.html
  echo "</html>" >> $distribution.html
done

echo "</div>" >> index.html
echo "</body>" >> index.html
echo "</html>" >> index.html

rm $tmppo
