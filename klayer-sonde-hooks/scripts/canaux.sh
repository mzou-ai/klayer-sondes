#!/usr/bin/env bash
# Sonde jetable v0.5 : teste les canaux de sortie JSON d'un hook, à côté du texte brut de trace.sh.
# Chaque canal porte un jeton distinct, pour savoir lequel atteint le modèle ou l'interface.
# N'écrit QUE sous ${CLAUDE_PLUGIN_ROOT}/trace/. Ne refuse qu'une commande contenant le canari.
set -u

payload="$(cat 2>/dev/null || true)"

field() {
  printf '%s' "$payload" | python3 -c "import sys,json;
try: d=json.load(sys.stdin)
except Exception: d={}
v=d
for k in '$1'.split('.'):
    v=v.get(k,'') if isinstance(v,dict) else ''
print(v or '')" 2>/dev/null
}

ev="$(field hook_event_name)"
sid="$(field session_id)"
tool="$(field tool_name)"
cmd="$(field tool_input.command)"

dir="${CLAUDE_PLUGIN_ROOT:-.}/trace"
mkdir -p "$dir" 2>/dev/null || true
printf '%s\tcanaux\tevent=%s\ttool=%s\tsession=%s\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${ev:-?}" "${tool:--}" "${sid:-?}" >> "$dir/hook-trace.log" 2>/dev/null

case "$ev" in
  SessionStart|UserPromptSubmit)
    # additionalContext vise le modèle ; systemMessage vise l'interface.
    printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"SONDE-KLAYER-JSON-CONTEXTE | event=%s | session=%s"},"systemMessage":"SONDE-KLAYER-JSON-SYSMSG | event=%s"}\n' \
      "$ev" "$ev" "${sid:-?}" "$ev"
    ;;
  PreToolUse)
    # Canari : seule une commande qui contient ce jeton est refusée. Le motif doit revenir tel quel.
    case "$cmd" in
      *SONDE-KLAYER-CANARI*)
        printf '%s\tcanaux\tdeny-emis\ttool=%s\tsession=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${tool:--}" "${sid:-?}" >> "$dir/hook-trace.log" 2>/dev/null
        printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"SONDE-KLAYER-DENY-APPLIQUE | tool=%s"}}\n' "${tool:--}"
        ;;
    esac
    ;;
esac
exit 0
