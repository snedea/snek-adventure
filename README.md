# Snek Adventure - Complete Implementation

A fully-featured multiplayer snake adventure game built in Roblox with server-authoritative physics, 20-rank progression system, multiple arenas, and cross-platform support including gamepad controls.

## 🎯 Pattern Library Feature - Build Smarter, Not Harder

**This project doesn't just build a game - it builds knowledge for the future.**

During development, we encountered and solved 8 common Roblox development challenges. These solutions have been automatically captured and saved to the **Context Foundry Pattern Library** (`~/.context-foundry/patterns/` and `~/.context-foundry/skills/`), making future Roblox builds faster and more reliable.

### 📚 Captured Reusable Skills

**1. Arena Builder for Top-Down Games** (`skl-roblox-arena-builder-for-top-d-001`)
- Procedural floor generation with grid lines
- Boundary wall creation with ForceField material
- Studio-safe lighting configuration with pcall error handling
- **Reuse in:** Battle royale, racing games, io-style games, any top-down arena

**2. Disable Default Character Spawning** (`skl-roblox-disable-default-charact-001`)
- Prevents Roblox's humanoid character from spawning
- Essential for custom entity systems
- **Reuse in:** Vehicle games, snake games, custom avatar systems, io-style games

### 🔍 Documented Common Issues & Solutions

The build process encountered and solved **8 critical Roblox development patterns**:

1. **DataStore Access Error in Studio** - Handle `GetDataStore()` failures gracefully with pcall
2. **Lighting Properties Permission Error** - Wrap lighting config in pcall for Studio safety
3. **Blank Game World - Missing Arena** - Never forget environment creation again
4. **Client Scripts Can't Find Modules** - Use `PlayerScripts:WaitForChild()` not `script.Parent`
5. **Default Character Spawns** - Disable `CharacterAutoLoads` before entity systems
6. **Module Double Initialization** - Use initialization guard flags
7. **Rojo Property Syntax** - Wrap properties in `$properties` object
8. **Camera Can't Find Player** - Track custom entities, not `HumanoidRootPart`

### 🚀 How This Helps Future Builds

When building the **next** Roblox game:
- ✅ **Search skills** - `search_skills("arena builder")` loads working code instantly
- ✅ **Avoid pitfalls** - Common issues are checked during Scout phase
- ✅ **Copy solutions** - Battle-tested implementations, not blank templates
- ✅ **Faster iteration** - Skip debugging the same problems twice

**Example workflow:**
```
User: "Build a Roblox vehicle combat game"
Context Foundry: [Searches skills] "Found: roblox-arena-builder"
Context Foundry: [Checks patterns] "Warning: Must disable CharacterAutoLoads first!"
Context Foundry: [Loads code] "Reusing ArenaBuilder.lua from Slither Simulator..."
Result: Arena + character management working in minutes, not hours
```

### 📂 Where Patterns Are Stored

- **Skills (Reusable Code):** `~/.context-foundry/skills/utils/` (JSON + Markdown)
- **Common Issues:** `~/.context-foundry/patterns/common-issues.json`
- **Architecture Patterns:** `~/.context-foundry/patterns/architecture-patterns.json`

All patterns are version-controlled, searchable, and automatically loaded for future builds.

---

## Project Overview

This is a complete, production-ready Roblox game featuring:

- **Real-time multiplayer snake movement** with smooth body segment following
- **Server-authoritative physics** for fair collision detection and exploit prevention
- **20-rank progression system** with gold economy and revival donuts
- **Competitive features**: Leaderboards (monthly + all-time), customization, stats tracking
- **Cross-platform support**: Desktop (mouse) + mobile (touch controls, pinch zoom)
- **Performance optimizations**: Spatial partitioning, object pooling, client-side interpolation

## Architecture Highlights

### Server-Authoritative Design
- All game state changes validated server-side
- Client sends input only (direction vectors)
- Server calculates position, collision, rewards
- Anti-cheat: Speed validation, teleport detection

### Performance Optimizations
- **Spatial Partitioning**: 64×64 stud grid reduces collision checks from O(n²) to O(n)
- **Object Pooling**: 1,000 pre-allocated body segments prevent GC spikes
- **Client Interpolation**: Server broadcasts at 20 Hz, clients render at 60 FPS
- **Network Optimization**: Only head positions transmitted, bodies calculated client-side

