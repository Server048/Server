
LogToConsole("▶ Script codeScript2 dimulai (loop panjang)...")

for i = 1, 200 do
    StopCheck() -- cek apakah disuruh stop
    addLog("🌱 Farming step " .. i)
    Sleep(5000)
end

LogToConsole("✅ Script codeScript2 selesai.")
