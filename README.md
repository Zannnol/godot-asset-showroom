# Godot Asset & Shader Showroom

[![Build Status](https://github.com/Zannnol/godot-asset-showroom/actions/workflows/build.yml/badge.svg)](https://github.com/Zannnol/godot-asset-showroom/actions)
[![Latest Release](https://img.shields.io/github/v/release/Zannnol/godot-asset-showroom)](https://github.com/Zannnol/godot-asset-showroom/releases/latest)
![Godot Engine](https://img.shields.io/badge/Godot-4.6.1--stable-478cbf?logo=godotengine&logoColor=white)
![Platforms](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue)
[![License](https://img.shields.io/github/license/Zannnol/godot-asset-showroom)](LICENSE)

An internal desktop utility built with **Godot 4** designed for 3D artists and technical artists. It provides a standalone, portable environment to quickly load, inspect, and evaluate 3D models, materials, and post-processing shaders without requiring any knowledge of the Godot Engine interface.

<img width="100%" align="center" alt="Godot-asset-viewer-demo" src="https://github.com/user-attachments/assets/89f32491-be8c-48c2-ae54-13b8fda4b5d3" />

---

## Wiki & Documentation

For detailed user guides, technical architecture details, and troubleshooting, visit the official **[Project Wiki](https://github.com/Zannnol/godot-asset-showroom/wiki)**:

* **[User Guide](https://github.com/Zannnol/godot-asset-showroom/wiki/User%E2%80%90Guide)**: Camera controls, Drag & Drop usage, and lighting adjustments.
* **[Technical Documentation](https://github.com/Zannnol/godot-asset-showroom/wiki/Technical%E2%80%90Documentation)**: Scene hierarchy, `AssetImporter`, and build pipeline.
* **[FAQ & Troubleshooting](https://github.com/Zannnol/godot-asset-showroom/wiki/FAQ%E2%80%90Troubleshooting)**: Common import issues and solutions.

---

## Key Features & Distribution

* **Portable Executable**: Distributed as a single standalone build. No installation or Godot engine dependency is required for end-users.
* **Drag & Drop Runtime Importer**: Instant `.glb` / `.gltf` loading with automatic bounding box calculation (AABB), bottom-center pedestal alignment, and dynamic camera refocusing.
* **Live Asset Metrics**: Real-time inspection panel displaying triangle count, vertex count, surface count, and exact dimensions ($X \times Y \times Z$).
* **PBR Lighting Studio**: Customizable HDRI environment, direction-adjustable key light, Kelvin color temperature slider, and viewport-anchored PBR reference spheres (Chrome & Matte).
* **Shader Testing Grounds**: Environment configured to support real-time post-processing and custom shader dynamic binding.
---

## Getting Started for Users

1. Go to the **[Releases](https://github.com/Zannnol/godot-asset-showroom/releases)** section of this repository.
2. Download the latest `Showroom-vX.X.X.zip` archive for your platform.
3. Extract the contents to any directory.
4. Launch `Showroom.exe` (or the corresponding executable for Linux and macOS).
---

## Roadmap & Features Status

### Implemented
- [x] Orbiting 3D camera system with pan, zoom, and target offset (`orbit_camera.gd`)
- [x] Studio environment lighting setup (HDRI skybox and key directional light with Kelvin temperature)
- [x] Real-time post-processing layer
- [x] Viewport-fixed PBR material reference spheres (Chrome & Matte)
- [x] Runtime mesh and material importer (glTF 2.0 / GLB) with Drag & Drop support
- [x] Automatic mesh recentering, bottom-Y pedestal alignment, and camera auto-framing
- [x] Real-time mesh info & stats overlay (triangles, vertices, surfaces, size)
- [x] Windows portable builds
- [x] Linux portable builds *(Built, pending testing)*
- [x] macOS portable builds *(Built, pending testing)*

### In Development / Planned
- [ ] OBJ importer support (`#12`)
- [ ] UV & Surface inspection views (`#9`, `#11`)
- [ ] Custom HDRI switching and rotation (`#15`, `#19`)
- [ ] Custom light direction / rotation (`#20`)
- [ ] Viewport camera reset (`#21`)
- [ ] Background color customization (`#22`)
- [ ] Screenshot & turntable GIF/video export module (`#23`)
- [ ] WebGL / WebAssembly build (`#10`)

---

## Repository Structure

```text
res://
├── assets/          # HDRI environments, test meshes, base textures
├── scenes/          # Main scene and modular UI components
│   ├── components/  # Sub-scenes (reference spheres, stage, etc.)
│   └── ui/          # UI overlays and control panels
├── scripts/         # Core camera, importer, and logic scripts
└── shaders/         # Production and draft shader pipeline
```

---

## Development Setup

If you wish to contribute or modify the project using Godot Engine:

1. Clone this repository:
   ```bash
   git clone https://github.com/Zannnol/godot-asset-showroom.git
   ```
2. Open **Godot Engine 4.x** (v4.6+ recommended).
3. Import the project using `project.godot`.
4. Launch the project from `res://scenes/main_showroom.tscn`.
