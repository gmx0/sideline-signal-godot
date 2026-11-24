# Sideline Signal

A short, deterministic 2D turn-based volleyball match for one player. Read the
landing lane, choose your receiving formation, and return into open court.
The first side to five points wins. There is no timer.

Open `project.godot` in Godot 4.6.3 (Compatibility renderer), then press **F5**.
No add-ons or extra assets are needed. For exports, install matching official
Godot export templates. The Web ZIP needs HTTP: extract it, run
`python -m http.server 8000 --bind 127.0.0.1` in that folder, and open
`http://127.0.0.1:8000/` on a desktop browser.

| Key | Action |
| --- | --- |
| **S** | Spread. A float gives you all three return angles; a driven ball beats it. |
| **G** | Gather at the incoming lane. Dig either ball, but return only to that lane or the middle. |
| **1 / 2 / 3** | Return left, middle or right. Each button indicates open, guarded or out of reach. |
| **Space / Enter** | Start the next rally once the point is over. |
| **R** | Restart the match. |

These actions also have visible buttons. Sending the ball into the guard
keeps the rally alive with a counter. The third blocked return costs you the
point. Try gathering at left on the opening driven ball, then returning left
while the rivals guard right. On the next float, spread to keep both sidelines
available and return away from the middle guard.

Engine notices are in `GODOT_NOTICES.txt`. No third-party art, music, text
or game code is used. All court graphics are drawn in Godot.
