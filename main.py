from touhou_scs import enums as e
from touhou_scs import lib
from touhou_scs.component import Component
from touhou_scs.lib import rgb, save_all, HSB
from touhou_scs.misc import add_disable_all_bullets, add_collisions
from touhou_scs.utils import group, unknown_g

if __name__ != "__main__":
    print("Don't import this! exiting.")
    exit()
    
c1 = lib.circle1

# First bullet component - fades in, points to target, moves with pulse
testRadialComp = Component("TestRadial", unknown_g(), 4)
emitter = 30
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
emitter2 = 200
test2 = Component("TestRadial2", unknown_g(), 4)
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

# Main caller component that creates the patterns
callerComponent = Component("CallerComponent", group(36), 4)
(callerComponent
    .assert_spawn_order(True)
    .GotoGroup(0, c1.all, emitter, t=0)
    .MoveBy(0.2, emitter, dx=-150, dy=30, t=10, type=e.Easing.EASE_IN, rate=1.5)
    .MoveBy(0.2, c1.all, dx=-150, dy=30, t=10, type=e.Easing.EASE_IN, rate=1.5)
)

# Create arc patterns with first bullet type
(callerComponent
    .instant.Arc(0, testRadialComp, c1, lib.bullet1,
        numBullets=127, spacing=1, centerAt=0)
    .instant.Arc(2, testRadialComp, c1, lib.bullet2,
        numBullets=10, spacing=14, centerAt=0)
)

test_line = (Component("TestLine", unknown_g(), 4)
    .assert_spawn_order(True)
    .GotoGroup(0, e.EMPTY_BULLET, emitter2)
    .Scale(0, e.EMPTY_BULLET, factor=3, t=1.5, reverse=True)
    .Pulse(0, e.EMPTY_BULLET, rgb(200,100,0), t=10)
    .Alpha(0, e.EMPTY_BULLET, t=0, opacity=0)
    .Toggle(e.TICK, e.EMPTY_BULLET, True)
    .PointToGroup(e.TICK, e.EMPTY_BULLET, e.PLR)
    .Alpha(e.TICK, e.EMPTY_BULLET, t=0.5, opacity=100)
)

# Create radial pattern with second bullet type
(callerComponent
    .GotoGroup(0.9, c1.all, emitter2, t=0)
    .MoveBy(0.8, emitter2, dx=80, dy=-20, t=8, type=e.Easing.BOUNCE_IN_OUT, rate=1)
    .instant.Radial(1, test2, c1, lib.bullet4,
        numBullets=18, centerAt=0)
    .timed.RadialWave(3, test2, c1, lib.bullet3,
        numBullets=24, waves=10, interval=0.3, centerAt=10)
    .instant.Line(1, test_line, e.PLR, lib.bullet1,
        numBullets=15, fastestTime=1, slowestTime=4, dist=400)
    .instant.Line(2, test_line, e.PLR, lib.bullet1,
        numBullets=15, fastestTime=1, slowestTime=4, dist=400)
    .instant.Line(3, test_line, e.PLR, lib.bullet1,
        numBullets=15, fastestTime=1, slowestTime=4, dist=400)
)


add_disable_all_bullets()
add_collisions()
save_all()
