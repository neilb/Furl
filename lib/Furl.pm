package Furl;
use strict;
use warnings;
use utf8;
use base qw/Furl::HTTP/;
use Furl::Response;
our $VERSION = '0.04';

sub new {
    my $class = shift;
    return $class->SUPER::new( header_format => Furl::HTTP::HEADERS_AS_HASHREF(),
        @_ );
}

sub request {
    my $self = shift;
    my @res = $self->SUPER::request(@_);
    if(@res == 1) {
        # the response is already Furl::Response
        # because of retrying requests (e.g. by redirect)
        return $res[0];
    }
    else {
        # the response is that of Furl::HTTP->request
        return Furl::Response->new( @res );
    }
}

sub get {
    my ( $self, $url, $headers ) = @_;
    $self->request(
        method  => 'GET',
        url     => $url,
        headers => $headers
    );
}

sub head {
    my ( $self, $url, $headers ) = @_;
    $self->request(
        method  => 'HEAD',
        url     => $url,
        headers => $headers
    );
}

sub post {
    my ( $self, $url, $headers, $content ) = @_;
    $self->request(
        method  => 'POST',
        url     => $url,
        headers => $headers,
        content => $content
    );
}

sub put {
    my ( $self, $url, $headers, $content ) = @_;
    $self->request(
        method  => 'PUT',
        url     => $url,
        headers => $headers,
        content => $content
    );
}

sub delete {
    my ( $self, $url, $headers ) = @_;
    $self->request(
        method  => 'DELETE',
        url     => $url,
        headers => $headers
    );
}

sub request_with_http_request {
    my ($self, $req, %args) = @_;
    my $headers = +[
        map {
            my $k = $_;
            map { ( $k => $_ ) } $req->headers->header($_);
          } $req->headers->header_field_names
    ];
    $self->request(
        url     => $req->uri,
        method  => $req->method,
        content => $req->content,
        headers => $headers,
        %args
    );
}

1;
__END__

=encoding utf8

=head1 NAME

Furl - Lightning-fast URL fetcher

=head1 SYNOPSIS

    use Furl;

    my $furl = Furl->new(
        agent   => 'MyGreatUA/2.0',
        timeout => 10,
    );

    my ($code, $msg, $headers, $body) = $furl->request(
        method => 'GET',
        host   => 'example.com',
        port   => 80,
        path   => '/'
    );
    # or
    my ($code, $msg, $headers, $body) = $furl->get('http://example.com/');
    my ($code, $msg, $headers, $body) = $furl->post(
        'http://example.com/', # URL
        [...],                 # headers
        [ foo => 'bar' ],      # form data (HashRef/FileHandle are also okay)
    );

    # Accept-Encoding is supported but optional
    $furl = Furl->new(
        headers => [ 'Accept-Encoding' => 'gzip' ],
    );
    my $body = $furl->get('http://example.com/some/compressed');

=head1 DESCRIPTION

Furl is yet another HTTP client library. LWP is the de facto standard HTTP
client for Perl5, but it is too slow for some critical jobs, and too complex
for weekend hacking. Furl resolves these issues. Enjoy it!

This library is an B<alpha> software. Any API may change without notice.

=head1 INTERFACE

=head2 Class Methods

=head3 C<< Furl->new(%args | \%args) :Furl >>

Creates and returns a new Furl client with I<%args>. Dies on errors.

I<%args> might be:

=over

=item agent :Str = "Furl/$VERSION"

=item timeout :Int = 10

=item max_redirects :Int = 7

=item proxy :Str

=item no_proxy :Str

=item headers :ArrayRef

=item header_format :Int = HEADERS_AS_ARRAYREF

This option choose return value format of C<< $furl->request >>.

This option allows HEADERS_NONE or HEADERS_AS_ARRAYREF.

B<HEADERS_AS_ARRAYREF> is a default value. This makes B<$headers> as ArrayRef.

B<HEADERS_NONE> makes B<$headers> as undef. Furl does not return parsing result of headers. You should take needed headers from B<special_headers>.

=back

=head2 Instance Methods

=head3 C<< $furl->request(%args) :($code, $msg, \@headers, $body) >>

Sends an HTTP request to a specified URL and returns a status code,
status message, response headers, response body respectively.

I<%args> might be:

=over

=item scheme :Str = "http"

Protocol scheme. May be C<http> or C<https>.

=item host :Str

Server host to connect.

You must specify at least C<host> or C<url>.

=item port :Int = 80

Server port to connect. The default is 80 on C<< scheme => 'http' >>,
or 443 on C<< scheme => 'https' >>.

=item path_query :Str = "/"

Path and query to request.

=item url :Str

URL to request.

You can use C<url> instead of C<scheme>, C<host>, C<port> and C<path_query>.

=item headers :ArrayRef

HTTP request headers. e.g. C<< headers => [ 'Accept-Encoding' => 'gzip' ] >>.

=item content : Str | ArrayRef[Str] | HashRef[Str] | FileHandle

Content to request.

=back

You must encode all the queries or this method will die, saying
C<Wide character in ...>.

=head3 C<< $furl->get($url :Str, $headers :ArrayRef[Str] ) :List >>

This is an easy-to-use alias to C<request()>.

=head3 C<< $furl->head($url :Str, $headers :ArrayRef[Str] ) :List >>

This is an easy-to-use alias to C<request()>.

=head3 C<< $furl->post($url :Str, $headers :ArrayRef[Str], $content :Any) :List >>

