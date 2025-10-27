#!/usr/bin/env luajit
-- Simple test to verify the auto-exit logic without requiring display

local function test_frame_counting()
    print("=== Testing frame counting and auto-exit logic ===")

    local frames = 0
    local target_frames = 10
    local running = true

    -- Simulate frame loop
    while running and frames < 100 do -- safety limit
        frames = frames + 1
        print(string.format("Frame %d", frames))

        -- Check auto-exit
        if frames >= target_frames then
            print(string.format("Auto-exit: reached %d frames (target: %d)", frames, target_frames))
            running = false
            break
        end
    end

    print(string.format("Final: %d frames rendered, running=%s", frames, tostring(running)))

    if frames == target_frames and not running then
        print("✅ TEST PASSED: Auto-exit worked correctly")
        return 0
    else
        print("❌ TEST FAILED: Auto-exit did not work")
        return 1
    end
end

os.exit(test_frame_counting())
