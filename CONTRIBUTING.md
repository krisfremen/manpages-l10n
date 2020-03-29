# Contributing to the manpages-l10n project

As described in the file README.md, the manpages-l10n project provides a
suitable infrastructure for man page translations. Here we describe the
workflow of fetching the upstream man pages, translating and finally publishing
the translations.


## Getting the upstream man pages

We support multiple distributions. To get the upstream man pages, we maintain
package lists for each distribution in
upstream/*distribution_name*/packages.txt. Usually we download all the listed
packages once or twice a month and unpack the man pages, using the script
upstream/update-distribution-manpages.sh. This script puts also the links
together so that they don't appear later as translatable files.

To get an overview which man pages are available from the supported packages,
but are still untranslated, the files
upstream/*distribution_name*/untranslated.txt will be created. For historical
reasons, this works only for German, but one happy day we'll find a solution for
all languages ;)


## Creating the templates

After updating the contents of upstream/*distribution_name*/man*, we create the
templates. The script templates/update-all-templates.py updates the existing
\*.pot files based on the new upstream man pages. You can run the script
templates/generate-one-template.sh to generate a new or to update an existing
template.


## Updating the translations

Run the command po/update-translations.py to update the existing \*.po files,
based on the previously changed templates. Later you can run
po/*your_language_code*/update-po.sh to update a single .po file or
po/*your_language_code*/update-translations.sh to update all existing .po files
from the current templates and compendium files (see below for how to use the
compendium).


## Use consistent file headers

The header of a .po file usually looks as follows:

~~~
# German translation of manpages
# This file is distributed under the same license as the manpages-l10n package.
# Copyright © of this file:
# Mario Blättermann <mario.blaettermann@gmail.com>, 2015.
~~~

The first three lines will be added automatically if they don't exist. But from
the fourth line on, you must not write other lines than those with translator
names, mail adresses and the copyright year. Otherwise, some of our scripts
won't work properly. The script »po/*your_language_code*/generate-manpage.sh«
needs this for generate the addendum. The script create-authors-file.sh also
reads translator names from there and would produce garbage if there are some
additional lines.

One exception: Comment lines starting with # FIXME will be ignored by the
scripts. But maybe it is more useful to put such FIXMEs directly above the
affected Gettext messages.


## Git workflow for reviewed .po files

After translating and reviewing a .po file (assuming you was using a copy of
that file and haven't applied your changes directly in your local Git checkout),
you should do the following steps:

* Run »git pull« to get the latest changes from other submitters.
* Verify your .po file with »msgfmt -vc«.
* Put your .po file at the right place in the Git hierarchy (don't commit it for
  the time being).
* Run »git status« and/or »git diff« to see what would be changed.
* Run the script po/*your_language_code*/update-po.sh to merge your .po file
  with the latest template and the messages from compendium. Now you should take
  a look again at the .po file. If there's something wrong, fix it.
* Commit your .po file. The command should look as follows:

~~~
git commit -a -m "[de] Update chown.1.po"
~~~

* To make it easier to distinguish between the different languages, prepend
  [your_language_code] to the commit message.
* Run »git push«. Normally, all should be fine after typing your SSH password.
  But in some cases, another contributor has applied some changes in the
  meantime. Then Git refuses the commit. Just run »git pull« first. This applies
  the remote changes to your local repo and opens an editor where you can change
  the commit message. In most cases, it is unneeded to change anything, just
  close the editor (after saving the message, if needed).
  
  
## Using the helper scripts

### Creating new translations

The script po/*your_language_code*/create-new-translation.sh creates a new .po
file. This presupposes that the original Groff or Mdoc file already exists in
upstream/man\* for at least one of our supported distributions. Besides the .po file
creation, it creates - if needed - a template and updates the compendium
templates in templates/common/ and the compendium files for your language in
po/*your_language_code*/common. The script never affects other languages than
your own.


### Fill and use the compendium

After reviewing and committing a .po file, you can run
po/*your_language_code*/use-for-compendium.sh to add the previously reviewed
Gettext messages to your compendium. Example:
»use-for-compendium.sh man1/chown.1.po«. This makes sense if your .po file
contains some messages which also appear in other .po files. The script
recognizes messages with at least two occurences in our man page collection.
Note, you always have to submit the relative path, a simple file name isn't
sufficient.

After adding the file to the compendium, you can write the changes back to all
.po files with the command po/*your_language_code*/update-translations.sh.


### Formatting \*.po files

The script po/*your_language_code*/format-po.sh formats all .po files of your
language as »msgcat -w 80« would do; it wraps all lines at 80 characters.
Besides that, the unused Gettext messages at the end of the .po files will be
removed. Note, this script expects proper .po files; run
»msgfmt -vc *your_po_file*« to make sure the file is properly formatted in terms
of Gettext. Otherwise, the script can destroy a file completely and you need to
revert the changes.


### Generating translated man pages

A single translated man page can be created with the command
»po/*your_language_code*/generate-manpage.sh *distribution_name* *your_po_file*«,
for example »po/*your_language_code*/generate-manpage.sh archlinux man1/chown.1.po«.
This creates the man page in a subdirectory named »archlinux«. But you can also
generate all man pages from the whole .po collection using the command
»po/*your_language_code*/generate-all-manpages.sh *distribution_name*«. All the
generated man pages get an addendum, which consists of the translators names and
mail addresses as found in the .po file headers, and a license declaration,
taken from the file po/*your_language_code*/license.add.

