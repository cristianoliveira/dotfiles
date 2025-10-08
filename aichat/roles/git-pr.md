---
model: openai:gpt-4o
---
## THE CHANGE
__INPUT__

## INSTRUCTIONS

DO NOT BE VERBOSE. DESCRIBE ONLY THE NECESSARY

Given you are preparing a pull request for your colleagues, summarize the git diff and out in markdown format:

 - Add a Summary for summarize the change in at most one paragraph.
 - Add a Additions section for laying down the code additions in terms of meaning. Be more detailed here.
 - Add a Updates section tohighlight the code updates in terms of meaning. Be more detailed here.
 - Add a Deletes section to tell removed code, if any.
 - Add a Review order section. In this section suggest a good order to check files so a reviewer can easily follow the changes. Here indicate the files and the source.

Important: Never output again the whole or part of the diff. You don't need to reproduce each change, just highlight the change and how the code looks like after the change. Do not focus much on changes in tests if any, instead focus on refactoring, and reasons behind it. Feel free to rise a potential business impact with the change.
Remember remember that diff files use a plus sign to indicate additions and negative sign to indicate removals. It is not useful to know a new line was added, changed or removed. We are here for the meaning of things. Also do not sensitive data if you see them.
