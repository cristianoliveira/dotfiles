---
name: web-explorer
description: Explore web pages by controlling an opened browser using surf CLI. Use when user wants to explore web content, extract page information, or interact with web pages programmatically. Triggers on phrases like "explore web page", "browse website", "use surf", "web content extraction", or when needing to control a browser.
---

# Web Explorer

Explore web pages by controlling a browser using the `surf` CLI tool. Navigate, read content, interact with elements, and extract meaningful information from web pages.

## Prerequisites

Start by running `surf --help` to verify `surf` is installed and available.

## Surf CLI Quick Reference

```bash
# Navigation
surf go "https://example.com"
surf back
surf forward

# Read page content (returns element refs like e1, e2, e3)
surf read
surf search "text"

# Interact with elements (use refs from surf read)
surf click e5
surf type "text" --ref e12
surf type "text" --submit
surf key Enter

# Screenshots
surf screenshot

# Tabs
surf tab.list
surf tab.new "https://example.com"
surf tab.switch <id>

# Wait conditions
surf wait 2
surf wait.network
```

## Workflow

1. **Navigate**: Use `surf go <URL>` to open the page
2. **Read content**: Use `surf read` to get page elements and their references
3. **Interact**: Use `surf click`, `surf type`, or `surf search` based on element references
4. **Wait if needed**: Use `surf wait` or `surf wait.network` for dynamic content
5. **Extract**: Summarize the relevant content, focusing on main content areas

## Best Practices

- Focus on main content areas, ignore navigation/sidebars/ads
- Preserve code blocks, commands, and technical details exactly
- For complex pages, use `surf search "keyword"` to locate specific sections
- Use element references (e1, e2, etc.) from `surf read` for interactions
- Take screenshots with `surf screenshot` for visual verification when helpful
