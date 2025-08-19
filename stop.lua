
LogToConsole("▶ Script codeScript2 dimulai (loop panjang)...")

for i = 1, 20 do
    StopCheck() -- cek apakah disuruh stop
    LogToConsole("🌱 Farming step " .. i)
    Sleep(1000)
end

LogToConsole("✅ Script codeScript2 selesai.")
