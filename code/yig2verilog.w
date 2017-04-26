\nocon
\nosecs
\def\title{YIG to Verilog parser (Mathias Soeken, EPFL)}

@*Intro.  This program reads a YIG from standard input and writes an
equivalent Verilog file to the standard output.  Each net assignment
is directly translated into large nested majority-expressions.  Since
Verilog has no majority-operation as primitive, the expressions become
rather large.  However, the generated output can be read into ABC
using the `\.{read\_verilog}' command.  ABC can then be used to
translate it into many different formats, e.g., And-inverter graphs.

@ The main program first validates the command line.  It then parses
the YIG and generates the Verilog code on-the-fly.  The program
handles errors in a quite general way.  If at any point, an error
occurs, the corresponding line is reported and the program
terminates. No further reason is provided.  Also note that |buf| may
have changed while parsing and it may not be reported completely.

The first two definitions can be used to change the resource limits of
the program.  In its default configuration, it can process at most
99\,999 inputs, outputs, and wires.  And the size of a $Y$ operation
is limited to 30.  Note that the $Y_{30}$ operation has 496 inputs.

@d log_max_ids 5 /* we can have at most $10^5 - 1 = 99\,999$ inputs, ouputs, and wires */
@d max_y_size 30 /* maximum size of $Y$ operation */
@d max_y_args ((max_y_size+1)*(max_y_size+2))/2 /* maximum operands in $Y$ operation */

@c
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

typedef unsigned int uint;
typedef char args_vec[max_y_args][max_y_args + 3];

@<Subroutines@>;

int main( int argc, char *argv[] ) {
  char * buf = NULL, *rhs, *p;
  char type;
  size_t buflen, size, nargs;
  args_vec args;
  int first = 1, i, j;
  uint npis = 0u, npos = 0u, nwires = 0u, id;

  @<Process the command line@>;
  @<Parse and transform YIG@>;
  return 0;

parse_error:@;
  fprintf( stderr, "[e] cannot parse %s\n", buf );
  return 1;
}

@ We expect no program argument.

@<Process the command line@>=
if ( argc != 1 ) {
  fprintf( stderr, "Usage: %s < design.yig\n", argv[0] );
  return 1;
}

@ We parse the YIG and generate Verilog code on-the-fly.  We
distinguish between two different lines.  A nonempty line can contain
a command; in this case it starts with a `\.{.}'.  Otherwise, we
assume it is an assignment, either to an internal wire or to an output
signal.  If the command is an assignment, the string is split at the
|=| sign.

@<Parse and transform YIG@>=
while ( 1 ) {
  if ( getline( &buf, &size, stdin ) != -1 ) {
    buflen = strlen( buf );
    @<Trim |buf|@>;
    if ( !buflen ) continue; /* empty line */
    if ( buf[0] == '.' && buflen > 1 ) { /* command */
      @<Parse command@>;
    }
    else { /* assignment */
      @<Print Verilog header, if it's the first time@>;
      @<Find |=| separator@>;
      @<Split string@>;
      @<Parse left-hand side@>;
      @<Parse right-hand side@>;
    }
  }
}
@<Print Verilog footer@>;

@ If last character is newline, strip it from |buf|.
@<Trim |buf|@>=
if ( buflen && buf[buflen - 1] == '\n' ) buf[--buflen] = '\0';

@ There are four different commands.  The header commands are all
followed by a nonnegative number and are `\.{i}' for the number of
inputs, `\.{o}' for the number of outputs, and `\.{w}' for the number
of wires.  The command `\.{e}' indicates the end of the design and
triggers to exit the parsing loop.

@<Parse command@>=
if ( buf[1] == 'e' ) break;
else if ( buf[1] == 'i' ) { @+npis = atoi( buf + 3 ); @+ }
else if ( buf[1] == 'o' ) { @+npos = atoi( buf + 3 ); @+ }
else if ( buf[1] == 'w' ) { @+nwires = atoi( buf + 3 ); @+ }
else goto parse_error;

@ A net assignment has a left-hand side and a right-hand side that is
separated by |=|.  We find the position of |=| and store it as a
result in |rhs| that represents the substring starting from there.  If
it cannot be found, the program terminates.

@<Find |=| separator@>=
rhs = buf; while ( *rhs != '=' && *rhs != '\0' ) ++rhs;
if ( *rhs == '\0' ) goto parse_error;

@ This essentially splits the YIG string into the left-hand side |buf|
and right-hand side |rhs|. Also we strip leading white spaces from |rhs|.

@<Split string@>=
*rhs++ = '\0';
while ( *rhs == ' ' ) { ++rhs; }

@ The left-hand side of a net assignment consists of a character that
is either `\.{w}' (for wire assignment) or `\.{o}' (for output
assignment).

