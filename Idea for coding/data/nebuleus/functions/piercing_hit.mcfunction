particle minecraft:electric_spark ~ ~ ~ 0.25 0.25 0.25 0 30 force
particle minecraft:reverse_portal ~ ~ ~ 0.25 0.25 0.25 0 30 force
particle minecraft:flash ~ ~ ~ 0.01 0.01 0.01 0.02 1 force
particle wom:enderbullet_blast_hit ~ ~ ~ 0.01 0.01 0.01 0.02 1 force
summon silverfish ~ ~ ~ {NoAI:1b,Silent:1b,Invulnerable:1b,PersistenceRequired:1b,Tags:["piercing"]}
power grant @e[tag=piercing] nebuleus:invis
kill @e[tag=piercing]