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
package Shredder::GUI;

# use strict;
# use warnings;
$| = 1;

use Gtk3 '-init';
use Glib 'TRUE',               'FALSE';
use File::Basename 'basename', 'dirname';
use File::Path 'remove_tree';
use Cwd 'realpath';

use POSIX 'locale_h';
use Locale::gettext;

my $window;
my $promptdialog;
my $flow;

# Stuff to be overwritten
my @objects = ();

# Our GtkSpinner; hidden until shredding begins
my $spinner;

# Label showing status of shredding
my $shred_label;

my $files_deleted = 0;

sub cleanup {
    # Reset stuff
    @objects       = ();
    $files_deleted = 0;
}

sub first_run {
    my $parent = shift;

    my $watchagain = Shredder::Config::get_conf_value( 'FirstRunWatch' );
    return if ( !$watchagain );

    my $dialog = Gtk3::Dialog->new_with_buttons( undef, $parent,
        'destroy-with-parent', );
    $dialog->set_border_width( 10 );

    my $box = Gtk3::Box->new( 'vertical', 5 );
    $dialog->get_content_area->add( $box );

    my $header = Gtk3::HeaderBar->new;
    $dialog->set_titlebar( $header );
    $header->set_title( _( 'File shredder' ) );
    $header->set_show_close_button( TRUE );
    $header->set_decoration_layout( 'menu:minimize,close' );

    my $label = Gtk3::Label->new(
        _( 'It is recommended to always keep the Prompt setting enabled.' ) );
    $box->pack_start( $label, TRUE, TRUE, 5 );
    $label = Gtk3::Label->new(
        _(        'A larger number of overwrites may take longer to '
                . 'complete and may bog down other applications in use.'
        )
    );
    $box->pack_start( $label, TRUE, TRUE, 5 );

    my $cbtn = Gtk3::CheckButton->new_with_label(
        _( 'Do not show me this again' ) );
    $cbtn->signal_connect(
        toggled => sub {
            Shredder::Config::set_value( 'FirstRunWatch', FALSE );
        }
    );
    $cbtn->set_can_focus( FALSE );
    $box->pack_start( $cbtn, FALSE, FALSE, 10 );

    $dialog->show_all;
    $dialog->run;
    $dialog->destroy;
}

sub get_shred_path {
    my $path = '';

    if ( open( my $p, '-|', 'which shred' ) ) {
        while ( <$p> ) {
            chomp;
            $path = $_ if ( -e $_ );
        }
    }

    return $path if ( $path );
    die "no shredder found!\n";
}

