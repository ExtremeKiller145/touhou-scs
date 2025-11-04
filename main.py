import touhou_scs.enums as e
import touhou_scs.utils as u
from touhou_scs.component import Component, GetAllComponents
from touhou_scs.lib import SaveAll

mainCaller = 36
emitter = 110

testComp = Component("TestComponent",u.unknown_g())
testComp.assertSpawnOrder(True)
testComp.MoveTowards(2, 402, 403, {'t': 2, 'dist':20})

callerComp = Component("Test",u.group(36))

callerComp.assertSpawnOrder(True) \
    .Toggle(0, emitter, True) \
    .MoveTowards(0.3, mainCaller, e.PLR, { 't':2, 'type':1, 'rate':2, 'dist': 300}) \
    .Spawn(1, testComp.callerGroup, False)

SaveAll(GetAllComponents())
