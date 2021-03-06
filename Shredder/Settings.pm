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
package Shredder::Settings;

# use strict;
# use warnings;
use Glib 'TRUE', 'FALSE';
$| = 1;

use POSIX 'locale_h';
use Locale::gettext;

my $window;
my $popover;
my $update_btn;

my $homepage = 'https://dave-theunsub.github.io/thunar-sendto-shredder/';

sub about {
    my $dialog = Gtk3::AboutDialog->new;
    $dialog->signal_connect( 'delete-event' => sub { $dialog->destroy } );
    my $license
        = 'thunar-sendto-shredder is free software; you can'
        . ' redistribute it and/or modify it under the terms'
        . ' of either:'
        . ' a) the GNU General Public License as published by the'
        . ' Free Software Foundation; either version 1, or'
        . ' (at your option) any later version, or'
        . ' b) the "Artistic License".';
    $dialog->set_wrap_license( TRUE );
    $dialog->set_position( 'mouse' );

    my $header = Gtk3::HeaderBar->new;
    $dialog->set_titlebar( $header );
    $header->set_title( _( 'About' ) );
    $header->set_show_close_button( TRUE );
    $header->set_decoration_layout( 'menu:close' );

    my $images_dir = Shredder::Config::get_images_path();
    my $icon       = "$images_dir/thunar-sendto-shredder.png";
    my $pixbuf     = Gtk3::Gdk::Pixbuf->new_from_file( $icon );

    $dialog->set_logo( $pixbuf );
    $dialog->set_version( Shredder::Config::get_version() );
    $dialog->set_license( $license );
    $dialog->set_website_label( 'Homepage' );
    $dialog->set_website( $homepage );
    $dialog->set_logo( $pixbuf );
    $dialog->set_copyright( "\x{a9} Dave M 2016 -" );
    $dialog->set_program_name( 'thunar-sendto-shredder' );
    $dialog->set_authors( [ 'Dave M', '<dave.nerd@gmail.com>' ] );
    $dialog->set_comments(
              'thunar-sendto-shredder provides a simple right-click,'
            . ' context menu for securely shredding files from '
            . ' within the Thunar file manager' );

    $dialog->show_all;
    $dialog->run;
    $dialog->destroy;

    return TRUE;
}

sub popover {
    Gtk3::main_iteration while ( Gtk3::events_pending );
    my $loop = Glib::MainLoop->new;
    Glib::Timeout->add(
        1500,
        sub {
            $loop->quit;
            FALSE;
        }
    );
    $loop->run;
    $popover->hide;
    Gtk3::main_iteration while ( Gtk3::events_pending );
}

sub save_changes {
    my ( $prompt, $zero, $empty, $rounds ) = @_;

    Shredder::Config::set_value( 'Prompt',          $prompt );
    Shredder::Config::set_value( 'Zero',            $zero );
    Shredder::Config::set_value( 'DeleteEmptyDirs', $empty );
    Shredder::Config::set_value( 'Rounds',          $rounds );

    $popover->show;
    Gtk3::main_iteration while ( Gtk3::events_pending );
    popover();
}