sub is_empty {
    my $testdir = shift;
    return unless ( -d $testdir );
    opendir( my $dh, $testdir )
        or do {
        warn "can't open $testdir; returning\n";
        return FALSE;
        };
    return scalar( grep { $_ ne "." && $_ ne ".." } readdir( $dh ) ) == 0;
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

sub prompt {
    $promptdialog = Gtk3::Dialog->new_with_buttons( undef, $window,
        'destroy-with-parent', );
    $promptdialog->signal_connect( destroy => sub {return} );
    $promptdialog->set_border_width( 10 );

    my $box = Gtk3::Box->new( 'vertical', 5 );
    $promptdialog->get_content_area->add( $box );

    my $header = Gtk3::HeaderBar->new;
    $promptdialog->set_titlebar( $header );
    $header->set_title( _( 'File shredder' ) );
    $header->set_subtitle( _( 'Confirmation' ) );
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

    # $label = Gtk3::Label->new( '' );
    $shred_label = Gtk3::Label->new( '' );
    $box->pack_start( $shred_label, FALSE, FALSE, 0 );

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
    # Options
    my $options = '';

    # By default, use verbose so the user can see the progress
    $options .= ' --verbose';

    # By default, use remove
    $options .= ' --remove';

    # By default, add a final overwrite with zeros
    $options .= ' --zero';

    # Add Overwrite preference
    my $rounds = Shredder::Config::get_conf_value( 'Rounds' );
    $rounds ||= 3;

    # Add Recursive switch if selected in options
    # my $recursive = FALSE;
    # if ( Shredder::Config::get_conf_value( 'Recursive' ) ) {
    #    $recursive = TRUE;
    # }

    $files_deleted = 0;
    my $paths = '';

    $shred_label->set_ellipsize( 'middle' );
    $shred_label->set_max_width_chars( 35 );

    # $paths .= $_ for ( @objects );
    for my $o ( @objects ) {
        my $realpath = '';
        $realpath = realpath( $o );
        if ( -f $realpath ) {
            # we need the extra space or files will be
            # jammed together like one word
            $paths .= quotemeta( $realpath );
            $paths .= ' ';
        } elsif ( -d $o ) {
            my @inner = glob "$o/*";
            for my $i ( @inner ) {
                my $newrealpath = realpath( $i );
                $paths .= quotemeta( $newrealpath );
                $paths .= ' ';
            }
        }
    }

    $shred_label->set_text( _( 'Please wait...' ) );
    $spinner->start;
    Gtk3::main_iteration while ( Gtk3::events_pending );

    my $shred = Shredder::Config::get_shred_path();
    if ( !-e $shred ) {
        $shred = '/usr/bin/shred';
        if ( !-e $shred ) {
            die "Cannot find shred program.  Exiting.\n";
        }
    }

    my $SHRED;
    my $pid = open( $SHRED, '-|', "$shred -n $rounds $options $paths 2>&1" );
    defined( $pid ) or die "Couldn't fork! $!\n";

    Gtk3::main_iteration while ( Gtk3::events_pending );
    $window->queue_draw;

    Gtk3::main_iteration while ( Gtk3::events_pending );
    while ( <$SHRED> ) {
        Gtk3::main_iteration while ( Gtk3::events_pending );
        chomp;
        my $basename;
        my $dirname;
        if ( /shred: (.*?):/ ) {
            $basename = basename( $1 );
            $dirname  = dirname( $1 );
            $basename ||= _( 'file' );
        }
        if ( /shred: .*?: pass (\d\/\d)/ ) {
            Gtk3::main_iteration while ( Gtk3::events_pending );
            $shred_label->set_text( sprintf _( "Shredding %s..." ),
                $basename );
            Gtk3::main_iteration while ( Gtk3::events_pending );
        } elsif ( /shred:.*?: renamed to/ ) {
            Gtk3::main_iteration while ( Gtk3::events_pending );
            $shred_label->set_text( sprintf _( "Renaming %s..." ),
                $basename );
            Gtk3::main_iteration while ( Gtk3::events_pending );
        } elsif ( /shred:.*?: removed$/ ) {
            Gtk3::main_iteration while ( Gtk3::events_pending );
            $shred_label->set_text( sprintf _( "Removing %s..." ),
                $basename );
            $files_deleted++;
            Gtk3::main_iteration while ( Gtk3::events_pending );
        } else {
            next;
        }

        Gtk3::main_iteration while ( Gtk3::events_pending );

        # Remove empty directories
        # (if selected, of course)
        if ( Shredder::Config::get_conf_value( 'DeleteEmptyDirs' ) ) {
            if ( is_empty( $dirname ) ) {
                if ( -e $dirname ) {
                    shred_dir( $dirname );
                }
            }
        }
    }

    Gtk3::main_iteration while ( Gtk3::events_pending );

    $spinner->stop;
    $spinner->hide;
    $shred_label->set_text( '' );

    my $sum_phrase = sprintf( _( '%d file(s)' ), $files_deleted );

    popup( _( 'Finished shredding ' . $sum_phrase ) );
    cleanup();
}

sub shred_dir {
    my $shreddir = shift;
    $shred_label->set_text( sprintf _( "Renaming empty directory %s" ),
        $shreddir );

    if ( -d $shreddir ) {
        for my $round ( 6 .. 1 ) {
            my $newname = '0' x $round;
            rename( $shreddir, $newname )
                or warn "Can't rename >$shreddir< to >$newname<: $!\n";
        }
    }
    $shred_label->set_text( sprintf _( "Removing empty directory %s" ),
        $shreddir );
    remove_tree( $shreddir, { verbose => 1, } );
}

1;
