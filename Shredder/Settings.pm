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

my $window;
my $popover;

sub show_window {
    $window = Gtk3::Window->new( 'toplevel' );
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

    # For popover
    my $label = Gtk3::Label->new( 'Saved' );
    $label->show;

    my $bold_label = Gtk3::Label->new( '<b>Settings</b>' );
    $bold_label->set_use_markup( TRUE );
    my $explain_label = Gtk3::Label->new( 'Prompt me before deleting files' );
    $explain_label->set_alignment( 0.0, 0.5 );
    my $prompt_switch = Gtk3::Switch->new;
    $grid->attach( $bold_label,    0, 0, 1, 1 );
    $grid->attach( $explain_label, 0, 2, 1, 1 );
    $grid->attach( $prompt_switch, 1, 2, 1, 1 );
    $prompt_switch->set_active(
        Shredder::Config::get_conf_value( 'Prompt' )
        ? TRUE
        : FALSE
    );

    $grid = Gtk3::Grid->new;
    $grid->set_row_spacing( 5 );
    $grid->set_column_spacing( 10 );
    $grid->set_column_homogeneous( TRUE );
    $box->pack_start( $grid, FALSE, FALSE, 10 );

    $explain_label = Gtk3::Label->new( 'Allow recursive shredding' );
    $explain_label->set_tooltip_text( 'Descend into additional directories' );
    $explain_label->set_alignment( 0.0, 0.5 );
    my $recursive_switch = Gtk3::Switch->new;
    $grid->attach( $explain_label,    0, 5, 1, 1 );
    $grid->attach( $recursive_switch, 1, 5, 1, 1 );
    $recursive_switch->set_active(
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
    my $write_switch = Gtk3::ComboBoxText->new;
    $explain_label->set_alignment( 0.0, 0.5 );
    $grid->attach( $explain_label, 0, 6, 1, 1 );
    $grid->attach( $write_switch,  1, 6, 1, 1 );

    my $pref = Shredder::Config::get_conf_value( 'Write' );
    warn "pref = >$pref<\n";
    my @writes = ( 'Simple', 'OpenBSD', 'DoD', 'DoE', 'Gutmann', 'RCMP', );
    for my $type ( @writes ) {
        $write_switch->append_text( $type );
    }

    my %swap;

    $swap{ 'Simple' }  = 0;
    $swap{ 'OpenBSD' } = 1;
    $swap{ 'DoD' }     = 2;
    $swap{ 'DoE' }     = 3;
    $swap{ 'Gutmann' } = 4;
    $swap{ 'RCMP' }    = 5;

    for my $key ( keys %swap ) {
        if ( $key eq $pref ) {
            $write_switch->set_active( $swap{ $pref } );
        }
    }

    my $blabel = Gtk3::Label->new( '' );
    $box->pack_start( $blabel, FALSE, FALSE, 10 );
    $popover = Gtk3::Popover->new;
    $popover->add( $label );
    $popover->set_position( 'right' );
    $popover->set_relative_to( $blabel );

    my $bbox = Gtk3::ButtonBox->new( 'horizontal' );
    $bbox->set_layout( 'spread' );
    $box->pack_start( $bbox, FALSE, FALSE, 5 );

    my $bbtn = Gtk3::Button->new_from_icon_name( 'gtk-apply', 3 );
    $bbtn->set_tooltip_text( 'Apply changes' );
    $bbtn->signal_connect(
        clicked => sub {
            save_changes(
                $prompt_switch->get_active,
                $recursive_switch->get_active,
                $writes[ $write_switch->get_active ],
            );
        }
    );
    $bbox->add( $bbtn );
    $bbtn = Gtk3::Button->new_from_icon_name( 'gtk-close', 3 );
    $bbtn->set_tooltip_text( 'Close window' );
    $bbtn->signal_connect( clicked => sub { $window->destroy } );
    $bbox->add( $bbtn );

    $window->show_all;
    Gtk3->main;
}

sub save_changes {
    my ( $prompt, $recursive, $write ) = @_;
    warn "p = >$prompt<, r = >$recursive<, write =>$write<\n";

    Shredder::Config::set_value( 'Prompt',    $prompt );
    Shredder::Config::set_value( 'Recursive', $recursive );
    Shredder::Config::set_value( 'Write',     $write );

    popover();
}

sub popover {
    $popover->show_all;
    Gtk3::main_iteration while ( Gtk3::events_pending );
    my $loop = Glib::MainLoop->new;
    Glib::Timeout->add(
        2000,
        sub {
            $loop->quit;
            FALSE;
        }
    );
    $loop->run;
    $popover->hide;
    Gtk3::main_iteration while ( Gtk3::events_pending );
}

sub switch_toggle {
    my ( $switch_object, $status, $type ) = @_;

    popover();
}

sub toggle_type {
    my ( $cbtext, $value ) = @_;

    popover();
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
