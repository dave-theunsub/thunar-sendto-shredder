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
package Shredder::Update;

use strict;
use warnings;
use Glib 'TRUE', 'FALSE';
$| = 1;

use LWP::UserAgent;

use POSIX 'locale_h';
use Locale::gettext;

# my $homepage = 'https://dave-theunsub.github.io/thunar-sendto-shredder/';

sub check_gui {
    my $local_version = Shredder::Config->get_version;
    my $remote_version;

    my $url
        = 'https://bitbucket.org/dave_theunsub/thunar-sendto-shredder/raw/master/latest';

    # LWP::UserAgent;
    # keeping this part separate in case we
    # have to support all kinds of proxy options later
    my $ua = build_ua();

    Gtk3::main_iteration while Gtk3::events_pending;
    my $response = $ua->get( $url );
    Gtk3::main_iteration while Gtk3::events_pending;

    if ( $response->is_success ) {
        $remote_version = $response->content;
        chomp( $remote_version );
    } else {
        return '';
    }

    my ( $local_chopped, $remote_chopped );
    ( $local_chopped  = $local_version ) =~ s/[^0-9]//;
    ( $remote_chopped = $remote_version ) =~ s/[^0-9]//;

    # warn: REMOVE ME
    return TRUE;
    # Sanity check to ensure we received an answer.
    # Return TRUE for update available,
    # also the version number
    if ( $local_chopped && $remote_chopped ) {
        if ( $remote_chopped > $local_chopped ) {
            return ( TRUE, $remote_version );
        }
    }
    return FALSE;
}

sub build_ua {
    my $agent = LWP::UserAgent->new( ssl_opts => { verify_hostname => 1 } );
    $agent->timeout( 15 );
    $agent->protocols_allowed( [ 'http', 'https' ] );

    return $agent;
}

1;
