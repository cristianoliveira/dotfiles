# OpenCode Plugin Events Timeline Quick Check

Use this page when a task depends on "when does this event fire".

## Read Routing

| Need | Read Next |
| --- | --- |
| Full plugin shape and hook map | `sdk-surface.md` |
| `client.*` call examples inside hooks | `sdk-client-usage.md` |
| Minimal runnable plugin skeleton | `example-plugin.md` |

## Section A - Confirmed Event Catalog (From Docs/Source)

- Caveat: docs, generated SDK types, and runtime bus implementations can drift; validate critical payload fields in live logs before strict parsing.

### Plugin hooks

| Event name/type | When it fires | Useful payload fields | Confidence | Source link |
| --- | --- | --- | --- | --- |
| `event` (plugin hook catch-all) | On each runtime bus event delivered to plugin hooks | `input.event.type`, `input.event.properties` | Medium | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts |
| `command.execute.before` | Before command template execution | `input.command`, `input.sessionID`, `input.arguments`; mutable `output.parts` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts |
| `chat.message` | When building outbound user message payload | `input.sessionID`, `input.agent`, `input.model`, optional `input.messageID`; mutable `output.message`, `output.parts` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts |
| `chat.params` | Before LLM call parameter finalization | `input.model`, `input.provider`, `input.message`; mutable `output.temperature`, `output.topP`, `output.topK`, `output.options` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts |
| `chat.headers` | Before provider request headers are sent | `input.model`, `input.provider`, `input.message`; mutable `output.headers` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts |
| `tool.definition` | While preparing tool schema/description for model-facing tool list | `input.toolID`; mutable `output.description`, `output.parameters` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts |
| `tool.execute.before` | Before tool execution | `input.tool`, `input.sessionID`, `input.callID`; mutable `output.args` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts |
| `tool.execute.after` | After tool execution | `input.tool`, `input.sessionID`, `input.callID`, `input.args`; mutable `output.title`, `output.output`, `output.metadata` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts |
| `shell.env` | Before shell execution env is assembled | `input.cwd`, optional `input.sessionID`, `input.callID`; mutable `output.env` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts |
| `experimental.chat.messages.transform` | Experimental message-list transform before model call | Mutable `output.messages[]` (`info`, `parts`) | Medium | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts |
| `experimental.chat.system.transform` | Experimental system-prompt transform before model call | `input.sessionID`, `input.model`; mutable `output.system[]` | Medium | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts |
| `experimental.session.compacting` | Before session compaction prompt generation | `input.sessionID`; mutable `output.context[]`, optional `output.prompt` override | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts |
| `experimental.text.complete` | Experimental text completion post-processing hook | `input.sessionID`, `input.messageID`, `input.partID`; mutable `output.text` | Medium | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts |

### Runtime bus events

