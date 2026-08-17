# Godot Asset & Shader Showroom

[![Build Status](https://img.shields.io/github/actions/workflow/status/Zannnol/godot-asset-showroom/build.yml?branch=main&style=flat-square)](https://github.com/Zannnol/godot-asset-showroom/actions)
[![Latest Release](https://img.shields.io/github/v/release/Zannnol/godot-asset-showroom?style=flat-square)](https://github.com/Zannnol/godot-asset-showroom/releases/latest)
[![Godot Engine](https://img.shields.io/badge/Godot-4.x-blue?style=flat-square&logo=godotengine&logoColor=white)](https://godotengine.org)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-lightgrey?style=flat-square)](https://github.com/Zannnol/godot-asset-showroom/releases/latest)
[![License](https://img.shields.io/github/license/Zannnol/godot-asset-showroom?style=flat-square)](LICENSE)

An internal desktop utility built with Godot 4 designed for 3D artists and technical artists. It provides a standalone, portable environment to quickly load, inspect, and evaluate 3D models, materials, and post-processing shaders without requiring any knowledge of the Godot Engine interface.

---

## Key Features & Distribution

* **Portable Executable**: Distributed as a single standalone build. No installation or Godot engine dependency is required for end-users.
* **Instant Model Evaluation**: Interactive turntable camera setup for inspection of mesh lighting, reflections, and material response.
* **Shader Testing Grounds**: Environment configured to support real-time post-processing and custom shader dynamic binding.

---

## Getting Started for Users

1. Go to the **Releases** section on the right side of this repository.
2. Download the latest `Showroom-vX.X.X.zip` archive for your platform.
3. Extract the contents to any directory.
4. Launch `Showroom.exe` (or the corresponding executable for Linux).

---

## Roadmap & Features Status

### Implemented
- [x] Orbiting 3D target-focused camera system (`orbit_camera.gd`)
- [x] Studio environment lighting setup (HDRI skybox and key directional light)
- [x] Real-time post-processing layer
- [x] Material reference standards (roughness/metallic calibration spheres)

### In Development / Planned
- [ ] Runtime mesh and material importer (glTF 2.0 / OBJ drag-and-drop support)
- [ ] Comprehensive UI suite for environment and shader parameters
- [ ] Real-time shader hot-reloading and dynamic parameter inspector
- [ ] Custom HDRI environment switching from local files
- [ ] Screenshot and turntable animation export module

---

## Repository Structure

```text
res://
├── assets/          # HDRI environments, test meshes, base textures
├── scenes/          # Main scene and modular UI components
├── scripts/         # Core camera, loading, and logic scripts
└── shaders/         # Production and draft shader pipeline
```

---

## Development Setup

If you wish to contribute or modify the project using Godot Engine:

1. Clone this repository:
   ```bash
   git clone https://github.com/Zannnol/godot-asset-showroom.git
   ```
2. Open **Godot Engine 4.x**.
3. Import the project using `project.godot`.
4. Launch the project from `res://scenes/showroom.tscn`.