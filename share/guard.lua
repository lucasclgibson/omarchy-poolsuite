-- Poolsuite guard for mpv: if 5 tracks in a row fail to load (SoundCloud
-- refusing or rate-limiting yt-dlp), stop instead of racing through the
-- playlist, and leave a note the bar player shows.
local state = os.getenv("POOLSUITE_STATE")
local fails = 0

mp.register_event("file-loaded", function()
  fails = 0
  if state then os.remove(state .. "/error") end
end)

mp.register_event("end-file", function(event)
  if event.reason ~= "error" then return end
  fails = fails + 1
  if fails >= 5 then
    if state then
      local f = io.open(state .. "/error", "w")
      if f then f:write("SoundCloud unavailable, try later"); f:close() end
    end
    mp.command("quit 3")
  end
end)
