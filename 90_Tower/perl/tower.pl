#!/usr/bin/env perl

use 5.010;      # To get 'state' and 'say'

use strict;     # Require explicit declaration of variables
use warnings;   # Enable optional compiler warnings

use English;    # Use more friendly names for Perl's magic variables
use Term::ReadLine;     # Prompt and return user input

our $VERSION = '0.000_01';

# Manifest constant representing the maximum number of disks. We can
# change this within limits. It needs to be at least 3 or the
# explanatory text will contain negative numbers. There is no known
# upper limit, though if it is more than 10 the output lines can be more
# than 80 columns, and if it is more than 49 the disk numbers will be
# more than two digits, which will cause output lines not to align
# properly.
use constant MAX_DISKS  => 7;

print <<'EOD';
                                 TOWERS
               Creative Computing  Morristown, New Jersey


EOD

while ( 1 ) {   # Iterate until something makes us stop.

    print <<'EOD';
Towers of Hanoi Puzzle.

You must transfer the disks from the left to the right
Tower, one at a time, never putting a larger disk on a
smaller disk.

EOD

    # Get the desired number of disks to work with.
    my $size = get_input(

        # Manifest constants do not interpolate into strings. This can
        # be worked around using the @{[ ... ]} construction, which
        # interpolates any expression.
        "How many disks do you want to move (@{[ MAX_DISKS ]} is max)? ",

        sub {

            # Accept any response which is an integer greater than zero
            # and less than or equal to the maximum number of disks.
            # NOTE that 'and' performs the same operation as &&, but
            # binds much more loosely.
            return m/ \A [0-9]+ \z /smx &&
                $ARG > 0 &&
                $ARG <= MAX_DISKS;
        },

        3,
        "Sorry, but I can't do that job for you.\n",    # Warning
        <<'EOD',
All right, wise guy, if you can't play the game right, I'll
just take my puzzle and go home.  So long.
EOD
    );

    # Expressions can be interpolated using @{[ ... ]}
    print <<"EOD";
In this program, we shall refer to disks by numerical code.
3 will represent the smallest disk, 5 the next size,
7 the next, and so on, up to @{[ MAX_DISKS * 2 + 1 ]}.  If you do the puzzle with
2 disks, their code names would be @{[ MAX_DISKS * 2 - 1 ]} and @{[ MAX_DISKS * 2 + 1 ]}.  With 3 disks
the code names would be @{[ MAX_DISKS * 2 - 3 ]}, @{[ MAX_DISKS * 2 - 1 ]} and @{[ MAX_DISKS * 2 + 1 ]}, etc.  The needles
are numbered from left to right, 1 to 3.  We will
start with the disks on needle 1, and attempt to move them
to needle 3.


Good luck!

EOD

    # Compute the legal disk numbers for this puzzle. The expression
    # reads right to left thus:
    #   * The .. operator generates the integers between and including
    #     its end points, that is, from MAX_DISKS + 1 - $size to
    #     MAX_DISKS, inclusive.
    #   * map { .. } calls the block once for each of its arguments.
    #     The value of the argument appears in the topic variable $ARG,
    #     and the result of the block is returned.
    #   * The list generated by the map {} is assigned to array
    #     @legal_disks.
    my @legal_disks = map { $ARG * 2 + 1 }
        MAX_DISKS + 1 - $size ..  MAX_DISKS;

    # Generate the board. This is an array of needles, indexed from
    # zero. Each needle is represented by a reference to an array
    # containing the disks on that needle, bottom to top.
    my @board = (
        [ reverse @legal_disks ],
        [],
        []
    );

    display( \@board ); # Display the initial board.

    my $moves = 0;  # Move counter.

    while ( 1 ) {   # Iterate until something makes us stop.
        my $disk = get_input(
            'Which disk would you like to move? ',
            sub {
                # Accept any odd integer in the required range.
                # NOTE that 'and' performs the same operation as &&, but
                # binds much more loosely.
                return m/ \A [0-9]+ \z /smx &&
                    $ARG % 2 &&
                    $ARG >= ( MAX_DISKS + 1 - $size ) * 2 + 1 &&
                    $ARG <= MAX_DISKS * 2 + 1;
            },
            3,
            do {    # Compound statement and scope for 'local'

                # We want to interpolate @legal_disks into our warning.
                # Interpolation of an array places $LIST_SEPARATOR
                # between the elements of the array. The default is ' ',
                # but we want ', '. We use 'local' to restrict the
                # change to the current block and code called by it.
                # Failure to localize the change can cause Spooky Action
                # at a Distance.
                local $LIST_SEPARATOR = ', ';

                "Illegal entry... You may only type @legal_disks\n";
            },
            "Stop wasting my time.  Go bother someone else.\n",
        );

        # Return the number (from zero) of the needle which has the
        # desired disk on top. If the desired disk is not found, we got
        # undef back. In this case we redo the innermost loop.
        redo unless defined( my $from = find_disk( $disk, \@board ) );

        # Find out where the chosen disk goes.
        # NOTE that unlike the BASIC implementation, we require the
        # needle to be moved.
        my $to = get_input(
            'Place disk on which needle? ',
            sub {
                # Accept integers 1 through 3, but not the current
                # location of the disk
                return m/ \A [0-9]+ \z /smx &&
                    $ARG > 0 &&
                    $ARG <= 3 &&
                    $ARG != $from + 1;
            },
            2,
            <<'EOD',
I'll assume you hit the wrong key this time.  But watch it,
I only allow one mistake.
EOD
            <<'EOD',
I tried to warn you, but you wouldn't listen.
Bye bye, big shot.
EOD
        ) - 1;

        # Check for placing a larger disk on a smaller one. The check is
        # that the destination needle has something on it (an empty
        # array is false in Boolean context) and that the destination
        # needle's top disk ([-1] selects the last element of an array)
        # is smaller than the source needle's disk.
        if ( @{ $board[$to] } && $board[$to][-1] < $board[$from][-1] ) {
            warn <<'EOD';
You can't place a larger disk on top of a smaller one,
It might crush it!
EOD
            redo;
        }

        # Remove the selected disk from its needle, and place it on the
        # destination needle.
        push @{ $board[$to] }, pop @{ $board[$from] };

        $moves++;   # Count another move.

        display( \@board ); # Display the current board.

        # If all the disks are on the last needle, we are done.
        if ( @{ $board[2] } == $size ) {

            # Print a success message
            print <<"EOD";
Congratulations!

You have performed the task in $moves moves.

EOD
            last;   # Exit the innermost loop.

        # If the maximum allowed moves have been exceeded
        } elsif ( $moves >= 2 ** MAX_DISKS ) {

            # Warn
            warn <<"EOD";
Sorry, but I have orders to stop if you make more than
$moves moves.
EOD

            last;   # Exit the innermost loop.
        }
    }

    say '';
    get_input(
        'Try again? [y/N]: ',
        sub {
            exit if $ARG eq '' || m/ \A n /smxi;
            return m/ \A y /smxi;
        },
        ~0, # The 1's complement of 0 = largest possible integer
        "Please respond 'y' or 'n'\n",
    );
}

