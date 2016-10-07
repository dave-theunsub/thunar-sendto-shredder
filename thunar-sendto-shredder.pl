#!/usr/bin/perl
#
# thunar-sendto-shredder, copyright (C) 2016 Dave M
#
# This file is part of thunar-sendto-shredder.
# https://dave-theunsub.github.io/thunar-sendto-shredder/
#
# thunar-sendto-shredder is free software; you can redistribute
# it and/or modify it under the terms of either:
#
# a) the GNU General Public License as published by the Free Software
# Foundation; either version 1, or (at your option) any later version, or
#
# b) the "Artistic License".
#

use strict;
use warnings;
$| = 1;

use lib '.';
# Config.pm: used for getting/setting system or user information
use Shredder::Config;

# GUI.pm: used for the shredding dialog / progressbar (UI)
use Shredder::GUI;

# Preferences.pm: used for system settings UI
use Shredder::Preferences;

# Version.pm: version and about information
use Shredder::Version;

# Incoming files - or not.
my @objects = @ARGV;

# See if the Config directory has been created
if ( !Shredder::Config::dir_exists ) {
    Shredder::Config::create();
}

# If we're not given files, bring up the Settings interface.
if ( !scalar( @objects ) ) {
    Shredder::Settings::show_window();
}

# Is prompt set to yes?
if ( Shredder::Config::get_conf_value( 'Prompt' ) ) {

    # Bring up GUI interface; we likely have stuff to shred
    Shredder::GUI::show_window();

    # End.
