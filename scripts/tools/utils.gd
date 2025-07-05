class_name Utils

static func find_entity_in_children(
    node: Node,
) -> Entity:
    if node is Entity:
        return node as Entity
    
    for child in node.get_children():
        if child is Entity:
            return child
        var found = find_entity_in_children(child)
        if found:
            return found
    
    return null