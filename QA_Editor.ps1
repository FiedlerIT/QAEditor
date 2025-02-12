#Work at branch version
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
    $Questions | Get-Member -MemberType Properties
    $categories = $Questions | Select-Object -ExpandProperty Kategorie -Unique
    Write-Host "Wählen Sie eine Kategorie aus:"

    for ($i = 0; $i -lt $categories.Count; $i++) {
        Write-Host "$(($i + 1)). $($categories[$i])"
    }

    $choice = Read-Host "Geben Sie die Nummer der Kategorie ein"
    if ($choice -as [int] -and $choice -ge 1 -and $choice -le $categories.Count) {
        $singleCategory = $categories[$choice - 1]
        #Write-Host "tempvar: '$tempvar' endetempvar"
        return $singleCategory
    } else {
        Write-Host "Ungültige Eingabe."
        return $null
    }
}
# Info anzeigen, wenn der Benutzer zustimmt
function Show-Info {
    param (
        [string]$InfoText
    )
    $showInfo = Read-Host "Möchten Sie die Info zur Frage sehen? (Ja/Nein)"
    if ($showInfo -eq "Ja") {
        Write-Host "Info: $InfoText"
    }
}
# Fragen aus einer Kategorie anzeigen
function Ask-Questions {
    param (
        [array]$Questions,
        [string]$Category
    )
    #$Questions | Format-List
    #Write-Host " Kategorie: '$Category' ende"
    $filteredQuestions = $Questions | Where-Object { $_.Kategorie -eq $Category }
    
    if (-not $filteredQuestions) {
        Write-Host "Keine unbeantworteten Fragen."
        return
    }

    foreach ($question in $filteredQuestions) {
        Write-Host "Frage: $($question.Frage)"
        # Zeige die Info an, falls verfügbar
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
        $correctAnswers = @()

        for ($i = 1; $i -le 5; $i++) {
            if ($question."Antwort${i}_Korrekt" -eq "True") {
                $correctAnswers += $i
            }
        }

        if (($userAnswers | Sort-Object | Compare-Object -ReferenceObject ($correctAnswers | Sort-Object) -PassThru | Measure-Object).Count -eq 0) {
            Write-Host "Korrekt!"
            $question.Status = "Beantwortet"
        } else {
            Write-Host "Falsch. Die korrekten Antworten waren: $($correctAnswers -join ", ")"
        }
        
    }

    $Questions | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
}

# Test zurücksetzen
function Reset-Test {
    param (
        [array]$Questions
    )

    foreach ($question in $Questions) {
        $tempvar = $question.Status
        Write-Host "setteings: ' $tempvar' "
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
                $categoryObject = Select-Category -Questions $questions
                $category = $categoryObject[-1]
                #Write-Host "anfang: '$teilstring' ende"
                if ($category) {
                   # Write-Host "übergabe Kategorie: '$category' endeübergabe"
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
