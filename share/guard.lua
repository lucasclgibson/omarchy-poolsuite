-- Poolsuite guard for mpv: stop with a note the bar player shows when
-- SoundCloud isn't serving tracks, instead of racing through the playlist:
--   * 5 tracks in a row fail to load, or
--   * the channel itself (the SoundCloud set) fails to load.
local state = os.getenv("POOLSUITE_STATE")
local fails = 0

local function give_up()
  if state then
    local f = io.open(state .. "/error", "w")
    if f then f:write("SoundCloud unavailable, try later"); f:close() end
  end
  mp.command("quit 3")
end

mp.register_event("file-loaded", function()
  fails = 0
  if state then os.remove(state .. "/error") end
end)

mp.register_event("end-file", function(event)
  if event.reason ~= "error" then return end
  fails = fails + 1
  -- A lone entry that failed is the set URL itself: nothing else to try.
  if fails >= 5 or (mp.get_property_number("playlist-count", 0) <= 1) then
    give_up()
  end
end)
