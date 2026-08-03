# Smart Light Agent

> A Git-repo-based AI agent for the Smart Light platform, powered by AWS Bedrock AgentCore Harness.

## What This Repo Does

This repository **IS** the agent. Point the Harness at this repo URL and it becomes a fully functional smart light effect AI assistant that can:

- Generate Lua LED effect scripts from natural language
- Modify existing effects based on user feedback
- Validate scripts by actually running them (Code Interpreter)
- Remember user preferences (AgentCore Memory)

## Directory Structure

```
smart-light-agent/
├── AGENT.md                          # Agent persona & behavior rules
├── README.md                         # This file
├── skills/
│   ├── effect_generate/SKILL.md      # Lua script generation rules
│   ├── effect_modify/SKILL.md        # Effect modification rules
│   └── effect_validate/SKILL.md      # Validation & self-fix rules
├── knowledge/
│   ├── lua_api_reference.md          # Complete ctx/Color/WaveForm API
│   ├── common_mistakes.md            # Error patterns & fixes (RAG)
│   └── example_effects/              # Reference scripts (RAG)
│       ├── sunset_breathing.lua
│       ├── rainbow_chase.lua
│       └── starry_night.lua
└── commands/
    └── validate.md                   # /validate slash command
```

## How It Works with Harness

| This Repo | Harness Feature |
|-----------|-----------------|
| `AGENT.md` | System prompt / persona |
| `skills/` | Inlined into system prompt as capabilities |
| `knowledge/` | Bedrock Knowledge Base → RAG retrieval |
| `commands/` | `/validate` available in chat composer |
| Code Interpreter | Runs Lua test harness to validate scripts |
| AgentCore Memory | Stores per-user preferences & history |

## Deployment

1. Push this repo to GitHub/CodeCommit
2. Deploy Harness infrastructure via CloudFormation
3. In Harness UI, paste the repo URL
4. Agent is live — users can start chatting

## Adding More Effects to Knowledge Base

Drop `.lua` files into `knowledge/example_effects/`. The Harness will automatically ingest them into the Knowledge Base for RAG retrieval. The more examples you provide, the better the generation quality.

## Customization

- Edit `AGENT.md` to change the agent's behavior
- Add new skills in `skills/` for new capabilities
- Add reference docs in `knowledge/` to improve generation quality
- All changes take effect on next repo reload (paste URL again or restart)
