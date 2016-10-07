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
package Shredder::GUI;

use strict;
use warnings;
$| = 1;

use Gtk3 '-init';
use Glib 'TRUE', 'FALSE';
use File::Find;

sub show_window {
    my @objects = @_;
    warn "in gui - got >$_<\n" for ( @_ );

    my $window = Gtk3::Window->new( 'toplevel' );
    $window->signal_connect( 'destroy' => sub { Gtk3->main_quit } );

    my $box = Gtk3::Box->new( 'horizontal', 5 );
    $window->add( $box );

    my $header = Gtk3::HeaderBar->new;
    $window->set_titlebar( $header );
    $header->set_title( 'File shredder' );
    $header->set_subtitle( 'Securely erase files!' );
    $header->set_show_close_button( TRUE );
    $header->set_decoration_layout( 'menu:minimize,close' );

    my $btn = Gtk3::Button->new_from_icon_name( 'gtk-about', 3 );
    $btn->signal_connect( clicked => \&about );
    $header->pack_start( $btn );

    $btn = Gtk3::Button->new_from_icon_name( 'gtk-quit', 3 );
    $btn->signal_connect( clicked => sub { Gtk3->main_quit } );
    $header->pack_start( $btn );

    my $label = Gtk3::Label->new( '' );
    $box->pack_start( $label, FALSE, FALSE, 0 );

    my $pb            = Gtk3::ProgressBar->new;
    my $pb_step       = 0;
    my $pb_file_count = 0;
    $box->pack_start( $pb, FALSE, FALSE, 0 );
    $window->{ pb } = $pb;

    shred();

    $window->show_all;
    Gtk3->main;
}

sub shred {
    my $options = ' -D';
    my $count   = 0;

    for my $o ( @objects ) {
        warn "in for loop: o = >$o<\n";
        if ( -f $o ) {
            $pb_file_count += 1;
        } elsif ( -d $o ) {
            $options .= ' -R';
            find( { wanted => \&wanted, preprocess => \&nodirs }, $o );
        } else {
            warn "obj = >$o<!\n";
            next;
        }
    }

    $options .= ' --verbose --verbose';
    my $paths = '';

    $paths .= $_ for ( @objects );
    warn "file count = >$pb_file_count<\n";
    warn "path = >$paths<\n";
    exit;

    if ( !$pb_file_count ) {
        warn "no file count - use warning banner here\n";
        Gtk3->main_quit;
    } else {
        $pb_step = 1 / $pb_file_count;
    }

    $pb->set_fraction( 0.0 );
    $label->set_text( 'Preparing to shred...' );

    my $shred = Shredder::Config::get_shred_path();

    Gtk3::main_iteration while ( Gtk3::events_pending );

    my $pid = open( my $SHRED, '-|', "$shred $options $paths 2>&1" );
    defined( $pid ) or die "Couldn't fork! $!\n";

    while ( <$SHRED> ) {
        chomp;
        Gtk3::main_iteration while ( Gtk3::events_pending );
        if ( /^srm: removing (.*?)$/ ) {
            $label->set_text( "Shredding $1..." );
        } elsif ( /^pass \d sync/ ) {
            $label->set_text( "Finishing $1..." );
        }
        my $current = $pb->get_fraction;
        $pb->set_fraction( $current + $pb_step );
    }

    $pb->set_fraction( 1.0 );
    $pb->set_text( 'Finished' );

    cleanup();
}

sub cleanup {
    # Reset stuff
    $pb_step       = 0;
    $pb_file_count = 0;
    @objects       = ();
}

sub wanted {
    my $file = $_;
    return unless ( -f $file );
    $pb_file_count++;
}

sub nodirs {
    grep !-d, @_;
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

sub prompt {

}

sub about {
    my $dialog = Gtk3::AboutDialog->new;
    my $license
        = 'thunar-sendto-shredder is free software; you can redistribute'
        . ' it and/or modify it under the terms of either:'
        . ' a) the GNU General Public License as published by the'
        . ' Free Software Foundation; either version 1, or'
        . ' (at your option) any later version, or'
        . ' b) the "Artistic License".';
    $dialog->set_wrap_license( TRUE );
    $dialog->set_position( 'mouse' );

    my $icon   = "$images_dir/thunar-sendto-shredder.png";
    my $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file( $icon );

    $dialog->set_logo( $pixbuf );
    $dialog->set_version( $VERSION );
    $dialog->set_license( $license );
    $dialog->set_website_label( _( 'Homepage' ) );
    $dialog->set_website( 'https://launchpad.net/thunar-sendto-shredder/' );
    $dialog->set_logo( $pixbuf );
    $dialog->set_translator_credits(
        'Please see the website for full listing' );
    $dialog->set_copyright( "\x{a9} Dave M 2016 -" );
    $dialog->set_program_name( 'thunar-sendto-shredder' );
    $dialog->set_authors( [ 'Dave M', '<dave.nerd@gmail.com>' ] );
    $dialog->set_comments(
              'thunar-sendto-shredder provides a simple context menu'
            . ' for securely shredding files with a graphical interface' );

    $dialog->run;
    $dialog->destroy;
    $dialog->signal_connect( 'delete-event' => sub { $dialog->destroy } );

    return TRUE;
}

1;
