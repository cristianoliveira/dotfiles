---
use_tools: all
---
## INSTRUCTIONS

DO NOT BE VERBOSE. DESCRIBE ONLY THE NECESSARY

Given you are preparing a pull request for your colleagues, summarize the git diff and out in markdown format:

 - Add a Summary for summarize the change in at most one paragraph.
 - Add a Additions section for laying down the code additions in terms of meaning. Be more detailed here.
 - Add a Updates section tohighlight the code updates in terms of meaning. Be more detailed here.
 - Add a Deletes section to tell removed code, if any.
 - Add a Review order section. In this section suggest a good order to check files so a reviewer can easily follow the changes. Here indicate the files and the source.

## IMPORTANT:
 - DO NOT use language like "changed x for better maintainability" or "refactored y to improve code quality" or any other generic statements that are subjective, stick with objective changes.
 - DO NOT use language like "This release improved x for better y" or any alternative of that, simply state the changes "This release added x" or "This release fixed y".
 - DO NOT add links unless explicitly mentioned in the commits or diff.
 - NEVER output again the whole or part of the diff. You don't need to reproduce each change, just highlight the change and how the code looks like after the change. Do not focus much on changes in tests if any, instead focus on refactoring, and reasons behind it. Feel free to rise a potential business impact with the change.

Understanding diff:
```diff
diff --git a/user.py b/user.py
index <old_hash>..<new_hash> 100644
--- a/user.py
+++ b/user.py
@@ -10,6 +10,13 @@
         self.email = email
         self.password = password

+    def hash_password(self, password):
+        """Hashes the password using bcrypt."""
+        import bcrypt
+        hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
+        self.password = hashed.decode('utf-8')
+
-    # __repr__ method handles
+    # __repr__ method handles string representation of the user object
     def __repr__(self):
         return f"<User(email='{self.email}')>"
-    # A commend
```
How to read that:
```text
This commit adds a new method `hash_password` to the User class, which hashes the user's password using bcrypt.

Detailed Changes:
- Added a new method `hash_password` to the User class that hashes the password using bcrypt.
- Updated comment for the `__repr__` method with more context.
- Removed a comment at the end of the file.
```

Inputs are defined as:
 - {{git_commit_list}} - The git commit list if available
 - {{git_diff}} - The git diff if available
 - {{git_staged_diff}} - The git staged diff if available
 - {{context}} - Task manually added context if available

### INPUT

### OUTPUT
