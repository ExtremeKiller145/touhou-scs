

from touhou_scs import enums as enum, lib
from touhou_scs.component import Component
from touhou_scs.types import Trigger
from touhou_scs.utils import unknown_g


BOUNDARY_HITBOX = 1
PLR_HURTBOX = 2
PLR_GRAZE_HITBOX = 3
BOMB_HITBOX = 4
GRAZE_FUNCTION = 34
PLR_HIT_FUNCTION = 35
DESPAWN_FUNCTION = 27 #PLR_HIT calls despawn in level, BOMB_HIT calls directly in code
ENEMY_HITBOX = 5

ppt = enum.Properties

added_disable_all_bullets = False

def add_disable_all_bullets():
    global added_disable_all_bullets
    if added_disable_all_bullets: 
        raise RuntimeError("Disable All Bullets has already been added")
    
    comp = Component("Disable All Bullets", 32, editorLayer=7)
    comp.assert_spawn_order(False)

    def add_disable_triggers(bullet: lib.BulletPool):
        max, min = bullet.max_group, bullet.min_group
        for i in range(min, max + 1):
            comp.Toggle(0, i, True)
    
    add_disable_triggers(lib.bullet1)
    add_disable_triggers(lib.bullet2)
    add_disable_triggers(lib.bullet3)
    add_disable_triggers(lib.bullet4)
    
    added_disable_all_bullets = True


added_collisions = False

def add_collisions():
    global added_collisions
    if added_collisions: 
        raise RuntimeError("Collisions have already been added")
    
    cols = Component("Base Collisions (un-mapped)", 18, editorLayer=6)
    cols.assert_spawn_order(False)
    
    cols.Collision(0, enum.EMPTY_BULLET, 
        blockA=enum.EMPTY_BULLET, blockB=BOUNDARY_HITBOX, activateGroup=False, onExit=True)
    
    cols.Collision(0, GRAZE_FUNCTION, 
        blockA=enum.EMPTY_BULLET, blockB=PLR_GRAZE_HITBOX, activateGroup=True)
    
    cols.Collision(0, DESPAWN_FUNCTION, 
        blockA=enum.EMPTY_BULLET, blockB=BOMB_HITBOX, activateGroup=True)

    cols.Collision(0, enum.EMPTY_BULLET, 
        blockA=enum.EMPTY_BULLET, blockB=PLR_HURTBOX, activateGroup=True)
    
    def spawn(comp: Component, target: int, spawnOrdered: bool, *, remap: str):
        """Specialized spawn trigger without validation"""
        trig: Trigger = {
            ppt.OBJ_ID: enum.ObjectID.SPAWN,
            ppt.X: 0,
            ppt.TARGET: target,
            ppt.EDITOR_LAYER: 7,
            ppt.SPAWN_TRIGGERED: True,
            ppt.MULTI_TRIGGERED: True,
            ppt.GROUPS: [comp.groups[0]],
            ppt.REMAP_STRING: remap,
            ppt.SPAWN_ORDERED: spawnOrdered,  
        }
        comp.triggers.append(trig)
    
    global_col = Component("Bullet Collision remap wrapper", 17, editorLayer=4) \
        .assert_spawn_order(False)

    plr_hit_col = Component("Player Hit Collisions", unknown_g(), editorLayer=4) \
        .assert_spawn_order(False)
    
    def add_collision_trigger_remaps(bullet: lib.BulletPool):
        min, max = bullet.min_group, bullet.max_group
        
        for bullet_hitbox in range(min, max + 1):
            spawn(global_col, cols.groups[0], False, remap=f"{enum.EMPTY_BULLET}.{bullet_hitbox}")
            
            # Give each bullet a spawn trigger that activates its own collisions
            spawn(plr_hit_col, PLR_HIT_FUNCTION, False, remap=f"{enum.EMPTY_BULLET}.{bullet_hitbox}")
            plr_hit_col.group_last_trigger(bullet_hitbox)
    
    add_collision_trigger_remaps(lib.bullet1)
    add_collision_trigger_remaps(lib.bullet2)
    add_collision_trigger_remaps(lib.bullet3)
    add_collision_trigger_remaps(lib.bullet4)
    
    # enemy_col = Component("Enemy Player Collisions", unknown_g(), editorLayer=7) \
    #     .assert_spawn_order(False)
    
    # enemy_col.Collision(0, PLR_HIT_FUNCTION,
    #     blockA=ENEMY_HITBOX, blockB=PLR_HURTBOX, activateGroup=True)
    
    # plr_bullet_col = Component("Player's Bullet Collisions", unknown_g(), editorLayer=7)\
    #     .assert_spawn_order(False)
    
    # def add_plr_bullet_collision_remaps(bullet: lib.BulletPool):
    #     min, max = bullet.min_group, bullet.max_group
        
    #     for bullet_hitbox in range(min, max + 1):
    #         ...
    
    # add_plr_bullet_collision_remaps(lib.reimuA_level1)
    
    
    added_collisions = True

collision1 = (Component("Collision 1", unknown_g(), editorLayer=6)
    .assert_spawn_order(True)
    .Scale(0, enum.EMPTY_BULLET, 
        factor=0.25, hold=0, t=1, type=enum.Easing.ELASTIC_IN_OUT, rate=1)
    .Alpha(0, enum.EMPTY_BULLET, t=1, opacity=0)
    .Pulse(0, enum.EMPTY_BULLET, lib.rgb(0,0,0), t=1)
    .Alpha(1, enum.EMPTY_BULLET, t=0, opacity=100)
    .Toggle(1, enum.EMPTY_BULLET, False)
)

# collision2 = (Component("Collision 2", unknown_g(), editorLayer=6)
#     .assert_spawn_order(True)
#     .Scale(0, enum.EMPTY_BULLET, t=1, factor=0.25)
#     .Alpha(0, enum.EMPTY_BULLET, t=1, opacity=0)
#     .Scale(1, enum.EMPTY_BULLET, t=0, factor=0.25, divide=True)
#     .Alpha(1, enum.EMPTY_BULLET, t=0, opacity=100)
# )


despawn_function = Component("Despawn Function List", DESPAWN_FUNCTION, editorLayer=6)

(despawn_function
    .assert_spawn_order(False)
    # Note: if a collisionX component seems to be be spawning delayed, its a GD bug. reload level.
    .Spawn(0, collision1.groups[0], True) # toggle this on/off same tick w/ unique group
    # .Spawn(0, collision2.groups[0], True)
)
