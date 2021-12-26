# Protowave

## Style guide

| Term | Style |
|---|---|
| Variable | do_snake_case_lowercase |
| Function | Capitalised_Underscores |
| Assembly | allowercase |
| Numbers | Hexadecimal (0x08) |
| File name | Capitalised_Underscores.s |


Commenting for subroutines are done using // on the first line of the subroutine.
Line comments are done using ; and are (by default double) tabbed so they are on the same line.

The default indendation used is double tab for the asm syntax, but the arguments are single tabbed so they fit on the same line from the asm syntax.

```assembly
main:
        // Subroutine decl comment goes here
        // IN: if a WREG in variable is used it is defined here
        // OUT: if a WREG variable is returned it is defined here

        movlw   0x00            ; set the variable to 0
        movwf   some_variable   ; variable does x

```

