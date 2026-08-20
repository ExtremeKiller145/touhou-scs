# Take in a prefab input and automatically reassign, move and copy group IDs,
# and automatically output them to the level.
#
# The original objects are NOT appended — only the copies are.
# Each copy is offset by (copy_index * X_SPACING) from the original positions.

# How many copies to produce
NUM_COPIES = 20

# Horizontal spacing between each copy (in GD units)
X_SPACING = 30 * 4

# Group IDs that should never be remapped (e.g. shared trigger groups)
GROUP_BLACKLIST: set[int] = {5, 132}

INPUT_STRING = "1,1816,2,2444.75,3,283.61,57,200,155,1,24,7,128,1.97,129,1.97,36,1,80,5;1,1816,2,2444.75,3,193.61,57,200,274,200,155,1,128,2.58,129,2.58,36,1,80,200,94,1;1,3801,2,2420.91,3,527.903,108,2336,57,200.201,155,9,6,90,21,2,24,1,128,1.219,129,1.219;1,3801,2,2420.89,3,527.943,108,2336,57,200.201,155,12,6,90,21,1,24,1,128,0.976,129,0.976;1,3801,2,2469.09,3,526.783,108,2336,57,200.201,155,9,6,90,21,2,24,1,128,1.219,129,1.219;1,3801,2,2469.11,3,526.821,108,2336,57,200.201,155,12,6,90,21,1,24,1,128,0.976,129,0.976;1,3801,2,2468.91,3,526.558,108,2336,57,200.201,155,30,25,7,6,90,21,4,24,1,128,1.463,129,1.463;1,3801,2,2445,3,455.088,108,2336,57,200.201,155,9,6,90,21,2,24,1,128,1.219,129,1.219;1,3801,2,2445,3,455.045,108,2336,57,200.201,155,12,6,90,21,1,24,1,128,0.976,129,0.976;1,3801,2,2445,3,455.372,108,2336,57,200.201,155,30,25,7,6,90,21,4,24,1,128,1.463,129,1.463;1,3801,2,2407.47,3,481.974,108,2336,57,200.201,155,9,6,90,21,2,24,1,128,1.219,129,1.219;1,3801,2,2407.43,3,481.961,108,2336,57,200.201,155,12,6,90,21,1,24,1,128,0.976,129,0.976;1,3801,2,2407.74,3,482.067,108,2336,57,200.201,155,30,25,7,6,90,21,4,24,1,128,1.463,129,1.463;1,3801,2,2482.53,3,481.974,108,2336,57,200.201,155,9,6,90,21,2,24,1,128,1.219,129,1.219;1,3801,2,2482.57,3,481.961,108,2336,57,200.201,155,12,6,90,21,1,24,1,128,0.976,129,0.976;1,3801,2,2482.26,3,482.067,108,2336,57,200.201,155,30,25,7,6,90,21,4,24,1,128,1.463,129,1.463;1,3801,2,2466.98,3,464.543,108,2336,57,200.201,155,248,25,7,6,270,21,22,24,1,128,1.917,129,1.917;1,3801,2,2423.02,3,465.565,108,2336,57,200.201,155,248,25,7,6,270,21,22,24,1,128,1.917,129,1.917;1,3801,2,2445,3,530.996,108,2336,57,200.201,155,248,25,7,6,270,21,22,24,1,128,1.917,129,1.917;1,3801,2,2479.25,3,506.46,108,2336,57,200.201,155,248,25,7,6,270,21,22,24,1,128,1.917,129,1.917;1,3801,2,2410.75,3,506.46,108,2336,57,200.201,155,248,25,7,6,270,21,22,24,1,128,1.917,129,1.917;1,3801,2,2421.09,3,527.671,108,2336,57,200.201,155,30,25,7,6,90,21,4,24,1,128,1.463,129,1.463;1,3621,2,2431.13,3,376.856,108,2337,20,1,57,200,155,9,25,2,6,13.38,21,2,24,1,128,0.36,129,0.36;1,3621,2,2458.44,3,376.704,108,2337,20,1,57,200,155,12,25,2,6,13.38,128,0.36,129,0.36;1,3621,2,2431.87,3,378.345,108,2337,20,1,57,200,155,12,25,-2,6,13.38,24,1,128,0.903,129,0.903;1,1837,2,2435.05,3,391.774,108,2337,20,1,57,200,155,36,25,-2,6,13.38,24,1,128,0.895,129,0.895;1,3621,2,2458.79,3,374.47,108,2337,20,1,57,200,155,9,25,1,6,13.38,21,2,24,1,128,0.903,129,0.903;1,1837,2,2461.19,3,385.556,108,2337,20,1,57,200,155,36,25,-2,6,103.38,24,1,128,0.895,129,0.895;1,3637,2,2444.99,3,375.856,108,2337,20,1,57,200,155,30,25,-6,6,13.38,21,4,24,1,128,1.13,129,1.13;1,2101,2,2452.47,3,390.01,108,2337,20,2,57,200,155,239,156,240,25,5,6,13.38,21,20,22,22,24,3,128,1.765,129,1.765;1,2101,2,2435.06,3,385.93,108,2337,20,2,57,200,155,239,156,240,25,5,6,13.38,21,20,22,22,24,3,128,1.765,129,1.765;1,2098,2,2429.87,3,372.773,108,2337,20,2,57,200,155,239,156,240,25,5,6,193.38,21,20,22,22,24,3,128,1.406,129,1.406;1,2101,2,2439.17,3,360.051,108,2337,20,2,57,200,155,239,156,241,25,5,6,193.38,21,20,22,21,24,3,128,1.765,129,1.765;1,2101,2,2457.05,3,366.076,108,2337,20,2,57,200,155,239,156,241,25,5,6,193.38,21,20,22,21,24,3,128,1.765,129,1.765;1,2098,2,2460.75,3,381.641,108,2337,20,2,57,200,155,239,156,241,25,5,6,13.38,21,20,22,21,24,3,128,1.406,129,1.406;1,3637,2,2444.99,3,375.856,108,2337,20,1,57,200,155,9,25,-5,6,13.38,21,2,24,1,128,1.1,129,1.1;"




