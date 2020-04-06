# Mailles de laine (wesh)

Un créateur de maillage dans le jeu pour Minetest

Développé et testé sur Minetest 0.4.16 - essayez les autres versions à vos risques et périls :)

Si vous aimez mes contributions, vous pouvez envisager de lire http://entuland.com/en/support-entuland

Fil de discussion du forum WIP MOD : https://forum.minetest.net/viewtopic.php?f=9&t=20115

# Recettes de toile

Toutes les recettes peuvent être configurées dans `/custom.recipes.lua`, qui sera créé la première fois que le mod sera lancé et ne sera jamais écrasé.

    W = n'importe quel bloc de laine
    I = ingrédient interne (voir liste ci-dessous)

    WWW
    WIW
    WWW

    wesh:canvas02 (lingot d'acier)
    wesh:canvas04 (lingot de cuivre)
    wesh:canvas08 (lingot d'étain)
    wesh:canvas16 (lingot de bronze) - wesh:canvas vous donne wesh:canvas16, conservé pour la compatibilité
    wesh:canvas32 (lingot d'or)
    wesh:canvas64 (diamant) lire l'avis après la capture d'écran

![Canvas recipe](/screenshots/canvas-recipe.png)

Ta plus grande taille de toile peut probablement créer des maillages trop complexes pour être rendus si vous essayez de saisir trop de nœuds.

C'est pourquoi il existe une limite facultative pour la quantité de visages capturés. Cette limite peut être librement modifiée ou désactivée dans le dialogue de capture. Si vous ne modifiez pas cette limite, le jeu devrait toujours générer des maillages fonctionnels.

# Comment utiliser

Placez un bloc de toile, vous verrez qu'il s'étend au-delà de son espace nodal en marquant un cube (disponible dans les tailles 2, 4, 8, 16 et 32)

Les captures d'écran suivantes montrent un exemple de l'aspect des toiles lorsqu'elles sont placées dans le monde (vous pouvez lire la taille sur la face supérieure), tenues en main et dans la barre rapide (dernier emplacement) :


Traduit avec www.DeepL.com/Translator (version gratuite)
![Canvas sizes](/screenshots/canvas-sizes.png)

Voici l'exemple utilisant la toile de taille 16 marquant son espace de capture :

![Empty canvas](/screenshots/canvas-empty.png)

Dans cet espace, vous pouvez construire tout ce que vous voulez en utilisant des blocs de laine colorés ou la plupart des blocs intégrés livrés avec minetest_game :

![Building inside the canvas](/screenshots/canvas-build.png)

Une fois que vous avez terminé votre construction, allez dans le bloc Canvas et cliquez dessus avec le bouton droit : il vous sera demandé de donner un nom à votre maillage (vous pouvez y taper n'importe quel texte, avec des majuscules et n'importe quel symbole).

Ici, vous pouvez également décider de générer ou non une matrice de sauvegarde que vous pourrez ensuite importer pour recréer le build, vous pouvez également spécifier dans quelles variantes vous souhaitez que votre mesh soit disponible.

Les matrices de sauvegarde sont des fichiers supplémentaires qui enregistrent les nœuds et les couleurs de votre build. Elles peuvent être utilisées pour reconstruire les captures avec les nœuds d'origine ou sous forme de laine en fonction de leurs couleurs correspondantes. Ces fichiers peuvent être omis sans risque si vous ne vous souciez pas de reconstruire vos créations (c'est-à-dire si vous ne les démontez pas ou si vous ne vous souciez pas de les recapturer).

Cette interface de capture vous donne également accès aux interfaces "Manage Meshes" et "Giveme Meshes", qui seront abordées plus loin dans cette documentation :

Traduit avec www.DeepL.com/Translator (version gratuite)

![Request for name](/screenshots/prompt-name.png)

Lorsque vous confirmez le nom de votre capture (vous pouvez l'annuler en appuyant sur la touche ESC), vous obtenez une confirmation dans le chat :

![Save confirmation](/screenshots/save-confirm.png)

![Plain version](/screenshots/version-plain.png)

![Plain bordered compare](/screenshots/plain-bordered-compare.png)

- versions laine : elles utiliseront les textures réelles utilisées par les blocs de laine, avec une variante bordée

![Wool version](/screenshots/version-wool.png)

![Wool bordered compare](/screenshots/wool-bordered-compare.png)

Exemple de capture de terrain naturel
:

![Non wool capture](/screenshots/non-wool-capture.png)

Les boîtes de collision seront construites automatiquement en fonction de l'étendue de votre maillage:

![Auto collision box](/screenshots/auto-collision-box.png)

Jusqu'à 8 boîtes de collision seront créées en fonction de la géométrie du maillage, ce qui vous permettra de créer des escaliers, des dalles, des cadres, des tapis et ainsi de suite, les boîtes de collision seront fusionnées dans des boîtes plus grandes lors de leur montage :

![Auto collision box 2](/screenshots/auto-collision-box-2.png)

Ces nouveaux blocs ne peuvent pas être créés, mais vous pouvez en obtenir autant que vous le souhaitez en cliquant sur le bouton "Giveme Meshes" de l'interface de capture, qui vous montrera quelque chose comme ceci (rappelez-vous que vous devez redémarrer le monde pour que de nouveaux maillages y apparaissent) :

![Giveme mesh](/screenshots/giveme-mesh.png)

Les noms ci-dessus peuvent également être utilisés avec les commandes "/give" et "/giveme".

Si vous jouez en mode créatif, tous ces maillages, y compris toutes les toiles, apparaissent si vous filtrez pour "wesh" ou "mesh" :

![Creative search](/screenshots/creative-search.png)


# Couleurs RG
L'un des derniers ajouts à ce mod a été de permettre la capture de nœuds en utilisant les couleurs RGB spécifiées dans le fichier [/default/colors.txt](/default/colors.txt) (dupliqué en `/custom.colors.txt` pour la personnalisation) - ce fichier a été extrait de [Minetest Mapper](https://github.com/minetest/minetestmapper/blob/master/colors.txt).

(discussion sur cette nouvelle fonctionnalité RGB [ici](https://github.com/entuland/wesh/issues/6))

En sélectionnant l'option "Ignorer les variantes, utiliser RGB" dans l'écran de capture, on obtient un maillage utilisant une palette personnalisée, construite à la volée, qui ressemble à ceci...

```
variantes = {
  rgb = "[combine:4x1:0,0=(px.png\\\^[colorize\\\:#42701f):1,0=(px.png\\\^[colorize\\\:#6c9343):2,0=(px.png\\\^[colorize\\\:#5f4027):3,0=(px.png\\\^[colorize\\\:#763018)",
},
```

...au lieu des variantes habituelles :

```
variantes = {
  laine = "wool-72.png",
  plain = "plain-16.png",
  plainborder = "plain-border-72.png",
  woolborder = "wool-border-72.png",
},
```

Cette palette RGB n'est *pas* compatible avec les variantes normales et vous ne pouvez pas utiliser les maillages RGB avec les palettes normales - plus d'informations sur les variantes dans la section [Propriétés personnalisées](#specification des propriétés personnalisées).

Si vous voulez avoir le même maillage avec la palette RBB personnalisée *et* avec les variantes habituelles, vous devez le capturer deux fois avec des noms différents.

# Privilèges

Trois privilèges distincts sont disponibles :
- `wesh_capture` limite la possibilité de créer de nouveaux maillages
- `wesh_place` limite la possibilité de placer les maillages créés dans le monde
- `wesh_delete` limite la possibilité de supprimer des mailles du disque
- `wesh_import` limite la possibilité d'importer des builds à partir de fichiers `.obj.matrix.dat`.
- `wesh_fill` limite la possibilité de remplir la toile avec des noeuds arbitraires (y compris l'air)

Tous ces privilèges sont accordés par défaut au "joueur unique".

Comme les toiles peuvent être créées et que l'interface de la toile permet aux joueurs d'obtenir des maillages gratuitement, le mode créatif n'est pas nécessaire pour utiliser ce mod.

# Gestion des maillages

Les maillages temporaires (ceux capturés dans la session de jeu en cours, en attente d'être déplacés dans le dossier du mod) peuvent être supprimés immédiatement à partir de l'interface "Gérer les maillages" : *il n'y aura PAS de confirmation lors de la suppression des captures temporaires !

[Supprimer le temporaire maintenant](/screenshots/delete-temporary-now.png)

Les maillages qui ont déjà été déplacés dans le dossier du mod ne peuvent pas être supprimés immédiatement et doivent être marqués pour être supprimés :

![Marquer pour suppression](/screenshots/mark-for-deletion.png)

Les suppressions en cours peuvent être annulées :

! [Annuler une suppression en cours](/screenshots/cancel-pending-deletion.png)

## Suppressions lors de jeux sur plusieurs mondes

Lorsque les mailles sont marquées pour être supprimées, cette information sera stockée dans le stockage du mod _associé à ce monde spécifique_ - cela signifie que pour que les suppressions aient lieu, vous devez quitter le monde et entrer à nouveau dans le même monde_.

Ces suppressions ne seront pas effectuées tant que vous n'entrerez pas à nouveau dans ce monde.

Tous les meshs seront finalement stockés dans le dossier du mod - cela signifie que _tous_ les mondes finiront par partager les _mêmes_ meshs. Si vous supprimez un maillage dans un monde, il disparaîtra pour tous les mondes.

# Traitement des matrices

Les fichiers matriciels n'enregistrent que les couleurs de votre construction et, à ce titre, n'utiliseront que des blocs de laine pour reconstruire vos créations lorsqu'elles seront importées en mode normal. Les autres modes sont expliqués ci-dessous.

Lorsque vous importez un fichier de matrice, il doit correspondre à la taille de la toile avec laquelle vous interagissez actuellement. Si la taille ne correspond pas, le mod affichera un message dans le chat disant cela et ne fera rien. Je prévois d'améliorer cela en enregistrant la taille de la matrice elle-même dans le nom du fichier.

Vous pouvez combiner différentes matrices ensemble en les important dans le même canevas en séquence.

Vous pouvez sélectionner trois modes différents pour importer les matrices :

- Les modes "Invert" et "Mononode" ne sont pas cochés : la matrice sera construite normalement selon les couleurs d'origine
- "Inverser" : la version négative de la matrice sera remplie avec le noeud que vous entrez dans la zone de texte
- Mononode : utilise le nom de noeud saisi pour importer la matrice au lieu des couleurs d'origine

Le mode "Mononode" peut être coché ou décoché en mode "Inversion", cela ne fait aucune différence.

[Matrice d'importation](/screenshots/import-matrix.png)

Vous pouvez également remplir complètement l'espace de la toile en utilisant le bouton "Remplir/vide" avec n'importe quel nœud, y compris l'air.

[Remplir la toile](/screenshots/fill-canvas.png)

Enfin, les matrices sont accessibles et peuvent être reconstruites immédiatement, sans qu'il soit nécessaire de redémarrer le monde. Cela signifie que vous pouvez utiliser cette fonctionnalité pour dessiner un plan et le reconstruire avec des blocs de laine immédiatement, autant de fois que vous le souhaitez, puis aller dans "Gérer les maillages" et supprimer cette capture temporaire pour éviter d'ajouter de nouveaux maillages à votre bibliothèque.

[Voici quelques exemples](/examples.md) expliquant comment utiliser certaines des fonctionnalités ci-dessus.

# Spécifier des propriétés personnalisées
Dans le fichier `.obj.dat` de chaque maille, vous trouverez quelque chose comme ceci :

```
return {
    description = "Votre nom de maille",
    variantes = {
        plain = "plain-16.png",
        plainborder = "plain-border-72.png",
        laine = "wool-72.png",
        woolborder = "wool-border-72.png",
    },
}
```

(veuillez considérer que le nombre `16` ci-dessus indique la taille de la texture, il n'a rien à voir avec la taille de la toile que vous utilisez pour capturer votre construction)

Les variantes utilisées dans chaque fichier `.obj.dat` dépendent de celles que vous sélectionnez dans l'interface au moment de la capture.

Les variantes par défaut sont stockées dans le fichier [/default/nodevariants.lua](/default/nodevariants.lua) qui est copié dans `/custom.nodevariants.lua` au démarrage du mod si un tel fichier n'existe pas.

Ces variantes seront celles affichées dans l'interface de capture.

Pour ajouter une nouvelle variante, ajoutez simplement une ligne avec votre nom de texture et assurez-vous d'enregistrer ce fichier de texture dans le dossier `/textures` du mod. Vous pouvez également supprimer les lignes qui ne vous intéressent pas et le mod ne générera pas ces variantes.

Vous pouvez faire l'opération ci-dessus soit sur le fichier `/custom.nodevariants.lua` (cela affectera toutes les nouvelles captures) ou dans le fichier `.obj.dat` associé à chaque mesh (n'affectera que ce mesh).

Par exemple, ici nous supprimons tout sauf la version "plain" et ajoutons une version personnalisée :

    return {
        description = "Votre nom de maille",
        variantes = {
            plain = "plain-16.png",
            mon_nom_de_texture_plaine = "mon_nom_de_fichier_de_texture.png",
        },
    }

Ce qui précède ne dépend pas des variantes disponibles dans `nodevariants.lua` - tant que vous utilisez un nom de clé différent et un fichier de texture existant, tout ira bien.

Jetez un coup d'oeil à `wool-72.png` pour voir où va chaque couleur, ou utilisez le fichier [textures-72.xcf](/textures/textures-72.xcf) inclus (format GIMP) qui a des couches pour ajouter les bordures également.

Comme expliqué dans [RGB Colors](#rgb-colors), les variantes normales et la palette personnalisée RGB ne sont pas compatibles. Vous ne pouvez pas ajouter de variantes régulières au fichier `.obj.dat` d'un maillage capturé en mode RVB, et vous ne pouvez pas ajouter une palette RVB personnalisée à un maillage capturé en utilisant les variantes régulières. Si vous avez besoin des deux modes, capturez le maillage deux fois avec des noms différents.

Vous pouvez également surcharger toute propriété que vous passez normalement à node_register(), comme `walkable`, `groups`, `co
