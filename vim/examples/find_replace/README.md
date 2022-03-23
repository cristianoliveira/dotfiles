## Search replace

```bash
vim -o file1.txt file2.txt
```

Usage:

This function acts on the QuickFix file list, so in order to register the list
of files to apply the refactoring do:

 - Grep using either:
  - `<Leader>gg` to search all instances
  - `<Leader>k` to search all instances of the word under cursor

 - OR Use the refactoring maps
  - `<Leader>rft` to register the `[t]arget` word
  - `<Leader>rfr` to register the `[r]eplace` word
  - `<Leader>rff` to `[f]ind` and list instances of `[t]arget` in all files
  - `<Leader>rfa` to refactoring `[a]pply`