### Data Persistence
- **DataStore**: Player rank, gold, donuts, customization, stats
- **OrderedDataStore**: Monthly and all-time leaderboards
- **Retry Logic**: 3-attempt exponential backoff for reliability
- **In-Memory Cache**: Reduces DataStore requests, improves performance

## File Structure

```
build-a-complete-roblox-slither/
├── default.project.json              # Rojo configuration
├── README.md                          # This file
├── src/
│   ├── ReplicatedStorage/
│   │   ├── Modules/
│   │   │   ├── SnakeConfig.lua       # Physics constants
│   │   │   ├── RankConfig.lua        # 20 rank definitions
│   │   │   ├── FoodConfig.lua        # Spawn rates, rewards
│   │   │   └── CustomizationData.lua # Colors, styles
│   │   └── Shared/
│   │       ├── Maid.lua              # Cleanup pattern
│   │       ├── Signal.lua            # Event system
│   │       ├── SpatialGrid.lua       # Collision optimization
│   │       └── BodySegmentPool.lua   # Object pooling
│   ├── ServerScriptService/
│   │   ├── GameSystems/
│   │   │   ├── PlayerDataManager.lua # DataStore persistence
│   │   │   ├── RankService.lua       # Rank calculations
│   │   │   ├── ShieldManager.lua     # Spawn protection
│   │   │   ├── FoodSpawner.lua       # Food generation
│   │   │   ├── LeaderboardService.lua # Stats tracking
│   │   │   ├── SnakeManager.lua      # Core gameplay
│   │   │   └── ReviveService.lua     # Donut revival
│   │   ├── GameInitializer.server.lua # Server startup
│   │   └── Tests/
│   │       ├── SnakeManager.spec.lua
│   │       ├── RankService.spec.lua
│   │       ├── FoodSpawner.spec.lua
│   │       ├── PlayerDataManager.spec.lua
│   │       └── init.lua              # Test runner
│   ├── StarterPlayer/
│   │   └── StarterPlayerScripts/
│   │       ├── SnakeController.lua   # Input capture
│   │       ├── MobileControls.lua    # Touch controls
│   │       ├── CameraController.lua  # Zoom/FOV
│   │       └── SnakeRenderer.lua     # Client interpolation
│   └── StarterGui/
│       ├── HUD/
│       │   └── HUD.client.lua        # Stats display
│       ├── Leaderboard/
│       │   └── Leaderboard.client.lua # Top players
│       ├── CustomizationMenu/
│       │   └── CustomizationMenu.client.lua # Color picker
│       ├── RevivePrompt/
│       │   └── RevivePrompt.client.lua # Revival UI
│       └── ShieldTimer/
│           └── ShieldTimer.client.lua # Shield countdown
```

## Installation & Setup