# Display the board, which is passed in as a reference.
sub display {
    my ( $board ) = @_;
    say '';

    # Use a manifest constant for an empty needle. This is global
    # despite its appearing to be nested in the subroutine. Perl uses
    # 'x' as its string replication operator. The initial 4 blanks
    # accommodate the disk number and spacing between needles.
    use constant EMPTY_NEEDLE   => ' ' x 4 . ' ' x MAX_DISKS . '|' .
        ' ' x MAX_DISKS;

    # Iterate over the rows to be printed.
    foreach my $inx ( reverse 0 .. MAX_DISKS ) {

        my $line;   # Line buffer.

        # Iterate over needles.
        foreach my $col ( 0 .. 2 ) {

            # If this position on the needle is occupied
            if ( my $disk_num = $board->[$col][$inx] ) {

                # Compute the width of a half disk
                my $half_width = ( $disk_num - 1 ) / 2;

                # Compute the graphic for the half disk. Perl uses 'x'
                # as its string replication operator.
                my $half_disk = '*' x $half_width;

                # Append the disk to the line. The inner sprintf() does
                # most of the work; the outer simply pads the graphic to
                # the required total width.
                $line .= sprintf( '%*s', -( MAX_DISKS * 2 + 5 ),
                    sprintf( '%*d %s|%s', MAX_DISKS + 3 - $half_width,
                        $disk_num, $half_disk, $half_disk ) );

            # Else this position is not occupied
            } else {

                # So just append the empty needle.
                $line .= EMPTY_NEEDLE;
            }
        }

        # Remove white space at the end of the line
        $line =~ s/ \s+ \z //smx;

        # Display the line
        say $line;
    }
    {   # Display the needle numbers
        my $line;
        foreach my $col ( 0 .. 2 ) {
            $line .= sprintf '%*d%*s', MAX_DISKS + 5, $col + 1,
            MAX_DISKS, ' ';
        }
        $line =~ s/ \s+ \z //smx;
        say $line;
    }

    say ''; # Empty line

    return;
}

# Find the named disk. The arguments are the disk number (which is
# assumed valid) and a reference to the board. If the disk is found on
# the top of a needle, the needle's index (from zero) is returned.
# Otherwise a warning is issued and undef is returned.
sub find_disk {
    my ( $disk, $board ) = @_;
    foreach my $inx ( 0 .. 2 ) {
        @{ $board->[$inx] }                 # If the needle is occupied
            and $disk == $board->[$inx][-1] # and we want its topmost
            and return $inx;                # return needle index
    }

    # Since we assume the disk number is valid but we did not find it,
    # it must not be the topmost disk.
    warn "That disk is below another one.  Make another choice.\n";

    return undef;
}

# Input subroutine. The arguments are:
# * The prompt.
# * Validation code. This recieves the input in the topic variable $ARG,
#   and returns a true value if the validation passed, and a false value
#   if it failed.
# * The maximum number of tries before dying.
# * The warning message for a validation failure, with trailing "\n".
# * The error message when the number of tries is exceeded, with
#   trailing "\n".
# The return is the valid input. We exit if end-of-file is reached,
sub get_input {
    my ( $prompt, $validate, $tries, $warning, $error ) = @_;

    # Instantiate the readline object. A state variable is only
    # initialized once.
    state $term = Term::ReadLine->new( 'tower' );

    while ( 1 ) {   # Iterate until something makes us stop.

        # The input gets read into the localized topic variable. If it
        # is undefined, it signals end-of-file, so we exit.
        exit unless defined( local $ARG = $term->readline( $prompt ) );

        # Call the validation code. If it returns a true value, we
        # return our input.
        return $ARG if $validate->();

        # Die if we are out of retries. In Perl, 0 is false and all
        # other integers are true.
        die $error unless --$tries;

        # Warn.
        warn $warning;
    }
}

__END__

=head1 TITLE

tower.pl - Play the game 'tower' from Basic Computer Games

=head1 SYNOPSIS

 tower.pl

=head1 DETAILS

This Perl script is a port of C<tower>, which is the 90th entry in Basic
Computer Games.

=head1 PORTED BY

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the Artistic
License 1.0 at
L<https://www.perlfoundation.org/artistic-license-10.html>, and/or the
Gnu GPL at L<http://www.gnu.org/licenses/old-licenses/gpl-1.0.txt>.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set expandtab tabstop=4 textwidth=72 :
