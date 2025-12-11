
from touhou_scs import enums as enum, lib, utils as util
from touhou_scs.component import Component, Multitarget
from touhou_scs.utils import unknown_g, calltracker

# Hitbox is the weapon, hurtbox is the target
BOUNDARY_HITBOX = 1
PLR_HURTBOX = 2
PLR_GRAZE_HURTBOX = 3
BOMB_HITBOX = 4
GRAZE_FUNCTION = 34
PLR_HURT_FUNCTION = 35
DESPAWN_FUNCTION = 27 #PLR_HURT calls despawn in level, BOMB_HURT calls directly in code
ENEMY_HITBOX = 5 # shared for every enemy

ppt = enum.Properties

@calltracker
def add_disable_all_bullets():
    if add_disable_all_bullets.has_been_called:
        raise RuntimeError("Disable All Bullets has already been added")

    comp = Component("Disable All Bullets", 32, editorLayer=4) \
        .assert_spawn_order(False)

    single = (Component("Disable Single Bullet", unknown_g(), editorLayer=6)
        .assert_spawn_order(False)
        .set_context(target=enum.EMPTY_BULLET)
            .Toggle(0, False)
        .clear_context()
    )

    bullet_groups = (
        list(range(lib.bullet1.min_group, lib.bullet1.max_group + 1)) +
        list(range(lib.bullet2.min_group, lib.bullet2.max_group + 1)) +
        list(range(lib.bullet3.min_group, lib.bullet3.max_group + 1)) +
        list(range(lib.bullet4.min_group, lib.bullet4.max_group + 1)) +
        list(range(lib.pointer.min_group, lib.pointer.max_group + 1))
    )

    bullet_iter = iter(bullet_groups)
    remaining = len(bullet_groups)

    # Chunk into max-64 batches and handle remainder normally
    while remaining > 0:
        batch_size = 64 if remaining > 127 else remaining

        def remap_disable(remap_pairs: dict[int, int], remap: util.Remap):
            for source, target in remap_pairs.items():
                if source == enum.EMPTY_BULLET:
                    remap.pair(target, next(bullet_iter))
                else:
                    remap.pair(target, enum.EMPTY_MULTITARGET)

        Multitarget.spawn_with_remap(comp, 0, batch_size, single, remap_disable)
        remaining -= batch_size


@calltracker
def add_plr_collisions():
    if add_plr_collisions.has_been_called:
        raise RuntimeError("Collisions have already been added")

    cols = (Component("Base Enemy's Bullet Collisions (un-mapped)", 18, editorLayer=6)
        .assert_spawn_order(False)
        .set_context(target=enum.EMPTY_BULLET)
            .Collision(0, blockA=enum.EMPTY_BULLET, blockB=BOUNDARY_HITBOX, activateGroup=False, onExit=True)
        .clear_context()
        .set_context(target=GRAZE_FUNCTION)
            .Collision(0, blockA=enum.EMPTY_BULLET, blockB=PLR_GRAZE_HURTBOX, activateGroup=True)
        .clear_context()
        .set_context(target=DESPAWN_FUNCTION)
            .Collision(0, blockA=enum.EMPTY_BULLET, blockB=BOMB_HITBOX, activateGroup=True)
        .clear_context()
        .set_context(target=enum.EMPTY_BULLET)
            .Collision(0, blockA=enum.EMPTY_BULLET, blockB=PLR_HURTBOX, activateGroup=True)
        .clear_context()
    )

    placeholder = unknown_g() # never called, just fulfills comp param requirement
    def add_collision_trigger_remaps(bullet: lib.BulletPool, name: str):
        # Called on level startup
        global_col = Component(f"[{name}]: Bullet Collision remap wrappers", 17, editorLayer=4) \
            .assert_spawn_order(False)
        # Each trigger in here is called individually, grouped for convenience/logging
        plr_hit_col = Component(f"[{name}]: PlrHit Collisions", placeholder, editorLayer=4) \
            .assert_spawn_order(False)

        for bullet_hitbox in range(bullet.min_group, bullet.max_group+ 1):
            # permanently turns on all collisions for each bullet (level calls it on startup)
            global_col.Spawn(0, cols.caller, False, remap=f"{enum.EMPTY_BULLET}.{bullet_hitbox}")
            # Give each bullet a spawn trigger that activates its own collisions
            with plr_hit_col.temp_context(groups=bullet_hitbox):
                plr_hit_col.Spawn(0, PLR_HURT_FUNCTION, False, remap=f"{enum.EMPTY_BULLET}.{bullet_hitbox}")

    add_collision_trigger_remaps(lib.bullet1, "B1")
    add_collision_trigger_remaps(lib.bullet2, "B2")
    add_collision_trigger_remaps(lib.bullet3, "B3")
    add_collision_trigger_remaps(lib.bullet4, "B4")

    (Component("Enemy-dmg-Player Collisions", 17, editorLayer=7)
        .assert_spawn_order(False)
        # WARNING: its using empties without remaps
        # (since not remapping PLR_HIT_FUNCTION and therefore not remapping DESPAWN_FUNCTION)
        .set_context(target=PLR_HURT_FUNCTION)
            .Collision(0, blockA=ENEMY_HITBOX, blockB=PLR_HURTBOX, activateGroup=True)
        .clear_context()
        .set_context(target=GRAZE_FUNCTION)
            .Collision(0, blockA=ENEMY_HITBOX, blockB=PLR_GRAZE_HURTBOX, activateGroup=True)
        .clear_context()
    )


