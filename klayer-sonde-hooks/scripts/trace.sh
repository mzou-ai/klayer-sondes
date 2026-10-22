#!/usr/bin/env bash
# Sonde jetable : trace un déclenchement de hook de plugin, quelle que soit la surface.
# N'écrit QUE sous ${CLAUDE_PLUGIN_ROOT}/trace/. Ne bloque jamais, ne modifie rien d'autre.
set -u

payload="$(cat 2>/dev/null || true)"

field() {
  printf '%s' "$payload" \
    | python3 -c "import sys,json;
try: d=json.load(sys.stdin)
except Exception: d={}
print(d.get('$1','') or '')" 2>/dev/null \
    || printf '%s' "$payload" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
}

ev="$(field hook_event_name)"
sid="$(field session_id)"
tool="$(field tool_name)"
cwd="$(field cwd)"

dir="${CLAUDE_PLUGIN_ROOT:-.}/trace"
mkdir -p "$dir" 2>/dev/null || true
printf '%s\tevent=%s\ttool=%s\tsession=%s\tcwd=%s\tplugin_root=%s\thost=%s\tuname=%s\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${ev:-?}" "${tool:--}" "${sid:-?}" "${cwd:-?}" \
  "${CLAUDE_PLUGIN_ROOT:-?}" "$(hostname 2>/dev/null || echo ?)" "$(uname -s 2>/dev/null || echo ?)" \
  >> "$dir/hook-trace.log" 2>/dev/null

# Signal visible dans la session elle-même (stdout d'un UserPromptSubmit est injecté en contexte).
echo "SONDE-KLAYER-HOOK-PLUGIN-ACTIF | event=${ev:-?} | session=${sid:-?} | cwd=${cwd:-?} | plugin_root=${CLAUDE_PLUGIN_ROOT:-?} | uname=$(uname -s 2>/dev/null || echo ?)"

# Publication du chemin du corpus, mécanisme même que le plan met à l'épreuve : le hook résout
# ${CLAUDE_PLUGIN_ROOT} et écrit un chemin littéral, sans dépendre d'une substitution ailleurs.
corpus="${CLAUDE_PLUGIN_ROOT:-?}/skills/sonde-presence/references/corpus-temoin.md"
if [ -r "$corpus" ]; then
  echo "SONDE-KLAYER-CORPUS-CHEMIN | lisible-par-le-hook=oui | $corpus"
else
  echo "SONDE-KLAYER-CORPUS-CHEMIN | lisible-par-le-hook=non | $corpus"
fi

# Inventaire des noms d'outils par mode. Le matcher PreToolUse est large, on se contente de
# nommer l'outil vu. La trace fait l'inventaire, run après run.
if [ "$ev" = "PreToolUse" ]; then
  echo "SONDE-KLAYER-OUTIL-VU | ${tool:--}"
fi

# Un hook peut-il écrire dans le DOSSIER CONNECTÉ ? Une seule tentative par session, sur le
# premier UserPromptSubmit : SessionStart ne tire pas sur toutes les surfaces (mesuré le
# 2026-08-15), ce qui rendait le test muet. Candidats : le montage cloud v1, le cwd, et le
# dossier projet que l'hôte déclare.
garde="$dir/ecriture-tentee-${sid:-sans-id}"
if [ "$ev" = "UserPromptSubmit" ] && [ ! -f "$garde" ]; then
  : > "$garde" 2>/dev/null || true
  vus=0
  for cand in /mnt/user-data/uploads/cowork-folders/*/ "${cwd:-/nonexistent}" "${CLAUDE_PROJECT_DIR:-/nonexistent}"; do
    [ -d "$cand" ] || continue
    vus=$((vus + 1))
    probe="${cand%/}/.klayer-sonde-jetable"
    if mkdir -p "$probe" 2>/dev/null && : > "$probe/ecriture-test.txt" 2>/dev/null; then
      echo "SONDE-KLAYER-ECRITURE-DOSSIER-CONNECTE | ecriture=oui | $probe/ecriture-test.txt"
    else
      echo "SONDE-KLAYER-ECRITURE-DOSSIER-CONNECTE | ecriture=non | ${cand%/}"
    fi
  done
  # Un candidat absent n'est PAS un refus d'écriture : le dire, plutôt que de se taire.
  if [ "$vus" -eq 0 ]; then
    echo "SONDE-KLAYER-ECRITURE-DOSSIER-CONNECTE | ecriture=indeterminee | aucun dossier candidat (cwd=${cwd:-?}, CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR:-absent})"
  fi
fi
exit 0
