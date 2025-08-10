$csvPath = "C:\Users\mfied\Documents\GitHub\QAEditor\QA.csv"

# CSV-Datei einlesen
function Load-Questions {
    if (Test-Path $csvPath) {
        try {
            return Import-Csv -Path $csvPath -Encoding UTF8
        } catch {
            Write-Host "Fehler beim Einlesen der CSV-Datei: $_"
            return @()
        }
    } else {
        Write-Host "Fehler: Die Datei wurde nicht gefunden."
        return @()
    }
}

# Kategorien anzeigen und auswählen
function Select-Category {
    param ([array]$Questions)

    $categories = $Questions | Where-Object { $_.Kategorie -ne $null } | Select-Object -ExpandProperty Kategorie -Unique
    if (-not $categories) {
        Write-Host "Keine Kategorien verfügbar."
        return $null
    }

    Write-Host "Wählen Sie eine Kategorie aus:"
    for ($i = 0; $i -lt $categories.Count; $i++) {
        Write-Host "$(($i + 1)). $($categories[$i])"
    }

    $choice = Read-Host "Geben Sie die Nummer der Kategorie ein"
    if ($choice -match "^\d+$" -and $choice -ge 1 -and $choice -le $categories.Count) {
        return $categories[$choice - 1]
    } else {
        Write-Host "Ungültige Eingabe."
        return $null
    }
}

# Info anzeigen
function Show-Info {
    param ([string]$InfoText)
    if ((Read-Host "Möchten Sie die Info zur Frage sehen? (Ja/Nein)") -eq "Ja") {
        Write-Host "Info: $InfoText"
    }
}

# Fragen stellen und Punkte berechnen
function Ask-Questions {
    param ([array]$Questions, [string]$Category)

    $filteredQuestions = $Questions | Where-Object { $_.Kategorie -eq $Category }
    if (-not $filteredQuestions) {
        Write-Host "Keine Fragen gefunden."
        return
    }

    $totalQuestions = $filteredQuestions.Count
    $correctCount = 0
    $startTime = Get-Date

    foreach ($question in $filteredQuestions) {
        Write-Host "`nFrage: $($question.Frage)"

        if ($question.Info) {
            Show-Info -InfoText $question.Info
        }

        $answers = @()
        for ($i = 1; $i -le 5; $i++) {
            $answer = $question."Antwort$i"
            if ($answer) {
                $answers += $answer
                Write-Host "$i. $answer"
            }
        }

        $response = Read-Host "Wählen Sie die Nummer(n) der korrekten Antwort(en), getrennt durch Kommas"
        $userAnswers = $response -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -match "^\d+$" } | ForEach-Object { [int]$_ }

        $correctAnswers = @()
        for ($i = 1; $i -le 5; $i++) {
            if ($question."Antwort${i}_Korrekt" -eq "TRUE") {
                $correctAnswers += $i
            }
        }

        # Prüfen auf Übereinstimmung, unabhängig von der Reihenfolge
        if (($userAnswers | Sort-Object) -eq ($correctAnswers | Sort-Object)) {
            Write-Host "✅ Richtig!"
            $correctCount++
        } else {
            Write-Host "❌ Falsch. Die korrekten Antworten waren: $($correctAnswers -join ', ')"
        }
    }

    $endTime = Get-Date
    $duration = $endTime - $startTime
    $successRate = if ($totalQuestions -gt 0) { [math]::Round(($correctCount / $totalQuestions) * 100, 2) } else { 0 }

    Write-Host "`n===== Testergebnis ====="
    Write-Host "Korrekt beantwortet: $correctCount von $totalQuestions"
    Write-Host "Erfolgsquote: $successRate%"
    Write-Host "Benötigte Zeit: $($duration.Minutes) Minuten und $($duration.Seconds) Sekunden"
}

# Test zurücksetzen
function Reset-Test {
    param ([array]$Questions)

    foreach ($question in $Questions) {
        $question.Status = "Unbeantwortet"
    }

    $Questions | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Der Test wurde zurückgesetzt."
}

# Hauptmenü
function Main {
    $questions = Load-Questions
    if (-not $questions) { return }

    while ($true) {
        Write-Host "`n===== Hauptmenü ====="
        Write-Host "1. Test starten"
        Write-Host "2. Test zurücksetzen"
        Write-Host "3. Beenden"

        $choice = Read-Host "Wählen Sie eine Option"
        switch ($choice) {
            "1" {
                $category = Select-Category -Questions $questions
                if ($category) {
                    Ask-Questions -Questions $questions -Category $category
                }
            }
            "2" {
                Reset-Test -Questions $questions
            }
            "3" {
                Write-Host "👋 Programm beendet."
                return
            }
            default {
                Write-Host "Ungültige Eingabe."
            }
        }
    }
}

Main