@calltracker
def add_enemy_collisions():
    """Does not include enemy damaging the player"""
    if add_enemy_collisions.has_been_called:
        raise RuntimeError("Enemy collision has already been added")

    def add(enemies: list[int], bullet: lib.BulletPool, enemyName: str, bulletName: str):
        base_col = (Component(f"{enemyName} Collision for {bulletName} (un-mapped)", unknown_g(), editorLayer=6)
            .assert_spawn_order(False)
            .set_context(target=plr_bullet_despawn.caller)
                .Collision(0, blockA=enum.EMPTY_BULLET, blockB=enum.EMPTY_TARGET_GROUP, activateGroup=True)
            .clear_context()
        )

        global_col = Component(f"{enemyName} Collision remap wrappers for {bulletName}", 17, editorLayer=4) \
            .assert_spawn_order(False)

        for enemy in enemies:
            for b in range(bullet.min_group, bullet.max_group + 1):
                global_col.Spawn(0, base_col.caller, False,
                    remap=f"{enum.EMPTY_BULLET}.{b}.{enum.EMPTY_TARGET_GROUP}.{enemy}")

    add(list(range(200, 210+1)), lib.reimuA_level1, "PlaceholderEnemies", "ReimuA_L1")

despawn1 = (Component("PlrBullet Despawn 1", unknown_g(), editorLayer=6)
    .assert_spawn_order(True)
    .set_context(target=enum.EMPTY_BULLET)
        .Scale(0, factor=0.25, hold=0, t=1, type=enum.Easing.ELASTIC_IN_OUT, rate=1.2)
        .Alpha(0, t=1, opacity=0)
        .Pulse(0, lib.rgb(0,0,0), t=1)
        .Alpha(1, t=0, opacity=100)
        .Toggle(1, False)
    .clear_context()
)


despawn2 = (Component("EnemyBullet Despawn 2", unknown_g(), editorLayer=6)
    .assert_spawn_order(True)
    # Bullet despawn
    .set_context(target=enum.EMPTY_BULLET)
        .Scale(0, factor=0.25, hold=0, t=0.1, type=enum.Easing.ELASTIC_IN_OUT, rate=1.5)
        .Alpha(0, t=0.1, opacity=0)
        .Pulse(0, lib.rgb(0,50,255), t=0.2, exclusive=True)
        .Alpha(0.2, t=0, opacity=100)
        .Toggle(0.2, False)
    .clear_context()
)

plr_bullet_despawn = (Component("PlrBullet Despawn List", unknown_g(), editorLayer=6)
    .assert_spawn_order(False)
    # To decrease enemy health & despawn the player bullet
    .Pickup(0, item_id=enum.EMPTY_TARGET_GROUP, count=-1, override=False)
    .set_context(target=enum.EMPTY_TARGET_GROUP)
        .Pulse(0, lib.HSB(50, 0.52, 0.56), fadeIn=0.1, fadeOut=0.1, exclusive=True)
    .clear_context()
    .Spawn(0, despawn2.caller, True) # toggle this on/off same tick w/ unique group
)


enemy_bullet_despawn = Component("EnemyBullet Despawn List", DESPAWN_FUNCTION, editorLayer=6)

(enemy_bullet_despawn
    .assert_spawn_order(False)
    # Note: if a collisionX component seems to be be spawning delayed, its a GD bug. reload level.
    .Spawn(0, despawn1.caller, True) # toggle this on/off same tick w/ unique group
    # .group_last_trigger
    # .Spawn(0, collision2.caller, True)
)
