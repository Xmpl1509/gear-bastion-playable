# Gear Bastion — Godot playable ad demo

Demo inspired by the gear-placement defense loop of Gear Defenders, with original procedural graphics. Godot 4.7, portrait 540 × 960, mouse and touch input, no external assets or plugins.

## Play

Open `project.godot` in Godot and press F6 on `main.tscn`, or F5.
Drag gold gears into the board. Only gears connected to the yellow MOTOR turn and power a cannon. Connect both cannons, then press **BẮT ĐẦU PHÒNG THỦ**. Gears remain movable during combat. Defend against 30 enemies, including the final boss, and replay from the end card.

Working layout: (270,654), (270,594), (210,594), (150,594), (330,594), (390,594). One spare gear is available.

## Web export

Install the export templates matching your Godot version via Editor → Manage Export Templates. Create `build/web`, then use Project → Export → Web. Serve the resulting folder over HTTP; opening the HTML as a local file does not work reliably.

CLI: `godot --headless --path . --export-release Web build/web/index.html`

The Web preset uses Compatibility rendering without threads. A persistent **CHƠI NGAY** button and the animated end-card CTA open `https://www.youtube.com/watch?v=dQw4w9WgXcQ` on a user tap. The end card also offers a separate replay button. Change `CTA_URL` in `main.gd` to update the destination. This project is not yet an ad-network upload package: MRAID integration and network-specific size packaging depend on the target ad network.

## Verification

`godot --headless --path . --script res://tests/smoke.gd`

Checks real drag/drop placement, both powered cannons, a full winning battle, loss without power and replay reset.
