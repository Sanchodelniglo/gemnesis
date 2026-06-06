/*
 * {{NAME}} — Sega Mega Drive ROM scaffolded by gemnesis.
 *
 * Boots into a tiny lab scene: a portal, a monitor, a shelf of flasks,
 * a counter, a tiled floor — and a hero you can move with the D-pad.
 *
 * D-pad : move the hero (each step plays a short PSG blip)
 * A     : play a longer "portal" tone
 *
 * Each comment explains a Mega Drive / SGDK building block.
 */
#include <genesis.h>
#include "resources.h"

#define SPEED 2

/* PSG channels: 0–2 are square-wave tones, 3 is white noise.
 * Envelope: 0 = loudest, 15 = silent. We use 8 as a "comfortable" level. */
#define BLIP_CHANNEL    0
#define PORTAL_CHANNEL  2
#define LEVEL_LOUD      8
#define LEVEL_SILENT    15

/* Screen is 320x224 (NTSC). Center = (152, 104) for a 16x16 sprite. */
static s16 hero_x = 152;
static s16 hero_y = 104;
static Sprite *hero;

/* Sound bookkeeping: timers count down frames until we silence each channel. */
static u8 blip_timer   = 0;
static u8 portal_timer = 0;
static bool was_moving = FALSE;

static void handle_input(void)
{
    u16 joy = JOY_readJoypad(JOY_1);
    bool moving = (joy & (BUTTON_LEFT | BUTTON_RIGHT | BUTTON_UP | BUTTON_DOWN)) != 0;

    if (joy & BUTTON_LEFT)  hero_x -= SPEED;
    if (joy & BUTTON_RIGHT) hero_x += SPEED;
    if (joy & BUTTON_UP)    hero_y -= SPEED;
    if (joy & BUTTON_DOWN)  hero_y += SPEED;

    /* Movement blip: trigger only on the edge (frame movement *starts*),
     * not every frame — that would be a constant tone. */
    if (moving && !was_moving) {
        PSG_setFrequency(BLIP_CHANNEL, 127);    /* ~880 Hz (A5) on NTSC */
        PSG_setEnvelope(BLIP_CHANNEL, LEVEL_LOUD);
        blip_timer = 4;                          /* ~67 ms at 60 fps */
    }
    was_moving = moving;

    /* Button A: longer, lower "portal" tone (~440 Hz). */
    if (joy & BUTTON_A) {
        PSG_setFrequency(PORTAL_CHANNEL, 254);   /* ~440 Hz (A4) */
        PSG_setEnvelope(PORTAL_CHANNEL, LEVEL_LOUD);
        portal_timer = 20;                       /* ~333 ms */
    }
}

static void tick_sound(void)
{
    if (blip_timer   > 0 && --blip_timer   == 0) PSG_setEnvelope(BLIP_CHANNEL,   LEVEL_SILENT);
    if (portal_timer > 0 && --portal_timer == 0) PSG_setEnvelope(PORTAL_CHANNEL, LEVEL_SILENT);
}

int main(bool hardReset)
{
    /* Two palettes: PAL2 for the lab background, PAL1 for the hero sprite.
     * PAL0 stays the default font palette (used by VDP_drawText). */
    PAL_setPalette(PAL2, lab_bg.palette->data,       DMA);
    PAL_setPalette(PAL1, hero_sprite.palette->data,  DMA);

    /* Draw the lab BG on plane A. Its unique tiles get loaded into VRAM
     * starting at TILE_USER_INDEX (a constant SGDK reserves for us). */
    VDP_drawImageEx(BG_A, &lab_bg,
                    TILE_ATTR_FULL(PAL2, FALSE, FALSE, FALSE, TILE_USER_INDEX),
                    0, 0, FALSE, CPU);

    /* Render text on the OTHER plane (BG_B) so it sits on top without
     * trampling our background tiles. */
    VDP_setTextPlane(BG_B);
    VDP_drawText("GEMNESIS LAB", 14, 2);

    /* Sprite engine: initialize, then add our hero at center. */
    SPR_init();
    hero = SPR_addSprite(&hero_sprite, hero_x, hero_y,
                         TILE_ATTR(PAL1, 0, FALSE, FALSE));

    /* Silence all PSG channels at boot — chip state on reset is undefined.
     * SGDK envelope: 0 = loudest, 15 = silent (matches SN76489 hardware). */
    PSG_setEnvelope(0, LEVEL_SILENT);
    PSG_setEnvelope(1, LEVEL_SILENT);
    PSG_setEnvelope(2, LEVEL_SILENT);
    PSG_setEnvelope(3, LEVEL_SILENT);

    /* Main loop: read pad → move sprite → tick sound timers → push to VDP. */
    while (TRUE) {
        handle_input();
        tick_sound();
        SPR_setPosition(hero, hero_x, hero_y);
        SPR_update();
        SYS_doVBlankProcess();
    }
    return 0;
}
