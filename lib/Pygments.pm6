use v6.d;
unit class Pygments:ver<0.0.1>;

use Inline::Python;

my Inline::Python $py;

INIT {
    $py .= new;
    $py.run: q:to/SETUP/;
    from pygments import highlight
    from pygments.lexers import get_lexer_by_name, guess_lexer
    from pygments.formatters import get_formatter_by_name
    from pygments.styles import STYLE_MAP, get_style_by_name
    SETUP

    $py.run: %?RESOURCES<perl.py>.slurp;
}

method call($name, |c) {
    $py.call('__main__', $name, |c)
}

method highlight(Str $code, $lexer = Any, :$formatter = 'html', *%options) is export {
    my $l = do given $lexer {
        when 'perl6' { self.call('Perl6Lexer') }
        when *.defined { self.call('get_lexer_by_name', $lexer) }
        default { self.call('guess_lexer', $code) }
    };

    my $f = $.formatter($formatter, |%options);
    $py.call('pygments', 'highlight', $code, $l, $f)
}

method formatter($name, *%options) is export {
    self.call('get_formatter_by_name', $name, |%options)
}

method style(Str $name = 'default') {
    $py.call('pygments.styles', 'get_style_by_name', $name)
}

method styles {
    $py.run('list(STYLE_MAP.keys())', :eval).map: *.decode
}

=begin pod

=head1 NAME

Pygments - Wrapper to python pygments library.

=head1 SYNOPSIS

  use Pygments;

  my $code = q:to/ENDCODE/;
  grammar Parser {
      rule  TOP  { I <love> <lang> }
      token love { '♥' | love }
      token lang { < Perl Rust Go Python Ruby > }
  }

  say Parser.parse: 'I ♥ Perl';
  # OUTPUT: ｢I ♥ Perl｣ love => ｢♥｣ lang => ｢Perl｣

  say Parser.parse: 'I love Rust';
  # OUTPUT: ｢I love Rust｣ love => ｢love｣ lang => ｢Rust｣
  ENDCODE

  # Get a theme.
  my $css = Pygments.css('manni');

  # Format a full html with line numbers and theme `manni`
  my $formatted-code = Pygments.highlight(
      $code, "perl6",
      :linenos(True),
      :style($css),
      :full(True)
  );

  say $formatted-code;

=head1 DESCRIPTION

Pygments is a wrapper for the L<pygments|http://pygments.org> python library.

=head1 METHODS

There's no need to instantiate the C<Pygments> class. All the methods can be called
directly.

=head2 highlight

=for code
method highlight(Str $code, $lexer, :$formatter = 'html', *%options)

Highlight the C<$code> with the lexer passed by paramenter. If no lexer is provided,
pygments will try to guess the lexer that will use.

=head2 style

=for code
method style(Str $name = 'default')

Get a single style with name C<$name>

=head2 styles

=for code
method styles

Return a list of all the available themes.

=head1 AUTHOR

Matias Linares <matiaslina@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Matias Linares

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
