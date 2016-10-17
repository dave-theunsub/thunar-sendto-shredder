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
package Shredder::Overview;

use Glib 'TRUE', 'FALSE';

use POSIX 'locale_h';
use Locale::gettext;

# GtkAssistant
my $flow;

# GtkHeaderBar
my $header;

sub show_window {
    $flow = Gtk3::Assistant->new;
    $flow->signal_connect( destroy => sub { $flow->destroy } );
    $flow->signal_connect( 'delete-event' => sub { $flow->destroy } );
    $flow->set_default_size( -1, 300 );

    $flow->signal_connect( close   => \&on_flow_close_cancel );
    $flow->signal_connect( cancel  => \&on_flow_close_cancel );
    $flow->signal_connect( prepare => \&on_assistant_prepare );

    $header = Gtk3::HeaderBar->new;
    $flow->set_titlebar( $header );
    $header->set_title( _( 'File shredder' ) );
    $header->set_subtitle( _( 'Overview' ) );
    $header->set_show_close_button( TRUE );
    $header->set_decoration_layout( 'menu:minimize,close' );

    create_page1();
    create_page2();
    create_page3();
    create_page4();
    create_page5();
    create_page6();

    $flow->show_all;
}

sub on_flow_close_cancel {
    $flow->destroy;
}

sub on_assistant_prepare {
    my ( $current_page, $num_pages );

    $current_page = $flow->get_current_page();
    warn "current = >$current_page<\n";
    $num_pages    = $flow->get_n_pages();
    warn "num = >$num_pages<\n";

    my $title = sprintf '(%d of %d)', $current_page + 1, $num_pages;
    my $label = Gtk3::Label->new( _( $title ) );
    $flow->set_page_title( $flow->get_current_page, $title );
    $header->set_title( $title );
    # $header->set_title( _('Overview' ) );
    # $header->set_custom_title( _( $title ) );
}

sub create_page1 {
    my $box = Gtk3::Box->new( 'vertical', 5 );
    $box->set_border_width( 5 );
    $box->set_homogeneous( TRUE );

    my $label = Gtk3::Label->new( "<b>" . _( 'Simple overwrite' ) . "</b>" );
    $label->set_use_markup( TRUE );
    $box->add( $label );

    $label
        = Gtk3::Label->new(
        'The simple option overwrites files with a single pass of 0x00 bytes.'
        );
    $box->add( $label );

    $label = Gtk3::Label->new( _( 'This is the default mode.' ) );
    $box->add( $label );

    my $bbox = Gtk3::ButtonBox->new( 'horizontal' );
    $bbox->set_layout( 'end' );
    $box->add( $bbox );

    my $btn = Gtk3::Button->new_from_icon_name( 'gtk-go-back', 3 );
    $btn->signal_connect(
        clicked => sub {
            $flow->previous_page;
        }
    );
    $btn->set_sensitive( FALSE );
    $bbox->add( $btn );
    $btn = Gtk3::Button->new_from_icon_name( 'gtk-go-forward', 3 );
    $btn->signal_connect(
        clicked => sub {
            $flow->next_page;
        }
    );
    $bbox->add( $btn );

    $box->show_all;

    $flow->append_page( $box );
    $flow->set_page_complete( $box, TRUE );
    $flow->set_page_type( $box, 'custom' );
}

sub create_page2 {
    my $box = Gtk3::Box->new( 'vertical', 5 );
    $box->set_border_width( 5 );
    $box->set_homogeneous( TRUE );

    my $label = Gtk3::Label->new( "<b>" . _( 'OpenBSD overwrite' ) . "</b>" );
    $label->set_use_markup( TRUE );
    $box->add( $label );

    $label = Gtk3::Label->new(
        _(  'This option overwrites files three times: first with 0xFF, then 0x00, then again with 0xFF.'
        )
    );
    $box->add( $label );

    $label = Gtk3::Label->new( _( 'The file is then deleted.' ) );
    $box->add( $label );

    my $bbox = Gtk3::ButtonBox->new( 'horizontal' );
    $bbox->set_layout( 'end' );
    $box->add( $bbox );

    my $btn = Gtk3::Button->new_from_icon_name( 'gtk-go-back', 3 );
    $btn->signal_connect(
        clicked => sub {
            $flow->previous_page;
        }
    );
    $bbox->add( $btn );
    $btn = Gtk3::Button->new_from_icon_name( 'gtk-go-forward', 3 );
    $btn->signal_connect(
        clicked => sub {
            $flow->next_page;
        }
    );
    $bbox->add( $btn );

    $box->show_all;

    $flow->append_page( $box );
    $flow->set_page_type( $box, 'custom' );
}

