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

use POSIX 'locale_h';
use Locale::gettext;

my $name        = 'thunar-sendto-shredder';
my $config_path = "$ENV{HOME}/.config/$name";

sub get_version {
    return '0.01';
}

sub create {
    if ( !dir_exists() ) {
        warn "Creating config directory $config_path...\n";
        mkpath( $config_path, { verbose => 1, } );
    }

    if ( !config_exists() || !-z "$config_path/tss.conf" ) {
        warn "Creating config file ", "$config_path/tss.conf", "...\n";
        warn "Using defaults:\n";

        if ( open( my $f, '>:encoding(UTF-8)', "$config_path/tss.conf" ) ) {
            # Recursively remove contents
            print $f "Recursive=0\n";
            print "Recursive: FALSE\n";

            # Overwrite method: use simple by default.
            # List: simple, openbsd, dod, doe, gutmann, rcmp
            print $f "Write=Simple\n";
            print "Overwrite Method: Simple (single pass)\n";

            # Prompt with "Are you sure?"; by default TRUE
            print $f "Prompt=1\n";
            print "Use prompt before shredding: TRUE \n";

            close( $f );
        }
    }
}

sub get_conf_value {
    my $wanted = shift;

    open( my $f, '<:encoding(UTF-8)', "$config_path/tss.conf" )
        or do {
        popup( 'warning',
            "couldn't open configuration file for reading: $!\n" );
        return;
        };

    while ( <$f> ) {
        chomp;
        if ( /^$wanted=(.*?)$/ ) {
            return $1;
        }
    }
    close( $f );
}

sub set_value {
    my ( $key, $value ) = @_;

    # Temporary storage of values
    my %configs;

    open( my $r, '<:encoding(UTF-8)', "$config_path/tss.conf" )
        or do {
        popup( 'warning',
            "couldn't open configuration file for reading set values: $!\n" );
        return FALSE;
        };
    while ( <$r> ) {
        my ( $k, $v ) = split /=/, $_;
        chomp( $v );
        if ( $k eq $key ) {
            $configs{ $k } = $value;
            next;
        }
        $configs{ $k } = $v;
    }
    close( $r );

    open( my $w, '>:encoding(UTF-8)', "$config_path/tss.conf" )
        or do {
        popup( 'warning', "couldn't open file to save new settings: $!\n" );
        return FALSE;
        };
    while ( my ( $k, $v ) = each %configs ) {
        print $w "$k=$v\n";
    }
    close( $w );
    return TRUE;
}

sub dir_exists {
    if ( -d "$ENV{ HOME }/.config/$name" ) {
        return TRUE;
    } else {
        return FALSE;
    }
}

sub config_exists {
    if ( -f "$ENV{ HOME }/.config/$name/tss.config" ) {
        return TRUE;
    } else {
        return FALSE;
    }
}

sub get_images_path {
    return '/usr/share/pixmaps';
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
    popup( 'error', "couldn't find secure remove (srm)" );
    return FALSE;
    die "no shred found!\n";
}

sub popup {
    my ( $type, $message ) = @_;

    my $p = Gtk3::MessageDialog->new( $window, qw| destroy-with-parent |,
        $type, 'ok', $message, );
    $p->run;
    $p->destroy;

}

1;
