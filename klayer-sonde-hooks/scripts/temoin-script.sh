#!/usr/bin/env bash
# Témoin d'exécution : lancé depuis un corps de SKILL.md, il prouve qu'un script du plugin
# s'exécute dans la session. N'écrit rien.
echo "SONDE-KLAYER-SCRIPT-EXECUTE | uname=$(uname -s 2>/dev/null || echo ?) | pwd=$(pwd) | racine=${CLAUDE_PLUGIN_ROOT:-absente}"