sub create_page3 {
    my $box = Gtk3::Box->new( 'vertical', 5 );
    $box->set_border_width( 5 );
    $box->set_homogeneous( TRUE );

    my $label = Gtk3::Label->new( "<b>" . _( 'DoD overwrite' ) . "</b>" );
    $label->set_use_markup( TRUE );
    $box->add( $label );

    $label = Gtk3::Label->new(
        _( 'This option overwrites files seven times.' ) );
    $box->add( $label );

    my $bbox = Gtk3::ButtonBox->new( 'horizontal' );
    $bbox->set_layout( 'end' );
    $box->add( $bbox );

    my $btn = Gtk3::Button->new_from_icon_name( 'gtk-go-back', 3 );
    $btn->signal_connect(
        clicked => sub {
            $flow->previous_page;
        }
    );
    $bbox->add( $btn );
    $btn = Gtk3::Button->new_from_icon_name( 'gtk-go-forward', 3 );
    $btn->signal_connect(
        clicked => sub {
            $flow->next_page;
        }
    );
    $bbox->add( $btn );
    $box->show_all;

    $flow->append_page( $box );
    $flow->set_page_type( $box, 'custom' );
}

sub create_page4 {
    my $box = Gtk3::Box->new( 'vertical', 5 );
    $box->set_border_width( 5 );
    $box->set_homogeneous( TRUE );

    my $label = Gtk3::Label->new( "<b>" . _( 'DoE overwrite' ) . "</b>" );
    $label->set_use_markup( TRUE );
    $box->add( $label );

    $label = Gtk3::Label->new(
        _( 'This US DoE compliant option overwrites files three times.' ) );
    $box->add( $label );

    $label = Gtk3::Label->new(
        _(  'The first two passes use a random pattern, and the third uses the bytes "DoE".'
        )
    );
    $box->add( $label );

    my $bbox = Gtk3::ButtonBox->new( 'horizontal' );
    $bbox->set_layout( 'end' );
    $box->add( $bbox );

    my $btn = Gtk3::Button->new_from_icon_name( 'gtk-go-back', 3 );
    $btn->signal_connect(
        clicked => sub {
            $flow->previous_page;
        }
    );
    $bbox->add( $btn );
    $btn = Gtk3::Button->new_from_icon_name( 'gtk-go-forward', 3 );
    $btn->signal_connect(
        clicked => sub {
            $flow->next_page;
        }
    );
    $bbox->add( $btn );
    $box->show_all;

    $flow->append_page( $box );
    $flow->set_page_type( $box, 'custom' );
}

sub create_page5 {
    my $box = Gtk3::Box->new( 'vertical', 5 );
    $box->set_border_width( 5 );
    $box->set_homogeneous( TRUE );

    my $label = Gtk3::Label->new( "<b>" . _( 'Gutmann overwrite' ) . "</b>" );
    $label->set_use_markup( TRUE );
    $box->add( $label );

    $label
        = Gtk3::Label->new( _( 'This option overwrites files 35 times.' ) );
    $box->add( $label );

    $label = Gtk3::Label->new( 'https://wikipedia.org/wiki/Gutmann_method' );
    $box->add( $label );

    my $bbox = Gtk3::ButtonBox->new( 'horizontal' );
    $bbox->set_layout( 'end' );
    $box->add( $bbox );

    my $btn = Gtk3::Button->new_from_icon_name( 'gtk-go-back', 3 );
    $btn->signal_connect(
        clicked => sub {
            $flow->previous_page;
        }
    );
    $bbox->add( $btn );
    $btn = Gtk3::Button->new_from_icon_name( 'gtk-go-forward', 3 );
    $btn->signal_connect(
        clicked => sub {
            $flow->next_page;
        }
    );
    $bbox->add( $btn );

    $box->show_all;
    $flow->append_page( $box );
    $flow->set_page_type( $box, 'custom' );
}

sub create_page6 {
    my $box = Gtk3::Box->new( 'vertical', 5 );
    $box->set_border_width( 5 );
    $box->set_homogeneous( TRUE );

    my $label = Gtk3::Label->new( "<b>RCMP overwrite</b>" );
    $label->set_use_markup( TRUE );
    $label->set_line_wrap( TRUE );
    $box->add( $label );

    $label = Gtk3::Label->new(
        _( 'This option overwrites files three times.' ) . "\n\n"
            . _(
            'The first pass writes 0x00, the second uses 0xFF, and the third uses RCMP.'
            )
    );
    $box->add( $label );

    my $bbox = Gtk3::ButtonBox->new( 'horizontal' );
    $bbox->set_layout( 'end' );
    $box->add( $bbox );

    my $btn = Gtk3::Button->new_from_icon_name( 'gtk-go-back', 3 );
    $btn->signal_connect(
        clicked => sub {
            $flow->previous_page;
        }
    );
    $bbox->add( $btn );
    $btn = Gtk3::Button->new_from_icon_name( 'gtk-go-forward', 3 );
    $btn->signal_connect(
        clicked => sub {
            $flow->next_page;
        }
    );
    $bbox->add( $btn );
    $btn->set_sensitive( FALSE );
    $btn = Gtk3::Button->new_from_icon_name( 'gtk-close', 3 );
    $btn->signal_connect(
        clicked => sub {
            $flow->destroy;
        }
    );
    $bbox->add( $btn );

    $box->show_all;
    $flow->append_page( $box );
    $flow->set_page_type( $box, 'custom' );
}

1;
