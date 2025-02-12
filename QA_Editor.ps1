# Work at second branch version
$csvPath = "D:\EPL-Projekte\SW\PS_Zertifikationssw\QA.csv"

# CSV-Datei einlesen
function Load-Questions {
    Import-Csv -Path $csvPath
}

# Kategorien anzeigen und auswählen
function Select-Category {
    param (
        [array]$Questions
    )
    $categories = $Questions | Select-Object -ExpandProperty Kategorie -Unique
    Write-Host "Wählen Sie eine Kategorie aus:"

    for ($i = 0; $i -lt $categories.Count; $i++) {
        Write-Host "$(($i + 1)). $($categories[$i])"
    }

    $choice = Read-Host "Geben Sie die Nummer der Kategorie ein"
    if ($choice -as [int] -and $choice -ge 1 -and $choice -le $categories.Count) {
        return $categories[$choice - 1]
    } else {
        Write-Host "Ungültige Eingabe."
        return $null
    }
}

# Info anzeigen
function Show-Info {
    param (
        [string]$InfoText
    )
    $showInfo = Read-Host "Möchten Sie die Info zur Frage sehen? (Ja/Nein)"
    if ($showInfo -eq "Ja") {
        Write-Host "Info: $InfoText"
    }
}

# Fragen stellen und Punkte berechnen
function Ask-Questions {
    param (
        [array]$Questions,
        [string]$Category
    )

    $filteredQuestions = $Questions | Where-Object { $_.Kategorie -eq $Category }
    
    if (-not $filteredQuestions) {
        Write-Host "Keine Fragen gefunden."
        return
    }

    $totalQuestions = $filteredQuestions.Count
    $correctCount = 0  # Zähler für korrekte Antworten

    foreach ($question in $filteredQuestions) {
        Write-Host "Frage: $($question.Frage)"
        
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
        $userAnswers = $response -split "," | ForEach-Object { $_.Trim() -as [int] }
        
        # Korrekte Antworten aus der CSV ermitteln
        $correctAnswers = @()
        for ($i = 1; $i -le 5; $i++) {
            if ($question."Antwort${i}_Korrekt" -eq "True") {
                $correctAnswers += $i
            }
        }

        # Prüfen, ob alle korrekten Antworten exakt gewählt wurden
        if (($userAnswers | Sort-Object | Compare-Object -ReferenceObject ($correctAnswers | Sort-Object) -PassThru | Measure-Object).Count -eq 0) {
            Write-Host "Korrekt!"
            $correctCount++
        } else {
            Write-Host "Falsch. Die korrekten Antworten waren: $($correctAnswers -join ', ')"
        }
    }

    # Erfolgsquote berechnen
    $successRate = if ($totalQuestions -gt 0) { [math]::Round(($correctCount / $totalQuestions) * 100, 2) } else { 0 }
    
    # Ergebnisse ausgeben
    Write-Host "Test abgeschlossen."
    Write-Host "Korrekt beantwortete Fragen: $correctCount von $totalQuestions"
    Write-Host "Erfolgsquote: $successRate%"

    $Questions | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
}

# Test zurücksetzen
function Reset-Test {
    param (
        [array]$Questions
    )

    foreach ($question in $Questions) {
        $question.Status = "Unbeantwortet"
    }

    $Questions | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Der Test wurde zurückgesetzt."
}

# Hauptmenü
function Main {
    $questions = Load-Questions

    while ($true) {
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
                break
            }
            default {
                Write-Host "Ungültige Eingabe."
            }
        }
    }
}

Main