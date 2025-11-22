# Quick Start Guide - Roblox Slither Simulator

## Build & Test in 5 Minutes

### Prerequisites
- [Roblox Studio](https://www.roblox.com/create) installed
- [Rojo](https://rojo.space/) installed (optional but recommended)

### Option A: Build with Rojo (Recommended)

```bash
# 1. Navigate to project directory
cd /Users/name/homelab/build-a-complete-roblox-slither

# 2. Verify all files are present
./verify-build.sh

# 3. Build the Roblox place file
rojo build default.project.json -o dist/SlitherSimulator.rbxlx

# 4. Open in Roblox Studio
open dist/SlitherSimulator.rbxlx
```

### Option B: Manual Setup in Roblox Studio

1. Open Roblox Studio
2. Create new Baseplate
3. Manually copy scripts from `src/` directory:
   - `ServerScriptService/` → ServerScriptService
   - `ReplicatedStorage/` → ReplicatedStorage
   - `StarterPlayer/` → StarterPlayer
   - `StarterGui/` → StarterGui
4. Create RemoteEvent in ReplicatedStorage:
   - Insert Folder named "RemoteEvents"
   - Insert RemoteEvent named "GameEvent"

### Enable DataStore API Access

**IMPORTANT**: Required for data persistence

1. In Roblox Studio: File → Game Settings
2. Navigate to Security tab
3. Check "Enable Studio Access to API Services"
4. Click Save

### Test Single Player

1. Press **F5** to start local test
2. You should see:
   - HUD displaying gold, rank, length, kills
   - Leaderboard on right side
   - Shield timer at top (spawn protection)
   - Mobile controls (if on touch device)
3. Press **C** to open customization menu
4. Use **Mouse** (desktop) or **Thumbstick** (mobile) to move
5. Press **Space/W** to boost, **Shift/S** to brake

### Test Multiplayer

1. In Roblox Studio: Test → Start Server and Players (2+ clients)
2. Server window shows server-side logic
3. Player windows show client rendering
4. Test features:
   - Movement synchronization
   - Collision detection
   - Food collection
   - Leaderboards updating
   - Revival system

### Run Unit Tests

1. Install [TestEZ](https://github.com/Roblox/testez) from Roblox marketplace
2. Place TestEZ in ReplicatedStorage
3. Open Command Bar (View → Command Bar)
4. Run: `require(game.ServerScriptService.Tests).run()`
5. Check output for test results

### Common Keyboard Shortcuts

- **F5**: Start local test
- **F6**: Stop test
- **F9**: Developer Console (view errors, performance)
- **F12**: Micro Profiler (performance analysis)
- **C**: Open customization menu (in-game)
- **Space/W**: Boost
- **Shift/S**: Brake
- **Z**: Toggle Camera Zoom (POV/Overhead)

### Verify Game is Working

✅ **HUD displays** gold, rank, length, kills  
✅ **Snake moves** smoothly following mouse/touch  
✅ **Body segments follow** head with interpolation  
✅ **Food spawns** around arena  
✅ **Collecting food** increases gold and length  
✅ **Shield timer** shows countdown at spawn  
✅ **Leaderboard** displays (may be empty in Studio)  
✅ **Customization menu** opens with C key  
✅ **Mobile controls** appear on touch devices  

### Troubleshooting

**Issue**: "DataStore request was rejected"  
**Fix**: Enable API Access in Game Settings → Security

**Issue**: No snake visible  
**Fix**: Check ServerScriptService output for errors, ensure GameInitializer ran

**Issue**: Mobile controls not showing  
**Fix**: Must test on actual mobile device or mobile emulator

**Issue**: Leaderboard empty  
**Fix**: Normal in Studio (mock data), test in published game

**Issue**: Low FPS  
**Fix**: Check Developer Console (F9) for performance issues, reduce MAX_SEGMENTS in SnakeConfig.lua

### Next Steps

1. **Customize Game**:
   - Edit `src/ReplicatedStorage/Modules/SnakeConfig.lua` for physics
   - Edit `src/ReplicatedStorage/Modules/RankConfig.lua` for progression
   - Edit `src/ReplicatedStorage/Modules/FoodConfig.lua` for spawning

2. **Publish to Roblox**:
   - File → Publish to Roblox
   - Set max players: 20-50
   - Enable Studio API Access for DataStore
   - Test with real players!

3. **Monitor Performance**:
   - Press F9 for Developer Console
   - Check FPS (target: 60)
   - Check Memory (target: <500MB)
   - Check Network (target: <5KB/s per player)

### File Locations Reference

```
Key Files:
├── default.project.json           # Rojo config
├── README.md                       # Full documentation
├── QUICKSTART.md                   # This file
├── verify-build.sh                 # Build verification
└── src/
    ├── ServerScriptService/
    │   ├── GameInitializer.server.lua  # Server entry point
    │   └── GameSystems/                # Core game logic
    ├── ReplicatedStorage/
    │   ├── Modules/                    # Configuration
    │   └── Shared/                     # Utilities
    ├── StarterPlayer/
    │   └── StarterPlayerScripts/       # Client controllers
    └── StarterGui/                     # UI scripts
```

### Support

- Full documentation: `README.md`
- Architecture specs: `.context-foundry/architecture.md`
- Test examples: `src/ServerScriptService/Tests/`

---

**Ready to build?** Run: `rojo build default.project.json -o dist/SlitherSimulator.rbxlx`
