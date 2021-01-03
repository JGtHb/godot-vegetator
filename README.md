# godot-vegetator
Rapidly generate and place trees, bushes, grass, and more in Godot

![Demo Image](demo_screen_shot.png)

## Overview
This is a proof-of-concept for quickly generating and placing and infinite number of [L-system](https://en.wikipedia.org/wiki/L-system) style plants within a Godot scene. All relevant code is contained within the "Vegetator" folder and can be easily imported to your project. The code is straightforward and can be expanded for your use-case. 

This solution focuses on maintaining high performance while making each plant unique. It achieves this by using the GPU to repeatedly transform a single, simple mesh via MultiMeshInstance. This allows each plant to be unique while keeping the number of draw calls to a minimum.

This can be used out-of-box for quickly adding vegetation to prototype levels, or potentially a final solution for low-poly projects. This is not a good solution for near-camera plants due to the intersections between branches. For this use case, [generating plant meshes as a single array mesh](https://github.com/adszads/godot-procedural-tree-generation) at the cost of increased draw calls would be a better approach.

## Features
#### PlacementManager.gd
Manages the placement of all plants within your scene on regular or irregular target surfaces. This allows you to overlap multiple plant types and have them placed next to each other intelligently without intersecting. (e.g. grass under bushes, and bushes between trees)

#### LeafMultiMeshInstance.gd
Manages the placement of all leaves on plants associated to this node. This allows you to manage and edit the leaves across multiple plants at once. Additional leaves can also be "interpolated" between each plant's branches, allowing for dense foliage while maintaining simple branch structures. Supported by LeafMultiMesh.gd.

#### BranchMultiMeshInstance.gd
Generates the location, rotation, and size of each branch in the user-defined L-system. Tests and records the placement of each plant with PlacementManager.gd. Records and requests leaf placement with LeafMultiMeshInstance.gd. Supported by BranchMultiMesh.gd. 

## How to Use
#### Setup
>See the demo scene for more details

* Import the Vegetator folder into your project
* Set up a minimum of three nodes in your project and attach the relevant scripts. This hierarchy is recommended but not required:
    - Placement Manager Node (Node) (PlacementManager.gd)
        - Leaf Manager Node (MultiMeshInstance) (LeafMultiMeshInstance.gd)
            - Plant Instancer Node (MultiMeshInstance) (BranchMultiMeshInstance.gd)
* Link the nodes together and set the desired parameters using the script variables panel
* Click "reinstance" in the script variables panel to preview the plants in your Godot editor

#### L-system Language
This uses a modified L-system language as shown below:
* "1", "2", "3", "4", or "5": embeds the respective rule in the L-System
* "X", "Y", or "Z": rotate around the respective axis within the max rotation parameter
* "F", "B", "L", "R", "U", "D": rotates towards the given direction within the max rotation parameter (Forward, Back, Left, Right, Up, or Down)
* "[": "Pushes" or "Stashes" the current location for later "Pop" or "Restore"
* "]": "Pops" or "Restores" the previously saved location
* ">": Generates a branch of the given length and rotation

#### Plant Parameters
* "Starting Rule" and "Rule [1-5]": L-system rule using the language above
* "Rule Generations": Number of times to iterate through the L-system
* "Branch Color": Albedo of branch mesh
* "Branch Start Length": Original starting branch length, typically the initial trunk
* "Branch Length Factor": Multiplier by which to (typically) decrease the length of each branch as the plant grows
* "Branch Start Diameter": Original starting branch diameter, typically the initial trunk
* "Branch Diameter Factor": Multiplier by which to (typically) decrease the diameter of each branch as the plant grows
* "Max Rotation": Maximum rotation to apply in the rotation characters of the L-system
* "Grove Diameter": Maximum distance from the instancer origin to place plants
* "Grove Treecount": Maximum number of plants to place within the Grove Diameter. The maximum number may not be reached if there are not enough suitable placement locations found.
* "Grove Spacing": Minimum distance between each plant within the grove.
* "Tree RNG Seed": Random seed for each plant. If you do not like how the individual trees in your grove look you may change this to randomize them.
* "Grove RNG Seed": Random seed for the placement of each plant. If you do not like where the plants are placed in your grove you may change this to randomize the placements.
* "Target Surface": The surface you would like to place plants on
* "Placement Manager": The placement manager node. Typically 1 per scene.
* " Leaf Manager": The leaf manager node. Typically 1 per leaf type.

#### Leaf Parameters
* "Leaf Interpolation Factor": Number of times to add additional leaves between each final branch. Increase to increase the foliage level.
* "Leaf Min Spacing": Minimum spacing between final branch to allow interpolation. Avoids overlapping or duplicate foliage.
* "Leaf Color": Albedo of each leaf mesh

