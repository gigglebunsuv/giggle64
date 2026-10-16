Title music: put a file named title_theme.ogg (or title_theme.mp3 / title_theme.wav)
in this folder. It starts when the title screen appears after the splash screens,
plays once (no loop), and fades out when a file is chosen. If the title sits idle for
15 seconds after the theme ends, the boot sequence starts over from the splash screens.
Volume: MUSIC_DB in scripts/ui/title_screen.gd (wind under it: WIND_DB).

Area music: each area's track is set in scripts/systems/world_data.gd (AREAS "music",
file name without extension). bunsriel_field plays in Bunsriel Fields and on the South Road,
ladhellin_desert in the Desert of Ladhellin, mirror_lake at Mirror Lake, haven_village in Haven Village,
castle_town in Old Castle Town, the_forest in The Forest, hidden_forest in The Hidden Forest,
west_marshlands in the West Marshlands, southern_fields in the Southern Fields, northeastern_cliffs
on the Northeastern Cliffs and frostpeak on Frostpeak; inside_house plays in every
interior (INTERIOR_MUSIC) unless the interior names its own. Area tracks loop, fade out with
the screen when leaving for a different track, and carry on uninterrupted between areas that
share one. Volume: MUSIC_DB in scripts/systems/world.gd. Use lowercase file extensions.

Dungeon tracks: lake_shrine plays in the Lake Shrine, southern_tower in the Southern Tower,
ladhellin_tower, skyreach_spire and bog_tower in those towers, and boss_battle during the fight with
Carapax (it starts when the boss appears and stops when it is beaten). File names must match
exactly (no spaces); to replace a track, overwrite the file with the same name.

Mini-bosses (Beta 1.3.2): miniboss plays while a mini-boss fights (the knights, the wyverns,
the Mummy Lord, the Battle-Mage, Dark Gigglebuns...); without the file they use boss_battle.
When a mini-boss falls the dungeon's own track comes back; when a boss falls the room goes quiet.
The MIDI is _giggle64_work/music/miniboss.mid (make_miniboss_midi.py).

Night (alpha 1.5.0): out in the open there is no music after dark, only the ambience and
the crickets. The area track fades out at dusk and back in at dawn.

Cutscene score: lothelye_legend plays once (no loop) under Lothelye's legend, when the
Bun Sword is drawn. The scene is timed to it: every cue (marker names in the MIDI) is a
moment on screen, and while the file plays the scene follows its playback position. Keep a
rendering the same length and tempo as the MIDI (no extra silence at the start).
Cue times: scripts/systems/legend_score.gd, written by _giggle64_work/tools/make_lothelye_midi.py.

MIDI sources for these tracks (render them yourself): _giggle64_work/music/<track>.mid, made by
_giggle64_work/tools/make_<area>_midi.py (shared helpers in g64midi.py, check with check_midi.py).

Beta 1.1.0 (The Batela Fells): new track names, MIDI in _giggle64_work/music/<track>.mid
(make_<track>_midi.py):
  castle_town_fallen   (not used: the fallen town stays silent by choice, ambience only)
  goddess_spring       the Goddess Springs and Springs of Lothelye (was silent until now)
  frostpeak_hollow     Frostpeak Hollow (Chapter II dungeon)
  sun_trial            the Sun Trial (Chapter II trial)
  forest_of_the_dead   the Forest of the Dead
  batela_fells         the Batela Fells
  ashwick              Ashwick, the survivors' camp: a music zone inside the Fells; it
                       plays there day and night instead of batela_fells
  sapphire_sanctum     the Sapphire Sanctum
  ending               after the Chapter I defeat, under the captions and the short
                       credits roll (and OPTIONS > CREDITS); plays once, no loop
  credits              the full end credits for the end of Saga IV (not wired yet;
                       plays once, no loop)
firebuns_theme now plays in the duel with Firebuns III at Batela Keep.

Beta 1.5.0 (The Astral Rift), the last update. New track names, MIDI in
_giggle64_work/music/<track>.mid (make_<track>_midi.py). Until a file is rendered, a boss
theme falls back to boss_battle and the rest are silent.
  game_over          the GAME OVER screen; plays once, no loop (also under the post-credits
                     glimpse of the Fells)
  prologue           the opening prologue in the Cinder Vault; plays once, no loop
  astral_rift        the Astral Rift (A major on Avalon's motif, F# minor B section)
  velloran_battle    Archmagus Velloran's fight in the Sanctum Ruin (the Sanctum Ruin itself
                     plays sapphire_sanctum)
  true_final_battle  Firebuns III, the true final battle, phases 1 and 2
  final_hope         the third phase (Avalon's motif and the main motif together)
  ending_cutscene    Serielye ends it; plays once, no loop
  tavern             the Golden Bun, Castle Town's tavern (ct_08). After the true ending
                     the band plays age_of_enlightenment there instead.
Timed to existing renders (keep their length and tempo if you re-render them):
  avalon             Avalon's scene follows its sections (StoryFinal.AVALON_CUES)
  credits            the credits tour follows its sections (StoryEnding.CREDIT_CUES/CARDS)
Bar times of any generator: python _giggle64_work/tools/bar_times.py make_<track>_midi.py
