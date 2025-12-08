---
temperature: 0.2
top_p: 1
---
<context>
Given the Diff above, you are a developer that follows the semantic commit message convention. You are preparing a pull request for your colleagues, summarize the git diff and out in markdown format:

Write commit title following the format:

  - feat(context): new features
  - fix(context): bug fixes
  - chore(context): changes that don't modify the code but tools and configs
  - docs(context): documentation only changes in readme or comments
  - refactor(context): code changes that neither fixes a bug nor adds a feature

IMPORTANT: the commit title MUST HAS LENGTH BETWEEN 10 AND 80 CHARACTERS

For the commit description:

  - Provide a short summary of the changes made in the commit.
  - List the files that were changed in a bullet list and a brief description of the changes made to each file.

Categorizing the changes: <order_is_important>
  - Implementation:
    - Any changes to the code or logic of the application.
  - Documentation:
    - Any changes to the documentation of the application, like Markdown or readme files.
    - Changes in comments in the code.
  - Tests:
    - Any changes related to testing the application.
  - Dependencies:
    - Any changes in the dependencies of the application.
  - Development Experience:
    - Changes in scripts or Makefiles
    - Changes in the CI/CD pipeline

DO NOT USE MARKDOWN, only plaint text appropriate for commit messages.
IF NO BEHAVIOUR HAS CHANGED, DO NOT MENTION IT

## ABOUT LANGUAGE
  - Be consise and precise
  - Prefer 'changed' over 'enhanced', 'improved', 'optimized', 'boosted' or 'upgraded'
  - Avoid words like 'streamlined'
  - DO NOT use language like "Changed x for better maintainability" or "Refactored y to improve code quality" focus on what changed, I add the whys

</context>

Example:
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
     def __repr__(self):
         return f"<User(email='{self.email}')>"
```
Expected output:
```text
feat(auth): hash password using bcrypt

This commit adds a new method `hash_password` to the User class, which hashes the user's password using bcrypt.

Detailed Changes:
 - Implementation: 
   - Added a new method `hash_password` to the User class that hashes the password using bcrypt.
 - Documentation:
   - Updated the documentation to reflect the new method and its functionality.
```

Input:
__INPUT__
