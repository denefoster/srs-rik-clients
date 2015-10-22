package SRS::Client::GpgMe;

use strict;
use warnings;

use Carp;

use IO::File;
use Crypt::GpgME;

sub new {
    my ($class, $passphrase) = @_;

    my $self = {
        'ctx' => Crypt::GpgME->new,
    };

    bless $self, $class;

    $ctx->set_passphrase_cb(sub { $passphrase });

    return $self;

}

sub verify {
    my ($self, $data) = @_;

    my $verified = $self->{'ctx'}->verify($data);

    return $verified;

}

sub sign {
    my ($self, $data) = @_;

    my $signed = $ctx->sign( $data );

    return $signed;

}


