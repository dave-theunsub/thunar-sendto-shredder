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

# Stuff to be overwritten
my @objects = ();

# Our Gtk3::ProgressBar; global for now
my $pb            = '';
my $pb_step       = 0;
my $pb_file_count = 0;

# Status label; shows user what is happening
my $label = '';

my $files_seen    = 0;
my $files_deleted = 0;

sub show_window {
    @objects = @_;
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

    my $btn = Gtk3::Button->new_from_icon_name( 'gtk-quit', 3 );
    $btn->set_tooltip_text( 'Quit this program' );
    $btn->signal_connect( clicked => sub { Gtk3->main_quit } );
    $header->pack_start( $btn );

    $label = Gtk3::Label->new( '' );
    $box->pack_start( $label, FALSE, FALSE, 0 );

    $pb = Gtk3::ProgressBar->new;
    $box->pack_start( $pb, FALSE, FALSE, 0 );
    $window->{ pb } = $pb;

    if ( Shredder::Config::get_conf_value ) {
        prompt();
    } else {
        shred();
    }

    $window->show_all;
    Gtk3->main;
}

sub shred {
    my $options = ' -D';

    my $files_seen    = 0;
    my $files_deleted = 0;

    for my $o ( @objects ) {
        warn "in for loop: o = >$o<\n";
        $files_seen += 1;
        if ( -f $o ) {
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
    my $num_of_files = shift;
    warn "no files?\n" and return unless ( $num_of_files );

    my $dialog = Gtk3::Dialog->new_with_buttons( 'title', undef,
        'destroy-with-parent', );
    $dialog->add_buttons( 'gtk-cancel', 'cancel', 'gtk-ok', 'ok' );
    $dialog->set_title( 'title goes here' );
    $dialog->signal_connect( destroy => sub { Gtk3->main_quit } );
    $dialog->set_default_size( 200, 200 );
    $dialog->set_border_width( 10 );

    my $box = Gtk3::Box->new( 'vertical', 5 );
    $dialog->get_content_area->add( $box );

    my $header = Gtk3::HeaderBar->new;
    $dialog->set_titlebar( $header );
    $header->set_title( 'File shredder' );
    $header->set_subtitle( 'Settings' );
    $header->set_show_close_button( TRUE );
    $header->set_decoration_layout( 'menu:minimize,close' );

    my $phrase = sprintf(
        "You are about to permanently erase %d files. " . "\n\n"
            . "Press OK to continue or cancel to stop this operation.",
        $num_of_files
    );
    my $label = Gtk3::Label->new( $phrase );
    $box->add( $label );

    $dialog->show_all;
    if ( $dialog->run eq 'cancel' ) {
        warn "pressed cancel!\n";
        $dialog->destroy;
        return;
    }
    $dialog->destroy;
}

sub warning {

}

1;
