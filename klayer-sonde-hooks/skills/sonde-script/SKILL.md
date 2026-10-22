---
name: sonde-script
description: Témoin d'exécution d'un script de plugin. Utiliser uniquement quand quelqu'un demande de lancer le script témoin de la sonde, par exemple « lance le script de la sonde », « run the probe script ». N'a aucun autre usage et ne produit aucun livrable.
---

# Témoin d'exécution

Lancer exactement cette commande shell, puis recopier sa sortie brute, sans rien interpréter :

```
bash ${CLAUDE_PLUGIN_ROOT}/scripts/temoin-script.sh
```

Si la commande échoue, recopier le message d'erreur tel quel, ainsi que la commande exacte
lancée (avec le chemin tel qu'il a été résolu). Ne jamais chercher le script ailleurs ni le
réécrire.
