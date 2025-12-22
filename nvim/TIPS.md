# Tips and tricks for vim

## Use coreutils in commands like

All these commmands can be used with:

`:% !` - For all lines in the current file
`:<,> !` - For a range of lines (visual selected mode)
`:r !` - If you want to read the output of cmd to current file

### Use `wc` to count lines in a file

  - `:r !wc -l %` - Will print the number of lines in the current file
  - `:r !wc -w %` - Will print the number of words in the current file

### Use `nl` to add line numbers to a selected list

Simple:

  - Select visual mode
  - `:<,> !nl`
  - It will print like `1 line1`

Adds a `n) ` after each line

  - Select visual mode
  - `:<,> !nl -s ') '`
  - It will print like `1) line1`

### Use `sort` to sort a list

  - Select visual mode
  - `:<,> !sort`
  - It will print like `line1 line2 line3`

### Use `uniq`

  - Select visual mode
  - `:<,> !uniq`
  - It will print like `line1 line2 line3`, removing duplicates

### Use 'column' to align text

  - `:%!column -t -s ' ' %` - Will print the current file in columns

## How does it work?

Symbols

  - `!` Starts an external shell command
  - `:` Starts a command syntaxe
  - `%` The (entire) current file
  - `<,>` A range of lines (visual selected mode)
  - `r` Read the output of the command to the current file
  - `w` Write the output of the command to the current file

Now you can use all of them in a command like
 - `:!` - Run an external shell command and print the output
 - `:%!` - Run an external shell command and write the output to the current file
 - `:r!` - Run an external shell command and read the output to the current file
 - `:w!` - Run an external shell command and write the output to the current file

