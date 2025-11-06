import touhou_scs.enums as e

from touhou_scs.component import Component
from touhou_scs.lib import rgb, save_all
from touhou_scs.utils import group, unknown_g

# Test all component trigger methods
testComp = Component("ComprehensiveTest", unknown_g())
testComp.assert_spawn_order(True)

# Basic triggers
testComp.Spawn(0.05, 501, True, remap=f"{unknown_g()}.502", delay=0.5)
testComp.Toggle(0.1, 503, True)

# Movement triggers
testComp.MoveTowards(0.15, 501, e.PLR, t=2.0, dist=300, type=1, rate=2.0, dynamic=True)
testComp.MoveBy(0.2, 502, dx=100, dy=-50, t=1.5, type=2, rate=1.5)
testComp.GotoGroup(0.25, 503, e.PLR, t=1.0, type=3, rate=2.0)

# Rotation triggers
testComp.Rotate(0.3, target=504, angle=90, center=505, t=1.5, type=1, rate=1.0)
testComp.PointToGroup(0.35, 506, e.PLR, t=0.5, type=2, rate=1.5)

# Transform triggers
testComp.Scale(0.4, 507, factor=2.0, divide=False, t=1.0, type=1, rate=1.0)
testComp.Scale(0.45, 508, factor=2.0, divide=True, t=1.0, type=1, rate=1.0)

# Visual triggers
testComp.Pulse(0.5, 509, rgb(4,4,4), exclusive=False, fadeIn=0.3, t=1.0, fadeOut=0.3)
testComp.Alpha(0.55, 510, opacity=50, t=0.8)
testComp.Follow(0.6, 511, e.PLR, t=2.0)

# Control triggers
testComp.Stop(0.65, 512)
testComp.Pause(0.7, 513, useControlID=True)
testComp.Resume(0.75, 513, useControlID=True)

# Caller component
callerComp = Component("MainCaller", group(36))
callerComp.assert_spawn_order(True)
callerComp.Toggle(0, 110, True)
callerComp.Spawn(0.1, testComp.callerGroup, True)

save_all()
