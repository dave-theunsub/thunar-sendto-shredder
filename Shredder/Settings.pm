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
package Shredder::Settings;

use strict;
use warnings;
use Glib 'TRUE', 'FALSE';
$| = 1;

my ( $prompt_clippy,    $prompt_pop );
my ( $recursive_clippy, $recursive_pop );
my ( $write_clippy,     $write_pop );

sub show_window {
    my $window = Gtk3::Window->new( 'toplevel' );
    $window->signal_connect( destroy => sub { Gtk3->main_quit } );
    $window->set_default_size( 300, 300 );
    $window->set_border_width( 10 );

    my $box = Gtk3::Box->new( 'vertical', 5 );
    $window->add( $box );

    my $header = Gtk3::HeaderBar->new;
    $window->set_titlebar( $header );
    $header->set_title( 'File shredder' );
    $header->set_subtitle( 'Settings' );
    $header->set_show_close_button( TRUE );
    $header->set_decoration_layout( 'menu:minimize,close' );

    my $btn = Gtk3::Button->new_from_icon_name( 'gtk-dialog-question', 3 );
    $btn->signal_connect( clicked => \&info );
    $header->add( $btn );
    $btn = Gtk3::Button->new_from_icon_name( 'gtk-about', 3 );
    $btn->signal_connect( clicked => \&about );
    $header->add( $btn );
    $btn = Gtk3::Button->new_from_icon_name( 'gtk-quit', 3 );
    $btn->signal_connect( clicked => sub { Gtk3->main_quit } );
    $header->add( $btn );

    my $grid = Gtk3::Grid->new;
    $grid->set_row_spacing( 5 );
    $grid->set_column_spacing( 10 );
    $grid->set_column_homogeneous( TRUE );
    $box->pack_start( $grid, FALSE, FALSE, 10 );

    my $bold_label = Gtk3::Label->new( '<b>Settings</b>' );
    $bold_label->set_use_markup( TRUE );
    my $explain_label = Gtk3::Label->new( 'Prompt me before deleting files' );
    $explain_label->set_alignment( 0.0, 0.5 );
    my $switch    = Gtk3::Switch->new;
    my $separator = Gtk3::Separator->new( 'horizontal' );
    $grid->attach( $bold_label,    0, 0, 1, 1 );
    $grid->attach( $explain_label, 0, 2, 1, 1 );
    $grid->attach( $switch,        1, 2, 1, 1 );
    $grid->attach( $separator,     0, 3, 2, 1 );
    $switch->set_active(
        Shredder::Config::get_conf_value( 'Prompt' )
        ? TRUE
        : FALSE
    );
    $switch->signal_connect( 'state-set' => \&switch_toggle, 'Prompt' );
    $prompt_clippy = Gtk3::Clipboard::get(
        Gtk3::Gdk::Atom::intern( 'CLIPBOARD', FALSE ) );
    $prompt_clippy->wait_for_text;
    $prompt_pop = Gtk3::Popover->new;
    $prompt_pop->set_position( 'right' );
    $prompt_pop->set_relative_to( $switch );

    $grid = Gtk3::Grid->new;
    $grid->set_row_spacing( 5 );
    $grid->set_column_spacing( 10 );
    $grid->set_column_homogeneous( TRUE );
    $box->pack_start( $grid, FALSE, FALSE, 10 );

    $explain_label = Gtk3::Label->new( 'Allow recursive shredding' );
    $explain_label->set_tooltip_text( 'Descend into additional directories' );
    $explain_label->set_alignment( 0.0, 0.5 );
    $switch    = Gtk3::Switch->new;
    $separator = Gtk3::Separator->new( 'horizontal' );
    $grid->attach( $explain_label, 0, 5, 1, 1 );
    $grid->attach( $switch,        1, 5, 1, 1 );
    $switch->signal_connect( 'state-set' => \&switch_toggle, 'Recursive' );
    $recursive_clippy = Gtk3::Clipboard::get(
        Gtk3::Gdk::Atom::intern( 'CLIPBOARD', FALSE ) );
    $recursive_clippy->wait_for_text;
    $recursive_pop = Gtk3::Popover->new;
    $recursive_pop->set_position( 'right' );
    $recursive_pop->set_relative_to( $switch );
    $switch->set_active(
        Shredder::Config::get_conf_value( 'Recursive' )
        ? TRUE
        : FALSE
    );

    $grid = Gtk3::Grid->new;
    $grid->set_row_spacing( 5 );
    $grid->set_column_spacing( 10 );
    $grid->set_column_homogeneous( TRUE );
    $box->pack_start( $grid, FALSE, FALSE, 10 );

    $explain_label = Gtk3::Label->new( 'Overwrite preference' );
    $switch        = Gtk3::ComboBoxText->new;
    $separator     = Gtk3::Separator->new( 'horizontal' );
    $explain_label->set_alignment( 0.0, 0.5 );
    $grid->attach( $explain_label, 0, 6, 1, 1 );
    $grid->attach( $switch,        1, 6, 1, 1 );
    $grid->attach( $separator,     0, 7, 2, 1 );

    my $pref = Shredder::Config::get_conf_value( 'Write' );
    warn "pref = >$pref<\n";
    my @writes = ( 'Simple', 'OpenBSD', 'DoD', 'DoE', 'Gutmann', 'RCMP', );
    for my $type ( @writes ) {
        $switch->append_text( $type );
    }

    my %swap;
    $swap{ '--simple' }  = 0;
    $swap{ '--openbsd' } = 1;
    $swap{ '--dod' }     = 2;
    $swap{ '--doe' }     = 3;
    $swap{ '--gutmann' } = 4;
    $swap{ '--rcmp' }    = 5;
    $switch->set_active( $swap{ $pref } );
    $switch->signal_connect( changed => \&toggle_type );

    $window->show_all;
    Gtk3->main;
}

sub switch_toggle {
    my ( $switch_object, $status, $type ) = @_;
    Shredder::Config::set_value( $type, $status );

    my $label = Gtk3::Label->new( 'Saved' );
    $label->show;
    if ( $type eq 'Prompt' ) {
        $prompt_clippy->set_text( $label, length( $label ) );
        $prompt_pop->show;
        Gtk3::main_iteration while ( Gtk3::events_pending );
        pause_for_effect();
        $prompt_pop->hide;
    } elsif ( $type eq 'Recursive' ) {
        $recursive_clippy->set_text( $label, length( $label ) );
        $recursive_pop->show;
        Gtk3::main_iteration while ( Gtk3::events_pending );
        pause_for_effect();
        $recursive_pop->hide;
    }
}

sub pause_for_effect {
    my $loop = Glib::MainLoop->new;
    Glib::Timeout->add(
        1000,
        sub {
            $loop->quit;
            FALSE;
        }
    );
    Gtk3::main_iteration while ( Gtk3::events_pending );
    $loop->run;
}

sub toggle_type {
    my $cb          = $_;
    my $active_text = $cb->get_active_text;
    warn "got at = >$active_text<\n";
}

sub info {
    my $dialog = Gtk3::Dialog->new(
        'Useful information',
        undef, [ qw| destroy-with-parent no-separator | ],
    );

    $dialog->show_all;
    $dialog->run;
    $dialog->destroy;
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

    my $images_dir = Shredder::Config::get_images_path();
    my $icon       = "$images_dir/thunar-sendto-shredder.png";
    my $pixbuf     = Gtk3::Gdk::Pixbuf->new_from_file( $icon );

    $dialog->set_logo( $pixbuf );
    $dialog->set_version( Shredder::Config::get_version() );
    $dialog->set_license( $license );
    $dialog->set_website_label( 'Homepage' );
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
