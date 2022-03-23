## Search replace

```bash
vim -o file1.txt file2.txt
```

Usage:

This function acts on the QuickFix file list, so in order to register the list
of files to apply the refactoring do:

Simple usage:

  - `<Leader>rft` to register the `[t]arget` word
  - `<Leader>rfr` to register the `[r]eplace` word
  - `<Leader>rff` to `[f]ind` and register instances of `[t]arget` in all files into quickfix
  - `<Leader>rfa` to refactoring `[a]pply`

Other ways to register the quickfix list:
  - `<Leader>gg` to search all instances
  - `<Leader>k` to search all instances of the word under cursor
