/*
 * {{NAME}} — Sega Mega Drive ROM scaffolded by gemnesis.
 *
 * Shows the word "GEMNESIS" and a hero sprite you can move with the D-pad.
 * Read each comment to learn the SGDK building blocks.
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
    /* Apply the sprite's bundled palette to PAL1 (PAL0 stays for text). */
    PAL_setPalette(PAL1, hero_sprite.palette->data, DMA);

    /* Print a label on the BG plane using the default font (PAL0). */
    VDP_drawText("GEMNESIS", 16, 2);

    /* Sprite engine: init, then add our hero on palette 1, tile 0. */
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