### Prerequisites
- [Roblox Studio](https://www.roblox.com/create)
- [Rojo](https://rojo.space/) (for syncing files to Roblox)
- [Git](https://git-scm.com/) (optional, for version control)

### Build Instructions

1. **Clone or download this repository**
   ```bash
   cd /path/to/build-a-complete-roblox-slither
   ```

2. **Build the Roblox place file**
   ```bash
   rojo build default.project.json -o dist/SlitherSimulator.rbxlx
   ```

3. **Open in Roblox Studio**
   - Open `dist/SlitherSimulator.rbxlx` in Roblox Studio
   - Enable API access: File → Game Settings → Security → Enable Studio Access to API Services

4. **Test locally**
   - Press F5 to test single-player
   - Use Test → Start Server and Players (2+ clients) for multiplayer testing

### Publishing to Roblox

1. **Thorough testing in Studio**
   - Run all integration tests (see Testing section)
   - Verify all features work as expected

2. **Publish**
   - File → Publish to Roblox
   - Create new game or update existing
   - Configure game settings:
     - Max Players: 20-50 (recommended)
     - Genre: Action, Multiplayer
     - Enable Studio API Access for DataStore

3. **Monitor performance**
   - Use Developer Console (F9) to check FPS, memory, network
   - Monitor DataStore request limits

## Game Features

### Core Gameplay
- **Snake Movement**: Smooth, responsive controls (mouse/touch)
- **Body Following**: Realistic segment trailing with interpolation
- **Collision Detection**: Fair, server-validated hit detection
- **Food Collection**: Auto-magnet system (range increases with rank)
- **Growth System**: Gain segments from food and kills

### Progression System
- **20 Ranks**: Worm → Ouroboros (86,000 gold for max rank)
- **Benefits per Rank**:
  - Increased magnet range (10 → 66 studs)
  - Reduced boost cooldown (10s → 6.2s)
  - Reduced brake cooldown (8s → 5.15s)
  - Shield duration (10s → 5s)
- **Gold Rewards**: Scale with rank (higher ranks = more gold per food)

### Abilities
- **Boost**: Temporary 1.8× speed increase (cooldown based on rank)
- **Brake**: Temporary 0.5× speed decrease for precision (cooldown based on rank)
- **Shield**: Spawn protection prevents death (duration based on rank)

### Competitive Features
- **Leaderboards**: 
  - Monthly and All-Time stats
  - Track kills, longest length, total food
  - Top 10 players displayed
- **Stats Tracking**: Total kills, longest snake, food collected
- **Badges**: (Planned for V2) Top 10 monthly, achievements

### Customization
- **17 Colors**: Unlock colors by reaching specific ranks
- **Special Colors**: Rainbow (rank 15), Galaxy (rank 20)
- **Mouth Styles**: 5 styles unlocked by rank
- **Eye Styles**: 6 styles unlocked by rank
- **Effects**: (Planned for V2) Particle trails, animated features

### Revival System
- **Donuts**: Start with 3 free revival donuts
- **Revival Prompt**: 10-second window to accept/decline
- **Respawn with Shield**: Revived snakes get spawn protection

### Mobile Support
- **Touch Controls**: Dynamic thumbstick for movement
- **Boost/Brake Buttons**: Large, accessible buttons
- **Pinch Zoom**: Zoom in/out with two-finger pinch
- **Normalized Input**: Same precision as desktop mouse

## Testing

### Unit Tests (TestEZ)

1. **Install TestEZ**
   - Get TestEZ from Roblox marketplace
   - Place in ReplicatedStorage

2. **Run Tests**
   - Open Command Bar (View → Command Bar)
   - Run: `require(game.ServerScriptService.Tests).run()`

3. **Test Coverage**
   - SnakeManager: Movement, collision, boost/brake
   - RankService: Rank calculations, magnet range
   - FoodSpawner: Poisson disk, spatial grid
   - PlayerDataManager: DataStore, retry logic

### Integration Tests (Manual)

1. **Movement**: 2+ players, verify smooth body following
2. **Collision**: Head-body contact → death → food scatter
3. **Boost/Brake**: Cooldowns respect rank, visual feedback
4. **Food Collection**: Gold awarded, magnet range scales with rank
5. **Rank Progression**: Collect gold → rank up → benefits apply
6. **Shield**: Spawn protection countdown, invulnerability
7. **Leaderboards**: Stats update, monthly resets
8. **Revival**: Donut prompt, respawn with shield
9. **Customization**: Color changes persist on rejoin
10. **Mobile**: Thumbstick, pinch zoom, boost/brake buttons

### Performance Benchmarks

**Targets**:
- 60 FPS with 20 snakes (50 segments each = 1,000 parts)
- <5ms per frame for collision detection (SpatialGrid)
- <5KB/s bandwidth per player
- <500MB server memory (object pooling)
- <100ms input latency (client → server → update)

**Load Testing**:
- Test with 50+ concurrent players
- Monitor server performance in Developer Console
- Check DataStore throttling (60 + numPlayers × 10 requests/min)

## Configuration

### Snake Physics (SnakeConfig.lua)
```lua
BASE_SPEED = 16              -- Studs per second
BOOST_MULTIPLIER = 1.8       -- Speed boost
BRAKE_MULTIPLIER = 0.5       -- Speed reduction
SEGMENT_SPACING = 3          -- Studs between segments
INITIAL_SEGMENTS = 5         -- Starting length
MAX_SEGMENTS = 100           -- Maximum length
```

### Food Spawning (FoodConfig.lua)
```lua
MAX_FOOD = 500               -- Maximum food in arena
SPAWN_RATE = 2.0             -- Seconds between spawns
SPAWN_BATCH_SIZE = 10        -- Food per batch
MIN_DISTANCE = 15            -- Poisson disk minimum
```

### Ranks (RankConfig.lua)
- 20 ranks with configurable thresholds
- Customizable magnet range, cooldowns, shield duration
- Easy to add new ranks or adjust balancing

## Security & Anti-Cheat

### Server-Side Validation
- All movement validated (direction, speed, position)
- Collision detection entirely server-side
- Gold/donut changes server-authoritative
- Customization choices validated against rank

### Anti-Exploit Measures
- **Speed Check**: Rejects movement exceeding max possible distance
- **Teleport Detection**: Validates position changes against last known position
- **Input Validation**: Direction must be unit vector
- **Business Logic**: Rank requirements enforced for customization

## Performance Optimizations

### Spatial Partitioning
- Divides arena into 64×64 stud cells
- Only checks collisions in same + 8 adjacent cells
- Reduces O(n²) to O(n) complexity

### Object Pooling
- Pre-allocates 1,000 body segments at startup
- Acquire/release instead of create/destroy
- Prevents GC spikes, improves frame stability

### Client-Side Interpolation
- Server broadcasts head position at 20 Hz
- Clients interpolate segments at 60 FPS
- Reduces network traffic by ~66%

### Network Optimization
- Only head position/rotation transmitted
- Body segments calculated client-side
- Throttled updates (0.05s intervals)

### DataStore Optimization
- In-memory cache reduces requests
- Batched updates (60-second flush)
- Retry logic with exponential backoff

## Known Limitations

### V1 Scope
- **Monthly Reset**: Requires manual script trigger
- **No Teams**: Solo gameplay only
- **No Spectate**: Players can't watch after death
- **Limited Customization**: 17 colors, 5 mouths, 6 eyes (no particles)

### Technical Constraints
- **Max Players**: 20-50 (performance-dependent)
- **DataStore Limits**: 60 + numPlayers × 10 requests/min
- **Studio Testing**: Mock DataStore (data not persisted)

## Roadmap (V2)

### Planned Features
- **Scheduled Monthly Reset**: Time-scoped OrderedDataStore keys
- **Advanced Customization**: Particle trails, animated mouths, emotes
- **Spectate Mode**: Watch other players after death
- **Team Mode**: 2v2 or team deathmatch variants
- **Power-Ups**: Temporary invincibility, speed boosts, invisibility
- **Analytics Dashboard**: Track player retention, session length, engagement
- **Badges**: Achievements, top 10 rewards, milestones
- **Private Servers**: Custom game modes, friend lobbies

### Performance Improvements
- **LOD System**: Distant snakes rendered with fewer segments
- **Occlusion Culling**: Hide snakes outside camera view
- **Dynamic Tick Rate**: Adjust update rate based on player count

## Troubleshooting

### Common Issues

1. **"DataStore request was rejected"**
   - Cause: Too many requests (rate limit)
   - Solution: Wait 60 seconds, reduce player count, or increase flush interval

2. **"Pool exhausted, creating new segment"**
   - Cause: More than 1,000 body segments active
   - Solution: Increase `POOL_SIZE` in BodySegmentPool.lua

3. **Low FPS with many snakes**
   - Cause: Too many parts, collision checks
   - Solution: Reduce MAX_SEGMENTS, optimize SpatialGrid cell size

4. **Leaderboard not updating**
   - Cause: Studio mode (mock DataStore) or rate limiting
   - Solution: Test in published game, check DataStore requests

5. **Mobile controls not appearing**
   - Cause: Device not detected as mobile
   - Solution: Test on actual mobile device, check UserInputService

### Debug Tools

- **Developer Console (F9)**: Monitor FPS, memory, network, errors
- **Server Stats**: Print BodySegmentPool stats, SpatialGrid count
- **Network Graph**: View incoming/outgoing data rates
- **Micro Profiler**: Profile server/client performance

## Credits & Acknowledgments

### Architectural Patterns
- **Nevermore Engine**: Maid cleanup pattern
- **Knit Framework**: Service/controller architecture inspiration
- **Roblox Best Practices**: DataStore, RemoteEvents, performance patterns

### Inspiration
- **Slither.io**: Original game concept and mechanics
- **Agar.io**: Multiplayer arena gameplay

## License

This project is provided as-is for educational and commercial use in Roblox. No warranty is provided. Attribution appreciated but not required.

## Support

For issues, questions, or contributions:
- Review the architecture documentation: `.context-foundry/architecture.md`
- Check the test files for usage examples
- Consult Roblox documentation for platform-specific questions

---

**Built with Roblox Studio + Rojo** | **Version**: 1.0.0 | **Last Updated**: 2025-11-22
