from touhou_scs import enums as e
from touhou_scs import lib
from touhou_scs.component import Component
from touhou_scs.lib import rgb, save_all, HSB
from touhou_scs.misc import add_disable_all_bullets, add_enemy_collisions, add_plr_collisions
from touhou_scs.utils import group, unknown_g

if __name__ != "__main__":
    print("Don't import this! exiting.")
    exit()

c1 = lib.circle1
emitter = 30
emitter2 = 200

# First bullet component - fades in, points to target, moves with pulse
testRadialComp = Component("TestRadial", unknown_g(), 5)
(testRadialComp
    .assert_spawn_order(True)
    .GotoGroup(0, e.EMPTY_BULLET, emitter, t=0)
    .Toggle(e.TICK, e.EMPTY_BULLET, True)
    .Alpha(0, e.EMPTY_BULLET, t=0, opacity=0)
    .Alpha(e.TICK, e.EMPTY_BULLET, t=1, opacity=100)
    .Scale(0, e.EMPTY_BULLET, factor=2, t=0.5, reverse=True)
    .PointToGroup(e.TICK, e.EMPTY_BULLET, e.EMPTY_TARGET_GROUP)
    .PointToGroup(0.3, e.EMPTY_BULLET, e.EMPTY_TARGET_GROUP)
    .MoveTowards(0.3, e.EMPTY_BULLET, e.EMPTY_TARGET_GROUP,
        t=1.8, type=e.Easing.EASE_IN_OUT, rate=2.01, dist=70)
    .Pulse(2.1, e.EMPTY_BULLET,
        HSB(54, 124, 156), fadeIn=0.1, t=0.1, fadeOut=0.3)
    .MoveTowards(2.1, e.EMPTY_BULLET, e.EMPTY_TARGET_GROUP,
        t=5, type=e.Easing.EASE_IN, rate=2.01, dist=500)
)

# Second bullet component - larger scale, different colors, tracks player
test2 = Component("TestRadial2", unknown_g(), 5)
(test2
    .assert_spawn_order(True)
    .GotoGroup(0, e.EMPTY_BULLET, emitter2, t=0)
    .Scale(0, e.EMPTY_BULLET, factor=4, t=0.3, hold=0, reverse=True)
    .Toggle(e.TICK, e.EMPTY_BULLET, True)
    .Alpha(0, e.EMPTY_BULLET, t=0, opacity=0)
    .Alpha(e.TICK, e.EMPTY_BULLET, t=1, opacity=100)
    .PointToGroup(e.TICK, e.EMPTY_BULLET, e.EMPTY_TARGET_GROUP)
    .PointToGroup(0.3, e.EMPTY_BULLET, e.EMPTY_TARGET_GROUP)
    .MoveTowards(0.3, e.EMPTY_BULLET, e.EMPTY_TARGET_GROUP,
        t=1.8, type=e.Easing.EASE_IN_OUT, rate=2.01, dist=70)
    .Pulse(0, e.EMPTY_BULLET,
        rgb(0,0,255), fadeIn=0, t=10, fadeOut=0)
    .Pulse(2.1, e.EMPTY_BULLET,
        HSB(64, 24, 156), fadeIn=0.1, t=0.1, fadeOut=0.4)
    .MoveTowards(2.5, e.EMPTY_BULLET, e.PLR,
        t=6, type=e.Easing.EASE_IN, rate=2.01, dist=400)
    .PointToGroup(2.4, e.EMPTY_BULLET, e.PLR, t=0.3)
)

test_line = (Component("TestLine", unknown_g(), 5)
    .assert_spawn_order(True)
    .GotoGroup(0, e.EMPTY_BULLET, emitter2)
    .Scale(0, e.EMPTY_BULLET, factor=3, t=1.5, reverse=True)
    .Pulse(0, e.EMPTY_BULLET, rgb(200,100,0), t=10)
    .Alpha(0, e.EMPTY_BULLET, t=0, opacity=0)
    .Toggle(e.TICK, e.EMPTY_BULLET, True)
    .PointToGroup(e.TICK, e.EMPTY_BULLET, e.PLR)
    .Alpha(e.TICK, e.EMPTY_BULLET, t=0.5, opacity=100)
)

# Main caller component that creates the patterns
main = Component("CallerComponent", group(36), 5)
(main
    .assert_spawn_order(True)
    .GotoGroup(0, c1.all, emitter, t=0)
    .MoveBy(0.2, emitter, dx=-150, dy=30, t=10, type=e.Easing.EASE_IN, rate=1.5)
    .MoveBy(0.2, c1.all, dx=-150, dy=30, t=10, type=e.Easing.EASE_IN, rate=1.5)
)

