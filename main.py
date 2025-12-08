from touhou_scs import enums as e
from touhou_scs import lib
from touhou_scs.component import Component
from touhou_scs.lib import Stage, enemy1, rgb, save_all, HSB
from touhou_scs.misc import add_disable_all_bullets, add_enemy_collisions, add_plr_collisions
from touhou_scs.utils import unknown_g

if __name__ != "__main__":
    print("Don't import this! exiting.")
    exit()

c1 = lib.circle1
emitter = 30
enemy1g = 200
enemy2 = 201
enemy3 = 202

# First bullet component - fades in, points to target, moves with pulse
testRadialComp = Component("TestRadial", unknown_g(), 5)
(testRadialComp
    .assert_spawn_order(True)
    .GotoGroup(0, e.EMPTY_BULLET, e.EMPTY_EMITTER, t=0)
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
    .GotoGroup(0, e.EMPTY_BULLET, e.EMPTY_EMITTER, t=0)
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
    .GotoGroup(0, e.EMPTY_BULLET, e.EMPTY_EMITTER)
    .Scale(0, e.EMPTY_BULLET, factor=3, t=1.5, reverse=True)
    .Pulse(0, e.EMPTY_BULLET, rgb(200,100,0), t=10)
    .Alpha(0, e.EMPTY_BULLET, t=0, opacity=0)
    .Toggle(e.TICK, e.EMPTY_BULLET, True)
    .PointToGroup(e.TICK, e.EMPTY_BULLET, e.PLR)
    .Alpha(e.TICK, e.EMPTY_BULLET, t=0.5, opacity=100)
)

# Main caller component that creates the patterns
# main = Component("CallerComponent", group(36), 5)
# (main
#     .assert_spawn_order(True)
#     .GotoGroup(0, c1.all, emitter, t=0)
#     .Spawn(0, Stage.stage1, True)
#     .MoveBy(0.2, emitter, dx=-150, dy=30, t=10, type=e.Easing.EASE_IN, rate=1.5)
#     .MoveBy(0.2, c1.all, dx=-150, dy=30, t=10, type=e.Easing.EASE_IN, rate=1.5)
# )


enemy1attack = (Component("Enemy1", unknown_g(), 5)
    .assert_spawn_order(True)
    .GotoGroup(0.9, c1.all, enemy1g, t=0)
    .MoveBy(0.8, enemy1g, dx=80, dy=-20, t=8, type=e.Easing.BOUNCE_IN_OUT, rate=1)
    .instant.Radial(1, test2, c1, lib.bullet4,
        numBullets=18, centerAt=0)
    .timed.RadialWave(3, test2, c1, lib.bullet3,
        numBullets=24, waves=10, interval=0.3, centerAt=10)
    .instant.Line(1, test_line, enemy1g, e.PLR, lib.bullet1,
        numBullets=15, fastestTime=1, slowestTime=4, dist=400)
    .instant.Line(3, test_line, enemy1g, e.PLR, lib.bullet1,
        numBullets=15, fastestTime=1, slowestTime=4, dist=400)
    .instant.Line(5, test_line, enemy1g, e.PLR, lib.bullet1,
        numBullets=15, fastestTime=1, slowestTime=4, dist=400)
)

# enemy2attack = (Component("Enemy2", unknown_g(), 5)
#     .assert_spawn_order(True)
#     .GotoGroup(0.9, c1.all, e.EMPTY_TARGET_GROUP, t=0)
#     .MoveBy(0.8, e.EMPTY_TARGET_GROUP, dx=-80, dy=40, t=6, type=e.Easing.EASE_OUT, rate=1.2)
#     .instant.Arc(1, testRadialComp, c1, lib.bullet2,
#         numBullets=32, spacing=2, centerAt=0)
#     .timed.RadialWave(2, testRadialComp, c1, lib.bullet1,
#         numBullets=15, waves=8, interval=0.4, centerAt=5)
#     .instant.Radial(4, test2, c1, lib.bullet3,
#         numBullets=24, centerAt=0)
# )

# enemy3attack = (Component("Enemy3", unknown_g(), 5)
#     .assert_spawn_order(True)
#     .GotoGroup(0.9, c1.all, e.EMPTY_TARGET_GROUP, t=0)
#     .MoveBy(0.8, e.EMPTY_TARGET_GROUP, dx=0, dy=60, t=5, type=e.Easing.NONE, rate=1)
#     .instant.Line(1, test_line, e.PLR, lib.bullet4,
#         numBullets=20, fastestTime=0.8, slowestTime=3, dist=350)
#     .instant.Radial(2.5, test2, c1, lib.bullet2,
#         numBullets=12, centerAt=0)
#     .instant.Line(4, test_line, e.PLR, lib.bullet1,
#         numBullets=25, fastestTime=1.2, slowestTime=5, dist=450)
# )

enemy1.spawn_enemy(Stage.stage1, 0.5, enemy1attack, 20)
# enemy1.spawn_enemy(Stage.stage1, 6, enemy2attack, 20)
# enemy1.spawn_enemy(Stage.stage1, 9, enemy3attack, 24)

add_enemy_collisions()
add_disable_all_bullets()
add_plr_collisions()
save_all()
