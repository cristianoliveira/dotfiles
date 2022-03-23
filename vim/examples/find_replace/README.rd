## Search replace

```bash
vim -o file1.txt file2.txt
```

Usage:
 - Grep using either:
  -  `<Leader>gg` to search all instances
  -  `<Leader>k` to search all instances of the word under cursor
 - Replace by using the Refactoring maps
  - `<Leader>rft` to register the `[t]arget` word
  - `<Leader>rfr` to register the `[r]eplace` word
  - `<Leader>rfa` to refactoring apply
