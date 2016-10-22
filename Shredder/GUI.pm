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
use File::Basename 'basename';

use POSIX 'locale_h';
use Locale::gettext;

my $window;
my $promptdialog;
my $flow;

# Stuff to be overwritten
my @objects = ();

# Our GtkSpinner; hidden until shredding begins
my $spinner;

# Status label; shows user what is happening
my $label = '';

my $files_deleted = 0;

sub show_window {
    @objects = @_;

    $window = Gtk3::Window->new( 'toplevel' );
    $window->set_default_size( 300, 100 );
    $window->set_border_width( 10 );
    $window->signal_connect(
        'destroy' => sub {
            Gtk3->main_quit;
            exit;
        }
    );
    $window->signal_connect(
        'delete-event' => sub {
            Gtk3->main_quit;
            exit;
        }
    );

    my $box = Gtk3::Box->new( 'vertical', 5 );
    $window->add( $box );

    my $header = Gtk3::HeaderBar->new;
    $window->set_titlebar( $header );
    $header->set_title( _( 'File shredder' ) );
    $header->set_subtitle( _( 'Securely erase files' ) );
    $header->set_show_close_button( TRUE );
    $header->set_decoration_layout( 'menu:minimize,close' );

    my $btn = Gtk3::Button->new_from_icon_name( 'gtk-quit', 3 );
    $btn->set_tooltip_text( _( 'Quit this program' ) );
    $btn->signal_connect( clicked => sub { Gtk3->main_quit } );
    $header->pack_start( $btn );

    $label = Gtk3::Label->new( '' );
    $box->pack_start( $label, FALSE, FALSE, 0 );

    $spinner = Gtk3::Spinner->new;
    $spinner->hide;
    $box->pack_start( $spinner, FALSE, FALSE, 0 );

    Gtk3::main_iteration while ( Gtk3::events_pending );
    $window->show_all;

    if ( Shredder::Config::get_conf_value( 'Prompt' ) ) {
        Gtk3::main_iteration while ( Gtk3::events_pending );

        my $confirm = prompt();
        if ( !$confirm ) {
            $window->destroy;
            Gtk3->main_quit;
            exit;
        }

    } elsif ( scalar( @objects ) ) {
        shred();
    } else {
        Gtk3->main_quit;
        exit;
    }

    Gtk3->main;
}

sub shred {
    my $options = ' -v -v';

    # Add Overwrite preference
    my $write
        = translate_write( Shredder::Config::get_conf_value( 'Write' ) );

    # Add Recursive switch if selected in options
    if ( Shredder::Config::get_conf_value( 'Recursive' ) ) {
        $options .= ' -R';
    }

    setpriority( 'PRIO_PROCESS', $$, 10 );

    $files_deleted = 0;
    my $paths = '';

    $paths .= $_ for ( @objects );

    $label->set_text( _( 'Preparing to remove...' ) );
    $spinner->start;
    Gtk3::main_iteration while ( Gtk3::events_pending );

    my $shred = Shredder::Config::get_shred_path();

    my $SHRED;
    my $pid = open( $SHRED, '-|', "$shred $write $options $paths 2>&1" );
    defined( $pid ) or die "Couldn't fork! $!\n";
    $window->queue_draw;
    Gtk3::main_iteration while ( Gtk3::events_pending );

    Gtk3::main_iteration while ( Gtk3::events_pending );
    while ( <$SHRED> ) {
        Gtk3::main_iteration while ( Gtk3::events_pending );
        chomp;
        if ( /^srm: removing (.*?)$/ ) {
            my $basename = basename( $1 );
            Gtk3::main_iteration while ( Gtk3::events_pending );
            $label->set_text( _( "Shredding ..." ) );
            $files_deleted++;
            Gtk3::main_iteration while ( Gtk3::events_pending );
        } else {
            next;
        }

        Gtk3::main_iteration while ( Gtk3::events_pending );
    }

    Gtk3::main_iteration while ( Gtk3::events_pending );
    $label->set_text( '' );

    cleanup();
    my $sum_phrase = sprintf( _( '%d file(s)' ), $files_deleted );

    popup( _( 'Finished shredding' . $sum_phrase ) );
}

sub cleanup {
    # Reset stuff
    @objects       = ();
    $files_deleted = 0;

    $spinner->stop;
    $spinner->hide;
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
    die "no shredder found!\n";
}

sub prompt {
    $promptdialog = Gtk3::Dialog->new_with_buttons( undef, $window,
        'destroy-with-parent', );
    $promptdialog->signal_connect( destroy => sub {return} );
    $promptdialog->set_border_width( 10 );

    my $box = Gtk3::Box->new( 'vertical', 5 );
    $promptdialog->get_content_area->add( $box );

    my $header = Gtk3::HeaderBar->new;
    $promptdialog->set_titlebar( $header );
    $header->set_title( 'File shredder' );
    $header->set_subtitle( 'Confirmation' );
    $header->set_show_close_button( TRUE );
    $header->set_decoration_layout( 'menu:minimize,close' );

    my $phrase
        = _( "The files you have chosen are about to be permanently erased." )
        . "\n\n"
        . _( "Press OK to continue or cancel to stop this operation." )
        . "\n\n";
    my $label = Gtk3::Label->new( $phrase );

    my $infobar = Gtk3::InfoBar->new;
    $infobar->set_message_type( 'info' );
    $infobar->add_button( 'gtk-cancel', 'cancel' );
    $infobar->add_button( 'gtk-ok',     'ok' );
    $infobar->signal_connect(
        response => sub {
            my ( $bar, $response ) = @_;
            if ( $response eq 'cancel' ) {
                $window->destroy;
                $promptdialog->destroy;
                Gtk3->main_quit;
                exit;
            } else {
                $promptdialog->destroy;
                shred();
            }
        }
    );
    $infobar->get_content_area->add( $label );
    $infobar->show_all;
    $box->add( $infobar );

    $promptdialog->show_all;
    $promptdialog->run;
    $promptdialog->destroy;
}

sub popup {
    my $message = shift;
    my $dialog  = Gtk3::Dialog->new;
    $dialog->set_title( _( 'Status' ) );
    $dialog->add_buttons( 'gtk-ok', 'ok' );
    $dialog->signal_connect( destroy => sub { Gtk3->main_quit } );
    $dialog->set_default_size( 150, 100 );
    $dialog->set_border_width( 10 );
    $dialog->set_border_width( 10 );

    my $box = Gtk3::Box->new( 'vertical', 5 );
    $dialog->get_content_area->add( $box );

    my $label = Gtk3::Label->new( $message );
    $box->pack_start( $label, FALSE, FALSE, 0 );

    $dialog->show_all;

    if ( $dialog->run eq 'ok' ) {
        $window->destroy;
        Gtk3->main_quit;
        exit;
    }
    $dialog->destroy;
}

sub translate_write {
    my $wanted = shift;

    my %swap;

    $swap{ 'Simple' }  = ' --simple';
    $swap{ 'OpenBSD' } = ' --openbsd';
    $swap{ 'DoD' }     = ' --dod';
    $swap{ 'DoE' }     = ' --doe';
    $swap{ 'Gutmann' } = ' --gutmann';
    $swap{ 'RCMP' }    = ' --rcmp';

    # Return requested overwrite type, or a default value
    if ( exists $swap{ $wanted } ) {
        return $swap{ $wanted };
    } else {
        return ' --simple';
    }
}

1;
