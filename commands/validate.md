# /validate

Validate the current or provided Lua light effect script.

## Usage

```
/validate
```

Validates the last generated script in the current conversation.

```
/validate <paste script here>
```

Validates the provided script.

## What It Does

1. Checks metadata format and required fields
2. Runs the script with 100 pixels × 10 frames in Code Interpreter
3. Verifies all onRender calls return valid Color values
4. Reports any errors found
5. If errors exist, offers to fix them automatically

## Output

- ✅ PASS — script is valid and ready for deployment
- ❌ FAIL — shows error details and fix suggestions
