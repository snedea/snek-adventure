#!/usr/bin/env python3
"""
Test if macOS can detect game controllers via the Game Controller framework.
"""

import subprocess
import sys

# Create a simple Swift script to check for game controllers
swift_code = '''
import GameController

print("Checking for connected game controllers...")
print("")

let controllers = GCController.controllers()

if controllers.isEmpty {
    print("❌ No game controllers detected")
    print("")
    print("Possible reasons:")
    print("  1. Controller not properly paired/connected")
    print("  2. Controller in sleep mode (press the Xbox button)")
    print("  3. macOS Game Controller framework doesn't recognize this controller")
} else {
    print("✅ Found \\(controllers.count) controller(s):")
    print("")

    for (index, controller) in controllers.enumerated() {
        print("Controller \\(index + 1):")
        print("  Product Category: \\(controller.productCategory)")

        if let vendorName = controller.vendorName {
            print("  Vendor: \\(vendorName)")
        }

        if let extendedGamepad = controller.extendedGamepad {
            print("  Type: Extended Gamepad (Xbox/PlayStation style)")
            print("  Has: D-pad, buttons, triggers, thumbsticks")
        } else if let microGamepad = controller.microGamepad {
            print("  Type: Micro Gamepad (Siri Remote style)")
        }

        print("")
    }
}

print("Note: If controllers are detected here but not in Roblox Studio,")
print("the issue is with Studio's gamepad implementation on macOS.")
'''

# Write the Swift code to a temporary file
import tempfile
import os

with tempfile.NamedTemporaryFile(mode='w', suffix='.swift', delete=False) as f:
    f.write(swift_code)
    swift_file = f.name

try:
    # Compile and run the Swift code
    print("Testing Game Controller detection on macOS...")
    print("=" * 70)
    print()

    result = subprocess.run(
        ['swift', swift_file],
        capture_output=True,
        text=True,
        timeout=5
    )

    print(result.stdout)
    if result.stderr:
        print("Errors:", result.stderr)

    print("=" * 70)

finally:
    # Clean up
    os.unlink(swift_file)