# [IMPORTANT] !!! Test why this causes gaps in enemy1 patterns
# (main
#     .instant.Arc(0, testRadialComp, c1, lib.bullet1,
#         numBullets=127, spacing=1, centerAt=0)
#     .instant.Arc(2, testRadialComp, c1, lib.bullet2,
#         numBullets=10, spacing=14, centerAt=0)
# )

emitter3 = 201
emitter4 = 202

enemy1 = (Component("Enemy1", unknown_g(), 5)
    .assert_spawn_order(True)
    .GotoGroup(0.9, c1.all, emitter2, t=0)
    .MoveBy(0.8, emitter2, dx=80, dy=-20, t=8, type=e.Easing.BOUNCE_IN_OUT, rate=1)
    .instant.Radial(1, test2, c1, lib.bullet4,
        numBullets=18, centerAt=0)
    .timed.RadialWave(3, test2, c1, lib.bullet3,
        numBullets=24, waves=10, interval=0.3, centerAt=10)
    .instant.Line(1, test_line, e.PLR, lib.bullet1,
        numBullets=15, fastestTime=1, slowestTime=4, dist=400)
    .instant.Line(3, test_line, e.PLR, lib.bullet1,
        numBullets=15, fastestTime=1, slowestTime=4, dist=400)
    .instant.Line(5, test_line, e.PLR, lib.bullet1,
        numBullets=15, fastestTime=1, slowestTime=4, dist=400)
)

enemy2 = (Component("Enemy2", unknown_g(), 5)
    .assert_spawn_order(True)
    .GotoGroup(0.9, c1.all, emitter3, t=0)
    .MoveBy(0.8, emitter3, dx=-80, dy=40, t=6, type=e.Easing.EASE_OUT, rate=1.2)
    .instant.Arc(1, testRadialComp, c1, lib.bullet2,
        numBullets=32, spacing=2, centerAt=0)
    .timed.RadialWave(2, testRadialComp, c1, lib.bullet1,
        numBullets=15, waves=8, interval=0.4, centerAt=5)
    .instant.Radial(4, test2, c1, lib.bullet3,
        numBullets=24, centerAt=0)
)

enemy3 = (Component("Enemy3", unknown_g(), 5)
    .assert_spawn_order(True)
    .GotoGroup(0.9, c1.all, emitter4, t=0)
    .MoveBy(0.8, emitter4, dx=0, dy=60, t=5, type=e.Easing.NONE, rate=1)
    .instant.Line(1, test_line, e.PLR, lib.bullet4,
        numBullets=20, fastestTime=0.8, slowestTime=3, dist=350)
    .instant.Radial(2.5, test2, c1, lib.bullet2,
        numBullets=12, centerAt=0)
    .instant.Line(4, test_line, e.PLR, lib.bullet1,
        numBullets=25, fastestTime=1.2, slowestTime=5, dist=450)
)

# less annoying way instead of making 'despawner' have spawn order
toggler = (Component("Toggler", unknown_g(), 7)
    .assert_spawn_order(False)
    .Toggle(0, e.EMPTY_TARGET_GROUP, False)
)

despawner = (Component("Despawner", unknown_g(), 7)
    .assert_spawn_order(False)
    .Alpha(0, e.EMPTY_TARGET_GROUP, t=1, opacity=0)
    .Pulse(0, e.EMPTY_TARGET_GROUP, HSB(0, 0, -20), fadeIn=0.1, t=0.3, fadeOut=0.6, exclusive=True)
    .Scale(0, e.EMPTY_TARGET_GROUP, factor=0.1, t=0.5, hold=3)
    .Stop(0, e.EMPTY1)
    .Spawn(0, toggler, False, delay=1)
)

despawnSetup = (Component("Despawn Setup", unknown_g(), 7)
    .assert_spawn_order(False)
    # .Pickup(0, item_id=e.EMPTY_TARGET_GROUP, count=30, override=True)
    .Count(0, despawner.groups[0], item_id=e.EMPTY_TARGET_GROUP, count=0, activateGroup=True)
)

def spawn_enemy(time: float, enemy_component: Component, enemy_emitter: int, hp: int):
    enemyOff = unknown_g()
    (main
        .Spawn(time, enemy_component.groups[0], True)
        .group_last_trigger(enemyOff)
        .Spawn(time, despawnSetup.groups[0], False, 
            remap=f"{e.EMPTY_TARGET_GROUP}.{enemy_emitter}.{e.EMPTY1}.{enemyOff}")
        .Pickup(time - e.TICK*2, item_id=enemy_emitter, count=hp, override=True)
    )

# Spawn enemies at different times
spawn_enemy(0.5, enemy1, emitter2, 30)
spawn_enemy(6.0, enemy2, emitter3, 20)
spawn_enemy(8.5, enemy3, emitter4, 24)

add_enemy_collisions()
add_disable_all_bullets()
add_plr_collisions()
save_all()