| Event name/type | When it fires | Useful payload fields | Confidence | Source link |
| --- | --- | --- | --- | --- |
| `server.connected` | Immediately when SSE event stream connects | Usually empty `properties` object | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/server/server.ts ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/server/routes/global.ts |
| `session.created` | When a session is created | `properties.info` (`id`, `title`, `projectID`, `time`) | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `session.updated` | When session metadata changes | `properties.info` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `session.deleted` | When a session is removed | `properties.info` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `session.status` | When session status transitions | `properties.sessionID`, `properties.status.type` (`busy`/`retry`/`idle`) | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `session.idle` (legacy-compatible completion label) | When session reaches idle state | `properties.sessionID` | Medium | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `session.compacted` | After compaction completes | `properties.sessionID` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `session.error` | When session run errors | `properties.sessionID?`, `properties.error?` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `message.updated` | When message record is created/updated | `properties.info` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `message.removed` | When message is deleted | `properties.sessionID`, `properties.messageID` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `message.part.updated` | When part content/state is upserted | `properties.part` (varies by `part.type`) | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/session/message-v2.ts |
| `message.part.delta` | During streaming incremental part field updates | `properties.sessionID`, `properties.messageID`, `properties.partID`, `properties.field`, `properties.delta` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/session/message-v2.ts ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/session/index.ts |
| `message.part.removed` | When a part is deleted | `properties.sessionID`, `properties.messageID`, `properties.partID` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `permission.asked` | Current permission request event | `properties.id`, `properties.sessionID`, `properties.permission`, `properties.patterns[]`, optional `properties.tool` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/permission/next.ts |
| `permission.replied` | Permission request is answered | New flow: `sessionID`, `requestID`, `reply`; legacy flow: `sessionID`, `permissionID`, `response` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/permission/next.ts ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/permission/index.ts |
| `permission.updated` (legacy) | Legacy permission request raised | Legacy permission object fields (`id`, `type`, `sessionID`, `messageID`, `metadata`, etc.) | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/permission/index.ts ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `question.asked` | Question prompt is emitted to UI/client | `properties.id`, `properties.sessionID`, `properties.questions[]`, optional `properties.tool` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/question/index.ts |
| `question.replied` | Question receives answer(s) | `properties.sessionID`, `properties.requestID`, `properties.answers[]` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/question/index.ts |
| `question.rejected` | Question is dismissed/rejected | `properties.sessionID`, `properties.requestID` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/question/index.ts |
| `file.edited` | File edit operation completed | `properties.file` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `file.watcher.updated` | Filesystem watcher reports add/change/unlink | `properties.file`, `properties.event` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `todo.updated` | Todo list changes | `properties.sessionID`, `properties.todos[]` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `command.executed` | Command execution finishes | `properties.name`, `properties.sessionID`, `properties.arguments`, `properties.messageID` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `lsp.updated` | LSP status update emitted | `properties` shape is open/unknown | Medium | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `lsp.client.diagnostics` | LSP diagnostics update emitted | `properties.serverID`, `properties.path` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `vcs.branch.updated` | Git branch value changes after watcher-triggered re-check | `properties.branch?` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/project/vcs.ts |
| `pty.created` | PTY instance is created | `properties.info` (id/title/command/args/cwd/status/pid) | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/pty/index.ts |
| `pty.updated` | PTY metadata/state changes | `properties.info` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/pty/index.ts |
| `pty.exited` | PTY process exits | `properties.id`, `properties.exitCode` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/pty/index.ts |
| `pty.deleted` | PTY record is removed | `properties.id` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/pty/index.ts |
| `tui.prompt.append` | TUI prompt text gets appended | `properties.text` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/cli/cmd/tui/event.ts |
| `tui.command.execute` | TUI command is invoked | `properties.command` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/cli/cmd/tui/event.ts |
| `tui.toast.show` | TUI toast notification event | `properties.title?`, `properties.message`, `properties.variant`, `properties.duration?` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/cli/cmd/tui/event.ts |
| `tui.session.select` | TUI requests navigation to a selected session | `properties.sessionID` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/cli/cmd/tui/event.ts |
| `installation.update-available` | Update check finds newer version | `properties.version` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/installation/index.ts ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/cli/upgrade.ts |
| `installation.updated` | Installation version/state update event | `properties.version` | High | https://opencode.ai/docs/plugins/ ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts |
| `mcp.tools.changed` | MCP server notifies tools list changed | `properties.server` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/mcp/index.ts |
| `mcp.browser.open.failed` | Browser open attempt fails during MCP OAuth | `properties.mcpName`, `properties.url` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/mcp/index.ts |
| `worktree.ready` | Async worktree bootstrap succeeds | `properties.name`, `properties.branch`; emitted on global event stream with `directory` wrapper | Medium | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/worktree/index.ts ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/server/routes/global.ts |
| `worktree.failed` | Async worktree bootstrap/create flow fails | `properties.message`; emitted on global event stream with `directory` wrapper | Medium | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/worktree/index.ts ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/server/routes/global.ts |
| `server.instance.disposed` | Instance disposal occurs and per-project stream is about to close | `properties.directory` | High | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/bus/index.ts ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/server/server.ts |
| `global.disposed` | Global dispose endpoint triggers full-instance teardown | Empty `properties` object; global stream only | Medium | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/server/routes/global.ts |
| `project.updated` | Project metadata/worktree/sandbox changes are emitted | Project payload (`id`, `worktree`, `vcs?`, `name?`, `icon?`, `time`, `sandboxes`) via global stream wrapper | Medium | https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/project/project.ts ; https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/server/routes/global.ts |

## Inferred Assumptions (Validate Per Task)

| Assumption | Why inferred | Confidence |
| --- | --- | --- |
| Event payload fields differ by event and are not stable enough to hardcode without checks | Docs enumerate names but not per-event schemas; `event` hook is typed as generic SDK `Event` | Medium |
| Hook execution order follows plugin load order across configs/directories | Plugin system executes hooks by loaded hook list sequence | High |
| `event` hook receives bus events after plugin init completes | `Plugin.init()` subscribes to bus and dispatches into `hook.event` handlers | High |

## Ordering, Caveats, and Unknowns

- Confirmed: plugin hooks run in sequence based on load order (global config, project config, global plugin dir, project plugin dir).
- Confirmed: plugin manager dispatches hook calls sequentially; expensive handlers can delay downstream hooks.
- Caveat: docs list event names, but most event payload schemas are not documented in plugin docs.
- Unknown: exact field-level schema and ordering relationships between many event pairs (for example `message.updated` vs `message.part.updated`) require runtime inspection.
- Practical default: branch on `event.type`, guard missing fields, and log samples before writing strict logic.

## Source Links

- https://opencode.ai/docs/plugins/
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/plugin/index.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/sdk/js/src/gen/types.gen.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/session/message-v2.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/session/index.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/installation/index.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/cli/upgrade.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/permission/index.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/permission/next.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/question/index.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/pty/index.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/cli/cmd/tui/event.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/mcp/index.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/project/vcs.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/project/project.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/worktree/index.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/bus/index.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/server/server.ts
- https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/server/routes/global.ts
