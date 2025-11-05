import touhou_scs.enums as e

from touhou_scs.component import Component
from touhou_scs.lib import save_all
from touhou_scs.utils import group, unknown_g

mainCaller = 36
emitter = 110
new = unknown_g()

testComp = Component("TestComponent",unknown_g())
testComp.assert_spawn_order(True)
testComp.MoveTowards(2, 402, 403, t=4, dist=20)

callerComp = Component("Test",group(36))

callerComp \
    .assert_spawn_order(True) \
    .Toggle(0.2, emitter, True) \
    .MoveTowards(0.3, mainCaller, e.PLR, 
        t=2, dist=200, type=3, dynamic=True) \
    .Spawn(1, testComp.callerGroup, True, remap=f"{new}.{34}", delay=3)

save_all()
