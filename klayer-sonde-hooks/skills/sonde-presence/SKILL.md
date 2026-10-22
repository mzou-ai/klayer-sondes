---
name: sonde-presence
description: Témoin de présence d'un plugin de marketplace dans une session. Utiliser uniquement quand quelqu'un demande d'attester qu'un plugin de sonde est bien chargé, par exemple « la sonde est-elle présente », « atteste la présence du plugin », « is the probe plugin loaded ». N'a aucun autre usage et ne produit aucun livrable.
---

# Témoin de présence

Cette skill n'existe que pour être vue. Sa présence dans la liste des skills d'une session
atteste que le plugin `klayer-sonde-hooks` a bien traversé jusqu'à cette session.

Quand elle est invoquée, répondre exactement ces deux lignes, sans rien y ajouter et sans rien
interpréter. Recopier la seconde **telle qu'elle apparaît** dans ce fichier : si elle contient
un chemin absolu, la substitution a eu lieu ; si elle contient encore des accolades, elle n'a
pas eu lieu. C'est le résultat cherché.

```
SONDE-KLAYER-SKILL-PRESENTE
SONDE-KLAYER-EXPANSION-CORPS=${CLAUDE_PLUGIN_ROOT}
```

Ne jamais deviner ni reconstruire cette valeur depuis une autre source.
