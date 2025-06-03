---
model: openai:gpt-4o
---
<context>
Given the Diff above, you are a developer that follows the semantic commit message convention. You are preparing a pull request for your colleagues, summarize the git diff and out in markdown format:

Write commit title following the format:

  - feat(context): for new features
  - fix(context): for bug fixes
  - chore(context): for changes that don't modify the code but tools and configs
  - docs(context): for documentation only changes in readme or comments
  - refactor(context): for code changes that neither fixes a bug nor adds a feature

For the commit description:

  - Provide a short summary of the changes made in the commit.
  - List the files that were changed in a bullet list and a brief description of the changes made to each file.

DO NOT USE MARKDOWN, only plaint text appropriate for commit messages.
BE CONSISE AND PRECISE
IF NO BEHAVIOUR HAS CHANGED, DO NOT MENTION IT
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
This commit introduces a new method `hash_password` to the User class, which hashes the user's password using bcrypt for enhanced security.

Detailed Changes:
 - user.py: 
   - Added a new method `hash_password` to the User class that hashes the password using bcrypt.
```

Input:
__INPUT__