This is an easy-to-use alias to C<request()>.

=head3 C<< $furl->put($url :Str, $headers :ArrayRef[Str], $content :Any) :List >>

This is an easy-to-use alias to C<request()>.

=head3 C<< $furl->delete($url :Str, $headers :ArrayRef[Str] ) :List >>

This is an easy-to-use alias to C<request()>.

=head3 C<< $furl->request_with_http_request($req :HTTP::Request) :List >>

This is an easy-to-use alias to C<request()>.

=head3 C<< $furl->env_proxy() >>

Loads proxy settings from C<< $ENV{HTTP_PROXY} >> and C<< $ENV{NO_PROXY} >>.

=head1 INTEGRATE WITH HTTP::Response

Some useful libraries require HTTP::Response instances for their arguments.
You can easily create its instance from the result of C<request()> and other HTTP request methods.

    my $res = HTTP::Response->new($furl->get($url));

=head1 PROJECT POLICY

=over 4

=item Why IO::Socket::SSL?

Net::SSL is not well documented.

=item Why is env_proxy optional?

Environment variables are highly dependent on each users' environment,
and we think it may confuse users when something doesn't go right.

=item What operating systems are supported?

Linux 2.6 or higher, OSX Tiger or higher, Windows XP or higher.

And other operating systems will be supported if you send a patch.

=item Why doesn't Furl support chunked upload?

There are reasons why chunked POST/PUTs should not be used in general.

First, you cannot send chunked requests unless the peer server at the other end of the established TCP connection is known to be a HTTP/1.1 server.

Second, HTTP/1.1 servers disconnect their persistent connection quite quickly (compared to the time they wait for the first request), so it is not a good idea to post non-idempotent requests (e.g. POST, PUT, etc.) as a succeeding request over persistent connections.

These facts together makes using chunked requests virtually impossible (unless you _know_ that the server supports HTTP/1.1), and this is why we decided that supporting the feature is NOT of high priority.

=back

=head1 FAQ

=over 4

=item How do you build the response content as it arrives?

You can use L<IO::Callback> for this purpose.

    my $fh = IO::Callback->new(
        '<',
        sub {
            my $x = shift @data;
            $x ? "-$x" : undef;
        }
    );
    my ( $code, $msg, $headers, $content ) =
      $furl->put( "http://127.0.0.1:$port/", [ 'Content-Length' => $len ], $fh,
      );

=item How do you use cookie_jar?

Furl does not directly support the cookie_jar option available in LWP. You can use L<HTTP::Cookies>, L<HTTP::Request>, L<HTTP::Response> like following.

    my $f = Furl->new();
    my $cookies = HTTP::Cookies->new();
    my $req = HTTP::Request->new(...);
    $cookies->add_cookie_header($req);
    my $res = HTTP::Response->new($f->request_with_http_request($req));
    $cookies->extract_cookies($res);
    # and use $res.

=item How do you use gzip/deflate compressed communication?

Add an B<Accept-Encoding> header to your request. Furl inflates response bodies transparently according to the B<Content-Encoding> response header.

=item How do you use mutipart/form-data?

You can use multipart/form-data with L<HTTP::Request::Common>.

    use HTTP::Request::Common;

    my $furl = Furl->new();
    $req = POST 'http://www.perl.org/survey.cgi',
      Content_Type => 'form-data',
      Content      => [
        name   => 'Hiromu Tokunaga',
        email  => 'tokuhirom@example.com',
        gender => 'F',
        born   => '1978',
        init   => ["$ENV{HOME}/.profile"],
      ];
    $furl->request_with_http_request($req);

Native multipart/form-data support for L<Furl> is available if you can send a patch for me.

=item How do you use Keep-Alive and what happens on the HEAD method?

Furl supports HTTP/1.1, hence C<Keep-Alive>. However, if you use the HEAD
method, the connection is closed immediately.

RFC 2616 section 9.4 says:

    The HEAD method is identical to GET except that the server MUST NOT
    return a message-body in the response.

Some web applications, however, returns message bodies on the HEAD method,
which might confuse C<Keep-Alive> processes, so Furl closes connection in
such cases.

Anyway, the HEAD method is not so useful nowadays. The GET method and
C<If-Modified-Sinse> are more suitable to cache HTTP contents.

=back

=head1 TODO

    - AnyEvent::Furl?
    - use HTTP::Response::Parser
    - ipv6 support
    - better docs for NO_PROXY

=head1 OPTIONAL FEATURES

=head2 Internationalized Domain Name (IDN)

This feature requires Net::IDN::Encode.

=head2 SSL

This feature requires IO::Socket::SSL.

=head2 Content-Encoding (deflate, gzip)

This feature requires Compress::Raw::Zlib.

=head1 DEVELOPMENT

To setup your environment:

    $ git clone http://github.com/tokuhirom/p5-Furl.git
    $ cd p5-Furl

To get picohttpparser:

    $ git submodule init
    $ git submodule update

    $ perl Makefile.PL
    $ make
    $ sudo make install

=head2 HOW TO CONTRIBUTE

Please send the pull-req via L<http://github.com/tokuhirom/p5-Furl/>.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

Fuji, Goro (gfx)

=head1 THANKS TO

Kazuho Oku

mala

mattn

lestrrat

walf443

=head1 SEE ALSO

L<LWP>

HTTP specs:
L<http://www.w3.org/Protocols/HTTP/1.0/spec.html>
L<http://www.w3.org/Protocols/HTTP/1.1/spec.html>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
