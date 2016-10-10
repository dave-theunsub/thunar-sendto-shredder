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
use Gtk3 '-init';
use Glib 'TRUE', 'FALSE';
$| = 1;

show_window();

sub show_window {
    my $dialog = Gtk3::Dialog->new_with_buttons( 'title', undef,
        'destroy-with-parent', );
    $dialog->add_buttons( 'gtk-cancel', 'cancel', 'gtk-ok', 'ok' );
    $dialog->set_title( 'title goes here' );
    $dialog->signal_connect( destroy => sub { Gtk3->main_quit } );
    $dialog->set_default_size( 300, 300 );
    #$dialog->set_border_width( 10 );

    my $box = Gtk3::Box->new( 'vertical', 5 );
    $dialog->get_content_area->add( $box );

    my $header = Gtk3::HeaderBar->new;
    $dialog->set_titlebar( $header );
    $header->set_title( 'File shredder' );
    $header->set_subtitle( 'Settings' );
    $header->set_show_close_button( TRUE );
    $header->set_decoration_layout( 'menu:minimize,close' );

    $dialog->show_all;
    $dialog->run;
    $dialog->destroy;
    Gtk3->main_quit;
}

1;
