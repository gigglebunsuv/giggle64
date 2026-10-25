# Beta 1.9.0 — Fellowship

Online co-op. Up to six players can share one world over the internet or a home network. Each plays Sir Gigglebuns or one of five companions made playable: Pink, Aladriel, Idrith, Mira and Himeko. Every one has the hero's full arsenal. They fight the same creatures and share the same treasure, and PvP is there if you want it.

## Playing together
- **OPTIONS › ONLINE** on the pause screen:
  - **CHARACTER** picks who you play. It works offline too, any time.
  - **NAME** sets the name shown over your head.
  - **HOST GAME** opens your game to others, on port 24064.
  - **ADDRESS** and **JOIN GAME** connect to a friend's game: type their address, then join.
  - **PVP** turns player-versus-player on or off. Only the host can change it.
  - **LEAVE** ends the session.
- **Joining** takes you into the host's world: their progress, their items and the area they're in. Your own save file isn't touched, and nothing is saved on your side while you're online. Only the host's file keeps the game.
- **The party travels together.** When the host takes an exit, everyone follows. When you take one, the host takes everyone through, and the party arrives side by side.
- **Everything you find is shared:**
  - items, coins, arrows and bombs;
  - heart pieces, keys and maps;
  - gear and tunics, quest progress and story flags.
  Whoever picks something up, everyone has it.
- **Everyone fights the same creatures.** The host's game runs them. They chase whichever hero is nearest, and every hero's blows count. Creatures that appear as you go (waves, spawners) show up for everyone.
- **Parrying and riposting work in co-op**: a parried creature reels in everyone's game.
- **Each hero has their own hearts.** If you fall as a guest, you get straight back up at the area's entrance. Only the host gets a Game Over.
- **PvP:** heroes' swords, arrows and other attacks hit each other too, with impact frames and all.
- **On screen:** each hero's name floats over their head. The party and their hearts are listed at the right, and you're told when someone joins or leaves.
- From the command line: `--net-host`, `--net-join=<address>`, `--net-char=<hero>` and `--net-name=<name>`.

## The companions
- **Pink, Aladriel, Idrith, Mira and Himeko** keep their own looks. They move with every one of Sir Gigglebuns' animations, re-fitted to their build: cuts, rolls, the bow, the hookshot, swimming, climbing, riding, fidgets and all.
- **Their own gear.** Every sword and shield, from the Squire's Sword to the Questlord's Greatsword and from the Wooden Shield to the Questlord's starmetal, comes in each companion's style while keeping its colors:
  - **Pink:** a smith's heavy falchion and a riveted round buckler.
  - **Aladriel:** a Questlord's long blade with drooping quillons and a tall kite shield.
  - **Idrith:** a curved scimitar and a round targe with a crescent moon.
  - **Mira:** a slim rapier with a ring guard and her red ribbon on the pommel, and a small round shield with ripples like the lake.
  - **Himeko:** a curved blade with a round guard and a long wrapped grip, and an oval shield with a five-petal flower.
- **Their own tunics.** The Tide Tunic, Frost Mantle and Shade Cloak recolor each companion's own outfit, and so do the Knight's Regalia and Knight's Tabard.

## Notes
- The host's game is the authority. If the host leaves, everyone else carries on alone, offline.
- Hosting over the internet needs port 24064 (UDP) forwarded to the host.
- Cutscenes and conversations play for whoever starts them.