@<Parse left-hand side@>=
type = *buf; /* wire or output */
if ( type != 'w' && type != 'o' ) goto parse_error;
id = atoi( buf + 1 );
if ( id == 0u ) goto parse_error;
if ( type == 'w' && id > nwires ) goto parse_error;
if ( type == 'o' && id > npos ) goto parse_error;

@ Parsing the right-hand size consists of some checks and the
population of the |args| array with the arguments of the $Y$ module.

@<Parse right-hand side@>=
if ( *rhs++ != 'Y' ) goto parse_error;
p = rhs + 1; while ( *p != '(' && *p != '\0' ) ++p;
if ( *p == '\0' ) goto parse_error;
*p = '\0';
size = atoi( rhs );
if ( size < 0 ) goto parse_error;
nargs = ( size + 1 ) * ( size + 2 ) / 2;
i = 0, j = 0;
while ( 1 )
{
  switch ( *( ++p ) ) {
  default: args[i][j++] = *p; @+break;
  case ' ': continue;
  case ')':
  case ',':
    if ( j == 1 ) { /* constant assignment */
      args[i][3] = args[i][0];
      args[i][0] = '1'; @+args[i][1] = '\''; @+args[i][2] = 'b';
      j = 4;
    }
    args[i][j] = '\0'; ++i; j = 0; break;
  case '\0': goto next;
  }
}
next:
if ( i != nargs ) goto parse_error;

@<Print Verilog assignment@>;

@ We make use of the fact, that the underlying grid of the $Y$
function is defined based on barycentric coordinates.  This function
translates a barycentric coordinate into an index of the |args| array.
Note that we can omit the $z$-coordinate.  The index is uniquely
determined by only providing $x$ and $y$, even if the dimension is not
known.

@<Subroutines@>=
size_t bar_to_index( size_t x, size_t y ) {
  return ( ( x + y ) * ( x + y + 1 ) / 2 ) + x;
}

@ In the remainder, we define some code and routines to print Verilog
code.  The Verilog header is printed when the first assignment is
being parsed.

@<Print Verilog header, if it's the first time@>=
if ( first ) {
  first = 0;
  printf( "module top( " );
  for ( i = 1; i <= npis; ++i ) {
    if ( i > 1 ) printf( ", " );
    printf( "i%d", i );
  }
  for ( i = 1; i <= npos; ++i ) {
    if ( npis || i > 1 ) printf( ", " );
    printf( "o%d", i );
  }
  printf( " );\n" );
  print_vars( "input", 'i', npis );
  print_vars( "output", 'o', npos );
  print_vars( "wire", 'w', nwires );
}

@ We use this subroutine to print variable initialization for inputs,
outputs, and wires.

@<Subroutines@>=
void print_vars( const char * name, char prefix, uint count ) {
  int i;
  if ( count ) {
    printf( "  %s ", name );
    for ( i = 1; i <= count; ++i ) {
      if ( i > 1 ) printf( ", " );
      printf( "%c%d", prefix, i );
    }
    printf( ";\n" );
  }
}

@ This prints a Verilog assignment to a $Y$ function.  We start
recursion on |print_expression| with the current size.

@<Print Verilog assignment@>=
printf( "  assign %c%d = ", type, id );
print_expression( args, 0, 0, size );
printf( ";\n" );

@ This function recurses by splitting larger $Y$ functions into
smaller ones.  If it finds a $Y_0$ function, it is translated into a
literal.

@<Subroutines@>=
void print_expression( args_vec args, size_t x, size_t y, size_t n ) {
  int i1, i2, i3;
  if ( n == 0 ) {
    printf( args[bar_to_index( x, y )] );
  } else {
    printf( "((" );
    print_expression( args, x, y, n - 1 );
    printf( " & " );
    print_expression( args, x, y + 1, n - 1 );
    printf( ") | (" );
    print_expression( args, x, y, n - 1 );
    printf( " & " );	  
    print_expression( args, x + 1, y, n - 1 );
    printf( ") | (" );
    print_expression( args, x, y + 1, n - 1 );
    printf( " & " );
    print_expression( args, x + 1, y, n - 1 );
    printf( "))" );
  }
}

@ That's all, folks!

@<Print Verilog footer@>=
printf( "endmodule // top\n" );
if (buf)
  free(buf);

@*Index.
