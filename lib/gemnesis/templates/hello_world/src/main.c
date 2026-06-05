/*
 * {{NAME}} — Sega Mega Drive ROM scaffolded by gemnesis.
 *
 * Boots into a tiny lab scene: a portal, a monitor, a shelf of flasks,
 * a counter, a tiled floor — and a hero you can move with the D-pad.
 * Every comment explains a Mega Drive / SGDK building block.
 */
#include <genesis.h>
#include "resources.h"

#define SPEED 2

/* Screen is 320x224 (NTSC). Center = (152, 104) for a 16x16 sprite. */
static s16 hero_x = 152;
static s16 hero_y = 104;
static Sprite *hero;

static void handle_input(void)
{
    u16 joy = JOY_readJoypad(JOY_1);
    if (joy & BUTTON_LEFT)  hero_x -= SPEED;
    if (joy & BUTTON_RIGHT) hero_x += SPEED;
    if (joy & BUTTON_UP)    hero_y -= SPEED;
    if (joy & BUTTON_DOWN)  hero_y += SPEED;
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

    /* Main loop: read pad, move sprite, push to VDP, wait for VBlank. */
    while (TRUE) {
        handle_input();
        SPR_setPosition(hero, hero_x, hero_y);
        SPR_update();
        SYS_doVBlankProcess();
    }
    return 0;
}
