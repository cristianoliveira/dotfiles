#!/usr/bin/env bun
/**
 * OpenCode Orchestrator Delegation Plugin
 *
 * When an orchestrator/primary agent hits a permission denial, this plugin
 * shows a helpful message directing the user to delegate the task
 * to another agent using the `aimeta subagents` CLI command.
 *
 * Only triggers for primary/orchestrator agents, not for subagents.
 */

import { appendFileSync } from "fs";

interface PermissionEvent {
  type: string;
  properties?: {
    id?: string;
    sessionID?: string;
    permission?: string;
    patterns?: string[];
    tool?: string;
    reply?: "yes" | "no" | boolean;
    requestID?: string;
  };
}

interface SessionInfo {
  agent?: {
    name?: string;
    mode?: "primary" | "subagent";
  };
  [key: string]: unknown;
}

/**
 * File-based logging helper
 * Writes logs to /tmp/orchestrator-delegation.log with timestamp and level
 */
function log(level: string, message: string, extra?: any) {
  const timestamp = new Date().toISOString();
  const extraStr = extra ? ` | ${JSON.stringify(extra)}` : "";
  const logEntry = `[${timestamp}] [${level}] ${message}${extraStr}\n`;
  appendFileSync("/tmp/orchestrator-delegation.log", logEntry);
}

/**
 * OpenCode plugin for orchestrator delegation on permission denials
 * @param context - OpenCode plugin context with client and session info
 * @returns Plugin hooks
 */
async function orchestratorDelegationPlugin(context: { client?: any }) {
  // Cache for session agent info to avoid repeated API calls
  const sessionAgentCache = new Map<string, SessionInfo>();

  // Log plugin initialization
  try {
    log("INFO", "Plugin initialized");
  } catch {
    // Silently fail if logging doesn't work
  }

  /**
   * Helper to determine if an agent is a primary/orchestrator agent
   * Checks agent configuration and naming patterns
   */
  function isPrimaryAgent(agent?: { name?: string; mode?: string }): boolean {
    if (!agent) return false;

    // Check explicit mode field (primary vs subagent)
    if (agent.mode === "primary") return true;

    // Check agent name patterns that indicate orchestrator
    const agentName = agent.name?.toLowerCase() || "";
    const orchestratorPatterns = [
      "orchestrator",
      "coordinator",
      "primary",
      "lead",
      "main",
      "controller",
    ];

    return orchestratorPatterns.some((pattern) => agentName.includes(pattern));
  }

  /**
   * Get agent info for a given session
   * Uses client API with caching to avoid repeated calls
   */
  async function getSessionAgent(
    sessionID?: string
  ): Promise<SessionInfo | null> {
    if (!sessionID) return null;

    // Check cache first
    if (sessionAgentCache.has(sessionID)) {
      return sessionAgentCache.get(sessionID) || null;
    }

    // Try to get session info via client API
    if (!context.client?.session?.get) return null;

    try {
      const result = await context.client.session.get({ path: { id: sessionID } });
      if (result.error || !result.data) {
        // Log session fetch error
        try {
          log("DEBUG", "Failed to fetch session info", {
            sessionID,
            error: result.error || "No data returned",
          });
        } catch {
          // Silently fail if logging doesn't work
        }
        return null;
      }

      const sessionInfo = result.data as SessionInfo;
      sessionAgentCache.set(sessionID, sessionInfo);
      return sessionInfo;
    } catch (error) {
      // Log error if API call fails
      try {
        log("ERROR", "Error fetching session info", {
          sessionID,
          error: error instanceof Error ? error.message : String(error),
        });
      } catch {
        // Silently fail if logging doesn't work
      }
      return null;
    }
  }

  return {
    /**
     * Observe permission events to detect denials for orchestrators
     * Triggers on permission.asked and permission.replied events
     */
    event: async (input: {
      event?: PermissionEvent;
    }) => {
      const event = input.event;
      if (!event) return;

      const eventType = event.type;
      const props = event.properties || {};

      // Only care about permission denial events
      const isPermissionAsked = eventType === "permission.asked";
      const isPermissionDenied =
        eventType === "permission.replied" &&
        (props.reply === "no" || props.reply === false);

      // Log permission-related events (avoid logging all events to prevent spam)
      if (isPermissionAsked || isPermissionDenied) {
        try {
          log("DEBUG", `Permission event received: ${eventType}`, {
            eventType,
            isDenied: isPermissionDenied,
            permission: props.permission,
            tool: props.tool,
          });
        } catch {
          // Silently fail if logging doesn't work
        }
      }

      if (!isPermissionAsked && !isPermissionDenied) {
        return;
      }

      // Get the session ID to look up agent info
      const sessionID = props.sessionID;
      if (!sessionID) return;

      // Get session and agent information
      const sessionInfo = await getSessionAgent(sessionID);
      if (!sessionInfo || !sessionInfo.agent) {
        return;
      }

      // Log agent check
      try {
        log("DEBUG", `Checking agent: ${sessionInfo.agent.name}`, {
          agentName: sessionInfo.agent.name,
          agentMode: sessionInfo.agent.mode,
          isPrimary: isPrimaryAgent(sessionInfo.agent),
        });
      } catch {
        // Silently fail if logging doesn't work
      }

      // Only show delegation message for primary/orchestrator agents
      if (!isPrimaryAgent(sessionInfo.agent)) {
        return;
      }

      // For permission.asked events, we can't modify the flow,
      // so we just observe. For permission.replied with denial,
      // we log a helpful message (but the decision is already made).
      // The delegation message is shown to guide the user.

      if (isPermissionDenied) {
        // Log permission denial detected
        try {
          log("INFO", `Permission denied for orchestrator: ${sessionInfo.agent.name}`, {
            agentName: sessionInfo.agent.name,
            tool: props.tool,
            permission: props.permission,
          });
        } catch {
          // Silently fail if logging doesn't work
        }

        // Log showing delegation message
        try {
          log("INFO", `Delegation message shown to: ${sessionInfo.agent.name}`);
        } catch {
          // Silently fail if logging doesn't work
        }

        console.log(`
Permission blocked for orchestrator agent "${sessionInfo.agent.name}".
To delegate this task to a specialized agent, run:

  aimeta subagents

This will show you available agents and how to use them.
`);
      }
    },
  };
}

// Named export for OpenCode plugin system
export { orchestratorDelegationPlugin };
// Default export for compatibility
export default orchestratorDelegationPlugin;