sub show_window {
    $window = Gtk3::Window->new( 'toplevel' );
    $window->signal_connect(
        destroy => sub {
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
    $window->set_border_width( 10 );

    my $box = Gtk3::Box->new( 'vertical', 5 );
    $window->add( $box );

    my $header = Gtk3::HeaderBar->new;
    $window->set_titlebar( $header );
    $header->set_title( 'File shredder' );
    $header->set_subtitle( 'Settings' );
    $header->set_show_close_button( TRUE );
    $header->set_decoration_layout( 'menu:minimize,close' );

    my $images_dir = Shredder::Config::get_images_path();

    # Header bar buttons
    my $btn  = Gtk3::Button->new;
    my $icon = Gtk3::Image->new_from_file( "$images_dir/tss-about.png" );
    $btn->set_image( $icon );
    $btn->set_tooltip_text( 'About' );
    $btn->signal_connect( clicked => \&about );
    $header->add( $btn );

    $btn = Gtk3::Button->new;
    $icon
        = Gtk3::Image->new_from_file( "$images_dir/tss-system-log-out.png" );
    $btn->set_image( $icon );
    $btn->set_tooltip_text( _( 'Quit this program' ) );
    $btn->signal_connect( clicked => sub { Gtk3->main_quit; exit } );
    $header->add( $btn );

    # This stays global so we can unhide it if
    # an update is available
    $update_btn = Gtk3::Button->new;
    $icon       = Gtk3::Image->new_from_file(
        "$images_dir/tss-software-update-available.png" );
    $update_btn->set_image( $icon );
    $update_btn->set_tooltip_text( 'An update is available' );
    $header->add( $update_btn );
    $update_btn->signal_connect(
        clicked => sub {
            system( 'xdg-open', $homepage ) == 0
                or warn "Cannot open homepage: $!\n";
        }
    );

    my $grid = Gtk3::Grid->new;
    $grid->set_row_spacing( 5 );
    $grid->set_column_spacing( 10 );
    $grid->set_column_homogeneous( TRUE );
    $box->pack_start( $grid, FALSE, FALSE, 10 );

    # For popover
    my $label = Gtk3::Label->new( 'Saved' );
    $label->show;

    # These are the options in the Settings:
    # they don't have to be global
    my ( $prompt_switch, $zero_switch, $empty_switch, $spin_switch );

    my $bold_label = Gtk3::Label->new( '<b>Settings</b>' );
    $bold_label->set_use_markup( TRUE );
    my $explain_label
        = Gtk3::Label->new( _( 'Prompt me before deleting files' ) );
    $explain_label->set_tooltip_text(
        _( 'Always confirm prior to running' ) );
    $explain_label->set_alignment( 0.0, 0.5 );
    $prompt_switch = Gtk3::Switch->new;
    $grid->attach( $bold_label,    0, 0, 1, 1 );
    $grid->attach( $explain_label, 0, 2, 1, 1 );
    $grid->attach( $prompt_switch, 1, 2, 1, 1 );
    $prompt_switch->set_active(
        Shredder::Config::get_conf_value( 'Prompt' )
        ? TRUE
        : FALSE
    );

    # Recursive stuff - shred doesn't do directories and stuff yet...
    # May add this later.
    #$explain_label = Gtk3::Label->new( _( 'Recursive shredding' ) );
    #$explain_label->set_tooltip_text(
    #    _( 'Descend into additional directories' ) );
    #$explain_label->set_alignment( 0.0, 0.5 );
    #my $recursive_switch = Gtk3::Switch->new;
    #$grid->attach( $explain_label,    0, 3, 1, 1 );
    #$grid->attach( $recursive_switch, 1, 3, 1, 1 );
    #$recursive_switch->set_active(
    #    Shredder::Config::get_conf_value( 'Recursive' )
    #    ? TRUE
    #    : FALSE
    #);

    $explain_label = Gtk3::Label->new( _( 'Overwrite with zeros' ) );
    $explain_label->set_tooltip_text(
        _( 'Add a final overwrite with zeros to hide shredding' ) );
    $explain_label->set_alignment( 0.0, 0.5 );
    $zero_switch = Gtk3::Switch->new;
    $grid->attach( $explain_label, 0, 3, 1, 1 );
    $grid->attach( $zero_switch,   1, 3, 1, 1 );
    $zero_switch->set_active(
        Shredder::Config::get_conf_value( 'Zero' )
        ? TRUE
        : FALSE
    );

    $explain_label = Gtk3::Label->new( _( 'Delete empty directories' ) );
    $explain_label->set_tooltip_text(
        _( 'Rename and delete empty directories when possible' ) );
    $explain_label->set_alignment( 0.0, 0.5 );
    $empty_switch = Gtk3::Switch->new;
    $grid->attach( $explain_label, 0, 4, 1, 1 );
    $grid->attach( $empty_switch,  1, 4, 1, 1 );
    $empty_switch->set_active(
        Shredder::Config::get_conf_value( 'DeleteEmptyDirs' )
        ? TRUE
        : FALSE
    );

    $explain_label = Gtk3::Label->new( _( 'Overwrite preference' ) );
    $explain_label->set_tooltip_text(
        _( 'Choose the number of overwrites' ) );
    $spin_switch = Gtk3::SpinButton->new_with_range( 1, 35, 1 );
    $explain_label->set_alignment( 0.0, 0.5 );
    $grid->attach( $explain_label, 0, 5, 1, 1 );
    $grid->attach( $spin_switch,   1, 5, 1, 1 );
    $spin_switch->set_value(
        Shredder::Config::get_conf_value( 'Rounds' )
        ? TRUE
        : FALSE
    );

    my $rounds = Shredder::Config::get_conf_value( 'Rounds' );
    $rounds ||= 3;
    $spin_switch->set_value( $rounds );

    $popover = Gtk3::Popover->new;
    $popover->add( $label );

    my $bbox = Gtk3::ButtonBox->new( 'horizontal' );
    $bbox->set_layout( 'end' );
    $box->pack_start( $bbox, FALSE, FALSE, 5 );

    my $apply_button = Gtk3::Button->new_from_icon_name( 'gtk-apply', 3 );
    $popover->set_relative_to( $apply_button );
    $apply_button->set_tooltip_text( 'Apply changes' );
    $apply_button->signal_connect(
        clicked => sub {
            save_changes(
                $prompt_switch->get_active,    # Prompt
                $zero_switch->get_active,      # Overwrite with Zeros
                $empty_switch->get_active,     # Delete empty directories
                $spin_switch->get_value,       # Rounds
            );
        }
    );
    $bbox->add( $apply_button );

    # Show first run dialog
    Shredder::GUI::first_run( $window );

    $window->show_all;

    # We don't need this unless there's an update
    $update_btn->hide;
    Gtk3::main_iteration while ( Gtk3::events_pending );
    my ( $can_update, $version ) = Shredder::Update::check_gui();
    if ( $can_update ) {
        Gtk3::main_iteration while ( Gtk3::events_pending );
        my $remote = sprintf( "Version %s is available", $version );
        $update_btn->set_tooltip_text( $remote );
        $update_btn->show;
    }

    Gtk3->main;
}

1;
