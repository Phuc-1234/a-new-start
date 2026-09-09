# Architecture Overview

## 1. Project Entry Point & Directory Structure
- **Engine**: Godot 4.7.x (`GL Compatibility` renderer, Jolt Physics 3D)
- **Main Scene**: `res://src/world/main_3d.tscn`
- **Subsystems**:
  - `src/world/`: Environment, level geometry, lighting, and ambient world systems (e.g. wind).
  - `src/player/`: Character controller, combat input, animation state machine, VRM model physics, camera.
  - `src/props/`: Interactive physics objects (e.g. rigid body cubes).
  - `src/legacy_2d/`: Deprecated 2D prototype (retained for reference).
  - `addons/`: Third-party plugins (`Godot-MToon-Shader`, `vrm`).

---

## 2. Scene Tree & Node Hierarchy

### `Main3D` (`res://src/world/main_3d.tscn`)
Top-level coordinator scene assembling the world, character, camera, and physics props:
* **`Arena`** (`res://src/world/arena.tscn`):
  * `WorldEnvironment`: Ambient and background lighting.
  * `DirectionalLight3D`: Primary directional sunlight with shadows.
  * `Floor`: `StaticBody3D` level surface.
  * `WindParticles` (`res://src/world/wind_system.gd`): CPUParticles3D driving visual wind lines and calculating dynamic wind forces. Registered under group `"wind"`.
* **`Character`** (`res://src/player/character.tscn`):
  * Root `CharacterBody3D` (`res://src/player/player_3d.gd`): Movement, attack logic, spring bone wind/inertia reaction, rigid body push collisions.
  * `Model`: VRM character instance (`avatar.vrm`) containing secondary spring bone nodes.
  * `PunchHitbox`: `Area3D` checking overlapping `RigidBody3D` targets on attack frames.
  * `TrailParticles`: `CPUParticles3D` motion trail toggled during movement.
  * `AnimationPlayer` & `AnimationTree`: State machine driving `Idle`, `Walk`, `Punch`, `Kick`.
* **`Camera3D`** (`res://src/player/camera_follow.gd`):
  * Independent camera following `Character` via exported `target_path: NodePath`.
* **Props (`CubeStack`, `LargePileLeft`, `LargePileRight`, `LargePileBack`)**:
  * `RigidBody3D` clusters for testing combat hit impulse and character push physics.

---

## 3. Communication Patterns & Architectural Boundaries

* **Decoupling Rules ("Call Down, Signal Up")**:
  * Subsystems must not use hardcoded cross-boundary node paths (e.g., no `$../../Character` from world nodes or `/root/Main3D/...`).
  * Parent scenes configure connections, exported paths, or inject dependencies.
* **Environmental Interaction (Wind)**:
  * `player_3d.gd` samples wind through `get_tree().get_first_node_in_group(&"wind")` and `get_wind_at()`, keeping player and world decoupled.
* **Camera Targeting**:
  * `camera_follow.gd` references its target through an exported `NodePath` assigned at the parent level (`main_3d.tscn`).
* **Physics & Combat**:
  * Push interactions use `get_slide_collision()` contact impulses.
  * Attack hits query `Area3D.get_overlapping_bodies()` and apply impulses directly to detected `RigidBody3D` nodes.
* **Spring Bone / Cloth Simulation**:
  * `player_3d.gd` accesses the VRM model's `secondary.spring_bones` to dynamically tune skirt collider radii, drag, stiffness, and inject wind/inertia forces (`model_node.springbone_add_force`).

---

## 4. Maintenance Protocol
* **Review**: Before introducing new subsystems, refactoring core scripts, or altering scene trees, review this document.
* **Update**: Whenever adding, removing, or refactoring scenes, nodes, cross-system signals, or groups, update `ARCHITECTURE.md` to reflect the changes.
