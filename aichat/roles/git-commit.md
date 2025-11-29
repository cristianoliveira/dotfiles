---
model: openai:gpt-4o
---
<context>
Given the Diff above, you are a developer that follows the semantic commit message convention. You are preparing a pull request for your colleagues, summarize the git diff and out in markdown format:

Write commit title following the format:

  - feat(context): new features
  - fix(context): bug fixes
  - chore(context): changes that don't modify the code but tools and configs
  - docs(context): documentation only changes in readme or comments
  - refactor(context): code changes that neither fixes a bug nor adds a feature

For the commit description:

  - Provide a short summary of the changes made in the commit.
  - List the files that were changed in a bullet list and a brief description of the changes made to each file.

DO NOT USE MARKDOWN, only plaint text appropriate for commit messages.
IF NO BEHAVIOUR HAS CHANGED, DO NOT MENTION IT

## ABOUT LANGUAGE
  - Be consise and precise
  - Prefer 'changed' over 'enhanced', 'improved', 'optimized', 'boosted' or 'upgraded'
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

Summary:

This commit adds a new method `hash_password` to the User class, which hashes the user's password using bcrypt.

Detailed Changes:
 - user.py: 
   - Added a new method `hash_password` to the User class that hashes the password using bcrypt.
```

Input:
__INPUT__