from gmdbuilder import Level, ObjectType, from_object_string, obj_prop, new_obj

level = Level.from_live_editor()

# Parse input objects
sep = INPUT_STRING.split(";")
if INPUT_STRING.endswith(";"):
    sep = sep[:-1]

source_objects: list[ObjectType] = [from_object_string(s) for s in sep]

for i, obj in enumerate(source_objects):
    if not obj.get(obj_prop.GROUPS):
        raise ValueError(f"Object at index {i} (id={obj.get(obj_prop.ID)}) has no groups — check your input string")

# Collect every unique group-like ID and link ID present in the prefab
seen_groups: list[int] = []
seen_links: list[int] = []
for obj in source_objects:
    for g in (obj.get(obj_prop.GROUPS) or set()):
        if g not in seen_groups and g not in GROUP_BLACKLIST:
            seen_groups.append(g)
    for g in (obj.get(obj_prop.PARENT_GROUPS) or set()):
        if g not in seen_groups and g not in GROUP_BLACKLIST:
            seen_groups.append(g)
    a80 = obj.get('a80')
    if a80 is not None and a80 not in seen_groups and a80 not in GROUP_BLACKLIST:
        seen_groups.append(a80)
    a108 = obj.get('a108')
    if a108 is not None and a108 not in seen_links:
        seen_links.append(a108)
base = max(seen_groups) + 1

for copy_index in range(NUM_COPIES):
    group_map: dict[int, int] = {g: base + copy_index * len(seen_groups) + i for i, g in enumerate(seen_groups)}
    link_map: dict[int, int] = {l: int(level.new.link()) for l in seen_links}

    for src_obj in source_objects:
        # Create a valid base object, then stamp all source fields onto it.
        # Skip a1 (object ID) — it's locked after new_obj() sets it.
        # Delete a155 (color index) as it shouldn't carry over to copies.
        a = src_obj[obj_prop.ID]
        new_object = new_obj(src_obj[obj_prop.ID])
        for k, v in src_obj.items():
            if k == obj_prop.ID:
                continue
            new_object[k] = set(v) if isinstance(v, set) else v
        new_object.pop("a155", None)

        # Remap groups (a57)
        old_groups = new_object.get(obj_prop.GROUPS)
        if old_groups:
            new_object[obj_prop.GROUPS] = {group_map.get(g, g) for g in old_groups}

        # Remap parent groups (a274)
        old_parent_groups = new_object.get(obj_prop.PARENT_GROUPS)
        if old_parent_groups:
            new_object[obj_prop.PARENT_GROUPS] = {group_map.get(g, g) for g in old_parent_groups}

        # Remap collision block id (a80)
        a80 = new_object.get("a80")
        if a80 is not None:
            new_object["a80"] = group_map.get(a80, a80)

        # Remap link id (a108)
        a108 = new_object.get('a108')
        if a108 is not None:
            new_object['a108'] = link_map.get(a108, a108)

        # Offset X relative to the object's original position
        new_object[obj_prop.X] = new_object.get(obj_prop.X, 0.0) + (copy_index + 1) * X_SPACING

        level.objects.append(new_object)


level.export_to_live_editor()
