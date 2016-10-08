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
package Shredder::Config;

use File::Path 'mkpath';
use Glib 'TRUE', 'FALSE';

my $name        = 'thunar-sendto-shredder';
my $config_path = "$ENV{HOME}/.config/$name";

sub get_version {
    return '0.01';
}

sub create {
    if ( !dir_exists() ) {
        warn "Creating config directory...\n";
        mkpath( $config_path, { verbose => 1, } );
    }

    if ( !config_exists() ) {
        warn "Creating config file...\n";

        if ( open( my $f, '>:encoding(UTF-8)', "$config_path/tss.conf" ) ) {
            # Recursively remove contents
            print $f "Recursive=1\n";

            # Overwrite method: simple is default
            # simple, openbsd, dod, doe, gutmann, rcmp
            print $f "Write=--simple\n";

            # Prompt with "Are you sure?"; by default TRUE
            print $f "Prompt=1\n";

            close( $f );
        }
    }
}

sub get_conf_value {
    my $wanted = shift;

    open( my $f, '<:encoding(UTF-8)', "$config_path/tss.conf" )
        or do {
        warn "couldn't open tss.conf: $!\n";
        die;
        };

    warn "opened!\n";
    while ( <$f> ) {
        warn "reading stuff\n";
        chomp;
        if ( /^$wanted=(.*?)$/ ) {
            warn "1 = >$1<\n";
            return $1;
        }
    }
    close( $f );
}

sub set_value {
        my ( $object, $value ) = @_;
}

sub dir_exists {
    if ( -d "$ENV{ HOME }/.config/$name" ) {
        warn "config dir exists!\n";
        return TRUE;
    } else {
        warn "config dir NOT exist!\n";
        return FALSE;
    }
}

sub config_exists {
    if ( -f "$ENV{ HOME }/.config/$name/tss.config" ) {
        warn "config file exists!\n";
        return TRUE;
    } else {
        warn "config file NOT exist!\n";
        return FALSE;
    }
}

sub get_images_path {
    # return '/usr/share/pixmaps';
    return '/home/dave/oop/developer/thunar-sendto-shredder-0.01/images';
}

sub get_shred_path {
    my $path = '';

    if ( open( my $p, '-|', 'which srm' ) ) {
        while ( <$p> ) {
            chomp;
            $path = $_ if ( -e $_ );
        }
    }

    return $path if ( $path );
    die "no shred found!\n";
}

1;
