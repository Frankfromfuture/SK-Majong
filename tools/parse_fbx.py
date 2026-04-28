import sys
import collections

# A very basic FBX binary parser just to get node names
def parse_fbx(filepath):
    with open(filepath, 'rb') as f:
        data = f.read()

    # Look for "Model" followed by the name
    # In FBX 7.4, nodes have a specific structure, but simple string search might work better
    import re
    # FBX strings are often length-prefixed or null-terminated, but usually ASCII
    # Let's search for "Model" property
    matches = re.finditer(b'Model\x00', data)
    names = []
    for m in matches:
        # The structure is roughly: NodeName (Model), Properties...
        # Let's look backwards for the name
        start = m.start()
        # Usually it's preceded by its length and the string itself
        # For a hacky extraction, let's just find printable strings around it
        window = data[max(0, start-100):min(len(data), start+100)]
        strings = re.findall(b'[a-zA-Z0-9_]{3,}', window)
        for s in strings:
            s_str = s.decode('ascii')
            if 'mj' in s_str.lower() or 'tile' in s_str.lower():
                names.append(s_str)
                
    return collections.Counter(names)

print(parse_fbx("/Users/frankfan/Desktop/Project/SK Majong/assets/models/mj/mjModelGroup.fbx"))
