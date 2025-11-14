

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
DESPAWN_FUNCTION = 27

ppt = enum.Properties

added_disable_all_bullets = False

def add_disable_all_bullets():
    global added_disable_all_bullets
    if added_disable_all_bullets: 
        raise RuntimeError("Disable All Bullets has already been added")
    
    comp = Component("Disable All Bullets", 32, editorLayer=6)
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
    
    cols = Component("Collisions", 18, editorLayer=7)
    
    def collision(*, comp: Component, target: int, blockA: int, blockB: int, activateGroup: bool):
        
        col = comp.create_trigger(enum.ObjectID.COLLISION, 0, target)
        col[ppt.BLOCK_A] = blockA
        col[ppt.BLOCK_B] = blockB
        col[ppt.ACTIVATE_GROUP] = activateGroup
        cols.triggers.append(col)
        
    collision(
        comp=cols,
        target=enum.EMPTY_BULLET,
        blockA=enum.EMPTY_BULLET,
        blockB=BOUNDARY_HITBOX,
        activateGroup=False
    )
    
    collision(
        comp=cols,
        target=GRAZE_FUNCTION,
        blockA=enum.EMPTY_BULLET,
        blockB=PLR_GRAZE_HITBOX,
        activateGroup=True
    )
    
    collision(
        comp=cols,
        target=DESPAWN_FUNCTION,
        blockA=enum.EMPTY_BULLET,
        blockB=BOMB_HITBOX,
        activateGroup=True
    )
    
    collision(
        comp=cols,
        target=enum.EMPTY_BULLET,
        blockA=enum.EMPTY_BULLET,
        blockB=PLR_HURTBOX,
        activateGroup=True
    )
    
    def spawn(comp: Component, target: int, spawnOrdered: bool, *, remap: str):
        """Specialized spawn trigger without validation"""
        trig: Trigger = {}
        trig[ppt.OBJ_ID] = enum.ObjectID.SPAWN
        trig[ppt.X] = 0
        trig[ppt.TARGET]= target
        trig[ppt.EDITOR_LAYER] = 7
        trig[ppt.SPAWN_TRIGGERED] = True
        trig[ppt.MULTI_TRIGGERED] = True
        trig[ppt.GROUPS] = comp.callerGroup
        trig[ppt.REMAP_STRING] = remap
        trig[ppt.SPAWN_ORDERED] = spawnOrdered
        comp.triggers.append(trig)
    
    global_col = Component("Bullet Collision remap wrapper", 17, editorLayer=7) \
        .assert_spawn_order(False)
    
    def add_collision_triggers(bullet: lib.BulletPool):
        min, max = bullet.min_group, bullet.max_group
        
        for bullet_hitbox in range(min, max + 1):
            
            spawn(global_col, cols.callerGroup, False, remap=f"{enum.EMPTY_BULLET}.{bullet_hitbox}")
            
            plr_hit_col = Component(f"Player Hit Collision {bullet_hitbox}", bullet_hitbox, editorLayer=7) \
                .assert_spawn_order(False)
            spawn(plr_hit_col, PLR_HIT_FUNCTION, False, remap=f"{enum.EMPTY_BULLET}.{bullet_hitbox}")
    
    
    add_collision_triggers(lib.bullet1)
    add_collision_triggers(lib.bullet2)
    add_collision_triggers(lib.bullet3)
    add_collision_triggers(lib.bullet4)
    
    added_collisions = True

collision1 = (Component("Collision 1", unknown_g(), editorLayer=6)
    .assert_spawn_order(True)
    .Scale(0, enum.EMPTY_BULLET, t=1, factor=0.25)
    .Alpha(0, enum.EMPTY_BULLET, t=1, opacity=0)
    .Pulse(0, enum.EMPTY_BULLET, lib.rgb(0,0,0), t=1)
    .Scale(1, enum.EMPTY_BULLET, t=0, factor=0.25, divide=True)
    .Alpha(1, enum.EMPTY_BULLET, t=0, opacity=100)
    .Pulse(1, enum.EMPTY_BULLET, lib.HSB(100,0,0), t=1)
    # .Toggle(1, enum.EMPTY_BULLET, False)
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
    .Spawn(0, collision1.callerGroup, True) # toggle this on/off same tick w/ unique group
    # .Spawn(0, collision2.callerGroup, True)
)
