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
package Shredder::Prompt;

use strict;
use warnings;
use Glib 'TRUE', 'FALSE';
$| = 1;

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

    # For popover
    my $label = Gtk3::Label->new( 'Saved' );
    $label->show;

    $window->show_all;
    Gtk3->main;
}

1;
