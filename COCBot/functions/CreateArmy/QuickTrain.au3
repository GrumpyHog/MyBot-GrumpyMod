; #FUNCTION# ====================================================================================================================
; Name ..........: Quick Train
; Description ...: New and a complete quick train system
; Syntax ........:
; Parameters ....: None
; Return values .: None
; Author ........: Demen
; Modified ......:
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2019
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
#include-once
#include <Array.au3>
#include <MsgBoxConstants.au3>

Local $g_bDoubleTrainDummy = False

Func QuickTrain()
	Local $bDebug = $g_bDebugSetlogTrain Or $g_bDebugSetlog
	Local $bNeedRecheckTroop = False, $bNeedRecheckSpell = False, $bNeedRecheckSiegeMachine = False
	Local $iTroopStatus = -1, $iSpellStatus = -1, $iSiegeStatus = -1 ; 0 = empty, 1 = full camp, 2 = full queue

	If $bDebug Then SetLog(" == Quick Train == ", $COLOR_ACTION)

	; Troop
	If Not $g_bDonationEnabled Or Not $g_bChkDonate Or Not MakingDonatedTroops("Troops") Then ; No need OpenTroopsTab() if MakingDonatedTroops() returns true
		If Not OpenTroopsTab(False, "QuickTrain()") Then Return
		If _Sleep(250) Then Return
	EndIf

	Local $iStep = 1
	While 1
		Local $avTroopCamp = GetCurrentArmy(48, 160)
		SetLog("Checking Troop tab: " & $avTroopCamp[0] & "/" & $avTroopCamp[1] * 2)
		If $avTroopCamp[1] = 0 Then ExitLoop

		If $avTroopCamp[0] <= 0 Then ; 0/280
			$iTroopStatus = 0
			If $bDebug Then SetLog("No troop", $COLOR_DEBUG)

		ElseIf $avTroopCamp[0] < $avTroopCamp[1] Then ; 1-279/280
			If Not IsQueueEmpty("Troops", True, False) Then DeleteQueued("Troops")
			$bNeedRecheckTroop = True
			If $bDebug Then SetLog("$bNeedRecheckTroop for at Army Tab: " & $bNeedRecheckTroop, $COLOR_DEBUG)

		ElseIf $avTroopCamp[0] = $avTroopCamp[1] Then ; 280/280
			$iTroopStatus = 1
			If $bDebug Then SetLog($g_bDoubleTrain ? "ready to make double troop training" : "troops are training perfectly", $COLOR_DEBUG)

		ElseIf $avTroopCamp[0] <= $avTroopCamp[1] * 1.5 Then ; 281-420/560
			RemoveExtraTroopsQueue()
			If $bDebug Then SetLog($iStep & ". RemoveExtraTroopsQueue()", $COLOR_DEBUG)
			If _Sleep(250) Then Return
			$iStep += 1
			If $iStep = 6 Then ExitLoop
			ContinueLoop

		ElseIf $avTroopCamp[0] <= $avTroopCamp[1] * 2 Then ; 421-560/560
			If CheckQueueTroopAndTrainRemain($avTroopCamp, $bDebug) Then
				$iTroopStatus = 2
				If $bDebug Then SetLog($iStep & ". CheckQueueTroopAndTrainRemain()", $COLOR_DEBUG)
			Else
				RemoveExtraTroopsQueue()
				If $bDebug Then SetLog($iStep & ". RemoveExtraTroopsQueue()", $COLOR_DEBUG)
				If _Sleep(250) Then Return
				$iStep += 1
				If $iStep = 6 Then ExitLoop
				ContinueLoop
			EndIf
		EndIf
		ExitLoop
	WEnd

	; Spell
	If $g_iTotalQuickSpells = 0 Then
		$iSpellStatus = 2
	Else
		If Not $g_bDonationEnabled Or Not $g_bChkDonate Or Not MakingDonatedTroops("Spells") Then ; No need OpenSpellsTab() if MakingDonatedTroops() returns true
			If Not OpenSpellsTab(False, "QuickTrain()") Then Return
			If _Sleep(250) Then Return
		EndIf

		Local $Step = 1, $iUnbalancedSpell = 0
		While 1
			Local $aiSpellCamp = GetCurrentArmy(43, 160)
			SetLog("Checking Spell tab: " & $aiSpellCamp[0] & "/" & $aiSpellCamp[1] * 2)
			If $aiSpellCamp[1] > $g_iTotalQuickSpells Then
				SetLog("Unbalance total quick spell vs actual spell capacity: " & $g_iTotalQuickSpells & "/" & $aiSpellCamp[1])
				$iUnbalancedSpell = $aiSpellCamp[1] - $g_iTotalQuickSpells
				$aiSpellCamp[1] = $g_iTotalQuickSpells
			EndIf

			If $aiSpellCamp[0] <= 0 Then ; 0/22
				If $iTroopStatus >= 1 And $g_bQuickArmyMixed Then
					BrewFullSpell()
					$iSpellStatus = 1
					If $iTroopStatus = 2 And $g_bDoubleTrainDummy Then
						BrewFullSpell(True)
						TopUpUnbalancedSpell($iUnbalancedSpell)
						$iSpellStatus = 2
					EndIf
				Else
					$iSpellStatus = 0
					If $bDebug Then SetLog("No Spell", $COLOR_DEBUG)
				EndIf

			ElseIf $aiSpellCamp[0] < $aiSpellCamp[1] Then ; 1-10/11
				If Not IsQueueEmpty("Spells", True, False) Then DeleteQueued("Spells")
				$bNeedRecheckSpell = True
				If $bDebug Then SetLog("$bNeedRecheckSpell at Army Tab: " & $bNeedRecheckSpell, $COLOR_DEBUG)

			ElseIf $aiSpellCamp[0] = $aiSpellCamp[1] Or $aiSpellCamp[0] <= $aiSpellCamp[1] + $iUnbalancedSpell Then  ; 11/22
				If $iTroopStatus = 2 And $g_bQuickArmyMixed And $g_bDoubleTrainDummy Then
					BrewFullSpell(True)
					TopUpUnbalancedSpell($iUnbalancedSpell)
					If $bDebug Then SetLog("$iTroopStatus = " & $iTroopStatus & ". Brewed full queued spell", $COLOR_DEBUG)
					$iSpellStatus = 2
				Else
					$iSpellStatus = 1
					If $bDebug Then SetLog($g_bDoubleTrain ? "ready to make double spell brewing" : "spells are brewing perfectly", $COLOR_DEBUG)
				EndIf

			Else ; If $aiSpellCamp[0] <= $aiSpellCamp[1] * 2 Then ; 12-22/22
				If ($iTroopStatus = 2 Or Not $g_bQuickArmyMixed) And CheckQueueSpellAndTrainRemain($aiSpellCamp, $bDebug, $iUnbalancedSpell) Then
					If $aiSpellCamp[0] < ($aiSpellCamp[1] + $iUnbalancedSpell) * 2 Then TopUpUnbalancedSpell($iUnbalancedSpell)
					$iSpellStatus = 2
				Else
					RemoveExtraTroopsQueue()
					If _Sleep(500) Then Return
					$Step += 1
					If $Step = 6 Then ExitLoop
					ContinueLoop
				EndIf

			EndIf
			ExitLoop
		WEnd
	EndIf

	If $g_iTotalQuickSiegeMachines = 0 Then
		$iSiegeStatus = 2
	Else
		If Not $g_bDonationEnabled Or Not $g_bChkDonate Or Not MakingDonatedTroops("Siege") Then ; No need OpenSiegeMachinesTab() if MakingDonatedTroops() returns true
			If Not OpenSiegeMachinesTab(False, "QuickTrain()") Then Return
			If _Sleep(250) Then Return
		EndIf

		Local $iStep = 0
		While 1
			Local $aiSiegeMachineCamp = GetCurrentArmy(56, 160)
			SetLog("Checking siege machine tab: " & $aiSiegeMachineCamp[0] & "/" & $aiSiegeMachineCamp[1] * 2)

			If $aiSiegeMachineCamp[0] <= 0 Then ;0/6
				TrainSiege()
			ElseIf $aiSiegeMachineCamp[0] < $aiSiegeMachineCamp[1] Then  ;1-2/6
				If Not IsQueueEmpty("SiegeMachines", True, False) Then DeleteQueued("SiegeMachines")
				$bNeedRecheckSiegeMachine = True
				If $bDebug Then SetLog("$bNeedRecheckSiegeMachine at Army Tab: " & $bNeedRecheckSiegeMachine, $COLOR_DEBUG)
			ElseIf $aiSiegeMachineCamp[0] = $aiSiegeMachineCamp[1] Then ; 3/6
				TrainSiege(True)
			Else ; 4-5/6
				RemoveExtraTroopsQueue()
				If _Sleep(500) Then Return
				$iStep += 1
				If $iStep = 6 Then ExitLoop
				ContinueLoop

			EndIf
			ExitLoop
		WEnd
	EndIf

	; check existing army then train missing troops, spells, sieges
	If $bNeedRecheckTroop Or $bNeedRecheckSpell Then

		Local $aWhatToRemove = WhatToTrain(True)

;	    _ArrayDisplay($aWhatToRemove, "$aWhatToRemove")
		showTroopList($aWhatToRemove, "$aWhatToRemove - QuickTrain()")

		RemoveExtraTroops($aWhatToRemove)

		Local $bEmptyTroop = _ColorCheck(_GetPixelColor(30, 205, True), Hex(0xCAC9C1, 6), 20) ; remove all troops
		Local $bEmptySpell = _ColorCheck(_GetPixelColor(30, 350, True), Hex(0xCAC9C1, 6), 20) ; remove all spells

		Local $aWhatToTrain = WhatToTrain(False, False) ; $g_bIsFullArmywithHeroesAndSpells = False

		;_ArrayDisplay($aWhatToTrain, "$aWhatToTrain")
		showTroopList($aWhatToTrain, "$aWhatToTrain - QuickTrain()")
		SetLog("$g_bQuickArmyMixed : " & $g_bQuickArmyMixed)

		If DoWhatToTrainContainTroop($aWhatToTrain) Then
			If $bEmptyTroop And $bEmptySpell Then
				$iTroopStatus = 0
			ElseIf $bEmptyTroop And ($iSpellStatus >= 1 And Not $g_bQuickArmyMixed) Then
				$iTroopStatus = 0
			Else
				If $bDebug Then SetLog("Topping up troops", $COLOR_DEBUG)
				TrainUsingWhatToTrain($aWhatToTrain) ; troop
				$iTroopStatus = 1
			EndIf
		EndIf

		If DoWhatToTrainContainSpell($aWhatToTrain) Then
			SetLog("$bEmptySpell : " & $bEmptySpell & "      $bEmptyTroop : " & $bEmptyTroop)
			If $bEmptySpell And $bEmptyTroop Then
				$iSpellStatus = 0
			ElseIf $bEmptySpell And ($iTroopStatus >= 1 And Not $g_bQuickArmyMixed) Then
				$iSpellStatus = 0
			Else
				If $bDebug Then SetLog("Topping up spells", $COLOR_DEBUG)
				SetLog("Topping up spells", $COLOR_DEBUG)
				BrewUsingWhatToTrain($aWhatToTrain) ; spell
				$iSpellStatus = 1
			EndIf
		EndIf	
	EndIf

	If $bNeedRecheckSiegeMachine Then TrainSiege()

	If _Sleep(250) Then Return

	SetDebugLog("$iTroopStatus = " & $iTroopStatus & ", $iSpellStatus = " & $iSpellStatus & ", $iSiegeStatus = " & $iSiegeStatus)
	If $iTroopStatus = -1 And $iSpellStatus = -1  And $iSiegeStatus = -1 Then
		SetLog("Quick Train failed. Unable to detect training status.", $COLOR_ERROR)
		Return
	EndIf

	Switch _Min($iTroopStatus, $iSpellStatus)
		Case 0
			If Not OpenQuickTrainTab(False, "QuickTrain()") Then Return
			If _Sleep(750) Then Return
			TrainArmyNumber($g_bQuickTrainArmy)
			If $g_bDoubleTrainDummy Then TrainArmyNumber($g_bQuickTrainArmy)
		Case 1
			If $g_bIsFullArmywithHeroesAndSpells Or $g_bDoubleTrainDummy Then
				If $g_bIsFullArmywithHeroesAndSpells Then SetLog(" - Your Army is Full, let's make troops before Attack!", $COLOR_INFO)
				If Not OpenQuickTrainTab(False, "QuickTrain()") Then Return
				If _Sleep(750) Then Return
				TrainArmyNumber($g_bQuickTrainArmy)
			EndIf
	EndSwitch
	If _Sleep(500) Then Return

EndFunc   ;==>QuickTrain

; CheckQuickTrainTroop is called at first run then every 6 six hours, Static $asLastTimeChecked[8] is counter
; Read QuickTrain Armies and store them in QuickTroopActiveCombo
; Set ArmyComp on first run 
Func CheckQuickTrainTroop()

	Local $bResult = True
	Local $iTroop
	Local $iSpell
	Local $bSaveArmy

	Local Static $asLastTimeChecked[8]
	If $g_bFirstStart Then $asLastTimeChecked[$g_iCurAccount] = ""

	If _DateIsValid($asLastTimeChecked[$g_iCurAccount]) Then
		Local $iLastCheck = _DateDiff('n', $asLastTimeChecked[$g_iCurAccount], _NowCalc()) ; elapse time from last check (minutes)
		SetDebugLog("Latest CheckQuickTrainTroop() at: " & $asLastTimeChecked[$g_iCurAccount] & ", Check DateCalc: " & $iLastCheck & " min" & @CRLF & _
		"_ArrayMax($g_aiArmyQuickTroops) = " & _ArrayMax($g_aiArmyQuickTroops))
		If $iLastCheck <= 360 And _ArrayMax($g_aiArmyQuickTroops) > 0 Then Return ; A check each 6 hours [6*60 = 360]
	EndIf

	; check preset supertroops are active
	ChkPresetQTST()

	If Not OpenArmyOverview(False, "CheckQuickTrainTroop()") Then Return
	If _Sleep(250) Then Return

    CheckArmyCamp(False, False, True, True) ; get current troops and spell
    If _Sleep(500) Then Return

	If Not OpenQuickTrainTab(False, "CheckQuickTrainTroop()") Then Return
	If _Sleep(500) Then Return

	; check for super troops in the quick train armies and boosted if needed
	ChkQTST()

	SetLog("Reading troops/spells/siege in quick train army")
	; reset troops/spells in quick army
	Local $aEmptyTroop[$eTroopCount] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	Local $aEmptySpell[$eSpellCount] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	Local $aEmptySiegeMachine[$eSiegeMachineCount] = [0, 0, 0, 0, 0, 0]
	$g_aiArmyQuickTroops = $aEmptyTroop
	$g_aiArmyQuickSpells = $aEmptySpell
	$g_aiArmyQuickSiegeMachines = $aEmptySiegeMachine
	$g_iTotalQuickTroops = 0
	$g_iTotalQuickSpells = 0
	$g_iTotalQuickSiegeMachines = 0
	$g_bQuickArmyMixed = False

	Local $iTroopCamp = 0, $iSpellCamp = 0, $iSiegeMachineCamp = 0, $sLog = ""

	Local $aSaveButton[4] = [808, 300, 0xdcf684, 20] ; green
	Local $aCancelButton[4] = [650, 300, 0xff8c91, 20] ; red
	Local $aRemoveButton[4] = [535, 300, 0xff8f94, 20] ; red

	local $iDistanceBetweenArmies = 108 ; pixels
	local $aArmy1Location[2] = [720, 276] ; first area of quick train army buttons
	Local $aiEditArmyLocation[4] = [720, 276, 845, 385]


	; findImage needs filename and path
	;Local $avEditQuickTrainIcon = _FileListToArrayRec($g_sImgEditQuickTrain, "*", $FLTAR_FILES, $FLTAR_NORECUR, $FLTAR_NOSORT, $FLTAR_FULLPATH)

	;If Not IsArray($avEditQuickTrainIcon) Or UBound($avEditQuickTrainIcon, $UBOUND_ROWS) <= 0 Then
	;	SetLog("Can't find EditQuickTrainIcon");
	;	Return False
	;EndIf

	For $i = 0 To UBound($g_bQuickTrainArmy) - 1 ; check all 3 army combo
		If Not $g_bQuickTrainArmy[$i] Then ContinueLoop ; skip unchecked quick train army

		 $g_aiArmyQuickTroops = $aEmptyTroop
		 $g_aiArmyQuickSpells = $aEmptySpell

		; calculate search area for EditQuickTrainIcon
		Local $sSearchArea = GetDiamondFromArray($aiEditArmyLocation)

		; search for EditQuickTrainIcon
		;Local $aiEditButton = decodeSingleCoord(findImage("EditQuickTrain", $avEditQuickTrainIcon[1], GetDiamondFromRect($sSearchArea), 1, True, Default))
		; icon for edit and create are different use findmultiple
		Local $avEditButton = findMultiple($g_sImgEditQuickTrain, $sSearchArea, $sSearchArea, 0, 1000, 1, "objectname,objectpoints", True)

		If Not IsArray($avEditButton) Or UBound($avEditButton, $UBOUND_ROWS) <= 0 Then
			SetLog("Can't find EditQuickTrainIcon", $COLOR_ERROR)
			If $g_bDebugImageSave Then SaveDebugImage("CheckQuickTrainTroop", False)
			Return False
		EndIf

		;Local $avTempEditButton, $aiEditButton

		; should only return Edit or Create Icon
		Local $avTempEditButton = $avEditButton[0]
		SetLog("Found :" & $avTempEditButton[0], $COLOR_DEBUG)
		Local $aiEditButton = decodeSingleCoord($avTempEditButton[1])

		$bSaveArmy = False

		If IsArray($aiEditButton) And UBound($aiEditButton, 1) >= 2 Then
			ClickP($aiEditButton)
			If _Sleep(1000) Then Return

			Local $TempTroopTotal = 0, $TempSpellTotal = 0, $TempSiegeTotal = 0

			Local $Step = 0
			While 1
				; read troops
				Local $aSearchResult = SearchArmy(@ScriptDir & "\imgxml\ArmyOverview\QuickTrain", 18, 182, 829, 261, "Quick Train") ; return Name, X, Y, Q'ty

				If $aSearchResult[0][0] = "" Then
					If Not $g_abUseInGameArmy[$i] Then
						$Step += 1
						SetLog("No troops/spells detected in Army " & $i + 1 & ", let's create quick train preset", $Step > 3 ? $COLOR_ERROR : $COLOR_BLACK)
						If $Step > 3 Then
							SetLog("Some problems creating army preset", $COLOR_ERROR)
							Click($aCancelButton[0], $aCancelButton[1]) ; Close editing
							If _Sleep(1000) Then Return
							ContinueLoop 2
						EndIf
						CreateQuickTrainPreset($i)
						$bSaveArmy = True
						ContinueLoop
					Else
						SetLog("No troops/spells/sieges detected in Quick Army " & $i + 1, $COLOR_ERROR)
						Click($aCancelButton[0], $aCancelButton[1]) ; Close editing
						If _Sleep(1000) Then Return
						ContinueLoop 2
					EndIf
				EndIf

				; get quantity
				Local $aiInGameTroop = $aEmptyTroop
				Local $aiInGameSpell = $aEmptySpell
				Local $aiInGameSiegeMachine = $aEmptySiegeMachine
				Local $aiGUITroop = $aEmptyTroop
				Local $aiGUISpell = $aEmptySpell
				Local $aiGUISiegeMachine = $aEmptySiegeMachine

				SetLog("Quick Army " & $i + 1 & ":", $COLOR_SUCCESS)
				For $j = 0 To (UBound($aSearchResult) - 1)
					Local $iTroopIndex = TroopIndexLookup($aSearchResult[$j][0])
					If $iTroopIndex >= 0 And $iTroopIndex < $eTroopCount Then
						SetLog("  - " & $g_asTroopNames[$iTroopIndex] & ": " & $aSearchResult[$j][3] & "x", $COLOR_SUCCESS)
						$aiInGameTroop[$iTroopIndex] = $aSearchResult[$j][3]
					ElseIf $iTroopIndex >= $eLSpell And $iTroopIndex <= $eBtSpell Then
						SetLog("  - " & $g_asSpellNames[$iTroopIndex - $eLSpell] & ": " & $aSearchResult[$j][3] & "x", $COLOR_SUCCESS)
						$aiInGameSpell[$iTroopIndex - $eLSpell] = $aSearchResult[$j][3]
					ElseIf $iTroopIndex >= $eWallW And $iTroopIndex <= $eLogL Then
						SetLog("  - " & $g_asSiegeMachineNames[$iTroopIndex - $eWallW] & ": " & $aSearchResult[$j][3] & "x", $COLOR_SUCCESS)
						$aiInGameSiegeMachine[$iTroopIndex - $eWallW] = $aSearchResult[$j][3]
					Else
						SetLog("  - Unsupport troop/spell/siege index: " & $iTroopIndex)
					EndIf
				Next

				; cross check with GUI qty
				If Not $g_abUseInGameArmy[$i] Then
					If $Step <= 3 Then
						For $j = 0 To 6
							If $g_aiQuickTroopType[$i][$j] >= 0 Then $aiGUITroop[$g_aiQuickTroopType[$i][$j]] = $g_aiQuickTroopQty[$i][$j]
							If $g_aiQuickSpellType[$i][$j] >= 0 Then $aiGUISpell[$g_aiQuickSpellType[$i][$j]] = $g_aiQuickSpellQty[$i][$j]
							If $g_aiQuickSiegeMachineType[$i][$j] >= 0 Then $aiGUISiegeMachine[$g_aiQuickSiegeMachineType[$i][$j]] = $g_aiQuickSiegeMachineQty[$i][$j]
						Next
						For $j = 0 To $eTroopCount - 1
							If $aiGUITroop[$j] <> $aiInGameTroop[$j] Then
								Setlog("Wrong troop preset, let's create again. (" & $g_asTroopNames[$j] & ": " & $aiGUITroop[$j] & "/" & $aiInGameTroop[$j] & ")" & ($g_bDebugSetlog ? " - Retry: " & $Step : ""))
								$Step += 1
								CreateQuickTrainPreset($i)
								$bSaveArmy = True
								ContinueLoop 2
							EndIf
						Next
						For $j = 0 To $eSpellCount - 1
							If $aiGUISpell[$j] <> $aiInGameSpell[$j] Then
								Setlog("Wrong spell preset, let's create again (" & $g_asSpellNames[$j] & ": " & $aiGUISpell[$j] & "/" & $aiInGameSpell[$j] & ")" & ($g_bDebugSetlog ? " - Retry: " & $Step : ""))
								$Step += 1
								CreateQuickTrainPreset($i)
								$bSaveArmy = True
								ContinueLoop 2
							EndIf
						Next

						For $j = 0 To $eSiegeMachineCount - 1
							If $aiGUISiegeMachine[$j] <> $aiInGameSiegeMachine[$j] Then
								SetLog("Wrong siege machine preset, let's create again (" & $g_asSiegeMachineNames[$j] & ": " & $aiGUISiegeMachine[$j] & "/" & $aiInGameSiegeMachine[$j] & ")" & ($g_bDebugSetlog ? " - Retry: " & $Step : ""))
								$Step += 1
								CreateQuickTrainPreset($i)
								$bSaveArmy = True
								ContinueLoop 2
							EndIf
						Next

					Else
						SetLog("Some problems creating troop preset", $COLOR_ERROR)
					EndIf
				EndIf

				; If all correct (or after 3 times trying to preset QT army), add result to $g_aiArmyQuickTroops & $g_aiArmyQuickSpells
				For $j = 0 To $eTroopCount - 1
					$g_aiArmyQuickTroops[$j] += $aiInGameTroop[$j]
					$TempTroopTotal += $aiInGameTroop[$j] * $g_aiTroopSpace[$j]              ; tally normal troops

				If $j > $eSpellCount - 1 Then ContinueLoop
					$g_aiArmyQuickSpells[$j] += $aiInGameSpell[$j]
					$TempSpellTotal += $aiInGameSpell[$j] * $g_aiSpellSpace[$j]              ; tally spells

					If $j > $eSiegeMachineCount - 1 Then ContinueLoop
					$g_aiArmyQuickSiegeMachines[$j] += $aiInGameSiegeMachine[$j]
					$TempSiegeTotal += $aiInGameSiegeMachine[$j] * $g_aiSiegeMachineSpace[$j] 		 ; tally sieges
				Next

				ExitLoop
			WEnd

			; check if an army has troops , spells
			If Not $g_bQuickArmyMixed And $TempTroopTotal > 0 And $TempSpellTotal > 0 Then $g_bQuickArmyMixed = True
			SetDebugLog("$g_bQuickArmyMixed: " & $g_bQuickArmyMixed)

			; cross check with army camp
			If _ArrayMax($g_aiArmyQuickTroops) > 0 Then
				Local $TroopCamp = GetCurrentArmy(48, 160)
				$iTroopCamp = $TroopCamp[1] * 2
				If $TempTroopTotal <> $TroopCamp[0] Then
					SetLog("Error reading troops in army setting (" & $TempTroopTotal & " vs " & $TroopCamp[0] & ")", $COLOR_ERROR)
					$bResult = False
				Else
					$g_iTotalQuickTroops = $TempTroopTotal
					SetDebugLog("$g_iTotalQuickTroops: " & $g_iTotalQuickTroops)
				EndIf
			EndIf
			If _ArrayMax($g_aiArmyQuickSpells) > 0 Then
				Local $aiSpellCamp = GetCurrentArmy(146, 160)
				$iSpellCamp = $aiSpellCamp[1] * 2
				If $TempSpellTotal <> $aiSpellCamp[0] Then
					SetLog("Error reading spells in army setting (" & $TempSpellTotal & " vs " & $aiSpellCamp[0] & ")", $COLOR_ERROR)
					$bResult = False
				Else
					$g_iTotalQuickSpells = $TempSpellTotal
					SetDebugLog("$g_iTotalQuickSpells: " & $g_iTotalQuickSpells)
				EndIf
			EndIf
			If _ArrayMax($g_aiArmyQuickSiegeMachines) > 0 Then
				Local $aiSiegeCamp = GetCurrentArmy(236, 160)
				$iSiegeMachineCamp = $aiSiegeCamp[1] * 2
				If $TempSiegeTotal <> $aiSiegeCamp[0] Then
					SetLog("Error reading siege machines in army setting (" & $TempSiegeTotal & " vs " & $aiSiegeCamp[0] & ")", $COLOR_ERROR)
					$bResult = False
				Else
					$g_iTotalQuickSiegeMachines = $TempSiegeTotal
					SetDebugLog("$g_iTotalQuickSiegeMachines: " & $g_iTotalQuickSiegeMachines)
				EndIf
			EndIf

			$sLog &= $i + 1 & " "

			;ClickP($g_abUseInGameArmy[$i] ? $aCancelButton : $aSaveButton)
			If $bSaveArmy = True Then
				SetLog("Edited QT Army....... hit save!")
				ClickP($aSaveButton)
				If _Sleep(8000) Then Return ;wait for 'saved army' to clear
			Else
				SetLog("QT Army is correct....... hit cancel!")
				ClickP($aCancelButton)
				If _Sleep(1000) Then Return
			EndIf
			
		Else
			SetLog('Cannot find "Edit" button for Army ' & $i + 1, $COLOR_ERROR)
			$bResult = False
		EndIf

	  ;_ArrayDisplay($g_aiArmyQuickTroops, "$g_aiArmyQuickTroops")

	  For $iTroop = 0 to $eTroopCount - 1
		 $g_aiArmyQuickTroopsCombo[$i][$iTroop] = $g_aiArmyQuickTroops[$iTroop]
	  Next

	  For $iSpell = 0 to $eSpellCount - 1
		 $g_aiArmyQuickSpellsCombo[$i][$iSpell] = $g_aiArmyQuickSpells[$iSpell]
	  Next

		$aiEditArmyLocation[1] = $aiEditArmyLocation[1] + $iDistanceBetweenArmies
		$aiEditArmyLocation[3] = $aiEditArmyLocation[3] + $iDistanceBetweenArmies

   Next

	debugQuickTroopsSpells()

   ;_ArrayDisplay($g_aiArmyQuickTroops, "$g_aiArmyQuickTroops")
   ;_ArrayDisplay($g_aiArmyQuickSpells, "$g_aiArmyQuickSpells")

   ;_ArrayDisplay($g_aiArmyQuickTroopsCombo, "$g_aiArmyQuickTroopsCombo")
   ;_ArrayDisplay($g_aiArmyQuickSpellsCombo, "$g_aiArmyQuickSpellsCombo")

   ; find which QT troop is best match for what is in current camps
   If $g_iQuickTrainArmyActive = -1 Then
	  $g_iQuickTrainArmyActive = findBestMatchQuickTroopArmy()
   EndIf

   $g_aiArmyQuickTroops= getArmyQuickTroopsActiveCombo()
   $g_aiArmyQuickSpells= getArmyQuickSpellsActiveCombo()

	$g_aiArmyCompTroops = getArmyQuickTroopsActiveCombo()
	$g_aiArmyCompSpells = getArmyQuickSpellsActiveCombo()
	If Not $g_bUseCustomSiegeMachines Then $g_aiArmyCompSiegeMachines = $g_aiArmyQuickSiegeMachines

	debugTroopsSpells($g_aiArmyCompTroops, $g_aiArmyCompSpells, "CheckQuickTrainTroop")

;	$g_aiArmyCompTroops = $g_aiArmyQuickTroops
;	$g_aiArmyCompSpells = $g_aiArmyQuickSpells



	SetLog("$g_iTotalQuickTroops : " & $g_iTotalQuickTroops)
	SetLog("$g_iTotalQuickSpells : " & $g_iTotalQuickSpells)
	SetLog("$g_iTotalQuickSiegeMachines : " & $g_iTotalQuickSiegeMachines)




	;If $g_iTotalQuickTroops > $iTroopCamp Then SetLog("Total troops in combo army " & $sLog & "exceeds your camp capacity (" & $g_iTotalQuickTroops & " vs " & $iTroopCamp & ")", $COLOR_ERROR)
	;If $g_iTotalQuickSpells > $iSpellCamp Then SetLog("Total spells in combo army " & $sLog & "exceeds your camp capacity (" & $g_iTotalQuickSpells & " vs " & $iSpellCamp & ")", $COLOR_ERROR)
	;If $g_iTotalQuickSiegeMachines > $iSiegeMachineCamp Then SetLog("Total siege machines in combo army " & $sLog & "exceeds your camp capacity (" & $g_iTotalQuickSiegeMachines & " vs " & $iSiegeMachineCamp & ")", $COLOR_ERROR)

	CloseWindow("CloseTrain")
	
	$asLastTimeChecked[$g_iCurAccount] = $bResult ? _NowCalc() : ""

EndFunc   ;==>CheckQuickTrainTroop

Func CreateQuickTrainPreset($i)
	SetLog("Creating troops/spells/siege machines preset for Army " & $i + 1)

	Local $aRemoveButton[4] = [535, 300, 0xff8f94, 20] ; red
	Local $iArmyPage = 0

	If _ColorCheck(_GetPixelColor($aRemoveButton[0], $aRemoveButton[1], True), Hex($aRemoveButton[2], 6), $aRemoveButton[2]) Then
		ClickP($aRemoveButton) ; click remove
		If _Sleep(750) Then Return

		DragIfNeeded("Barb")
		
		For $j = 0 To 6
			Local $iIndex = $g_aiQuickTroopType[$i][$j]
			If _ArrayIndexValid($g_aiArmyQuickTroops, $iIndex) Then

				If $iIndex >= $eSDrag And $iArmyPage = 0 Then
					If _Sleep(250) Then Return
					;ClickDrag(620, 445 + $g_iMidOffsetY, 620 - 373, 445 + $g_iMidOffsetY, 2000)
					ClickDrag(810, 445 + $g_iMidOffsetY, 20, 445 + $g_iMidOffsetY, 2000)
					If _Sleep(1500) Then Return
					$iArmyPage = 1
					SetLog("QT Preset Army Page : " &  $iArmyPage)
				EndIf
	
				If $iIndex >= $eLava And $iArmyPage = 1 Then
					If _Sleep(250) Then Return
					;ClickDrag(620, 445 + $g_iMidOffsetY, 620 - 373, 445 + $g_iMidOffsetY, 2000)
					ClickDrag(810, 445 + $g_iMidOffsetY, 20, 445 + $g_iMidOffsetY, 2000)
					If _Sleep(1500) Then Return
					$iArmyPage = 2
					SetLog("QT Preset Army Page : " &  $iArmyPage)
				EndIf

				Local $sFilter = String($g_asTroopShortNames[$iIndex]) & "_*"
				Local $asImageToUse = _FileListToArray($g_sImgTrainTroops, $sFilter, $FLTA_FILES, True)
				SetLog("Training :" & $asImageToUse[1])
				Local $aTrainPos = GetVariable($asImageToUse[1], $iIndex)
				
				If IsArray($aTrainPos) And $aTrainPos[0] <> -1 Then
					SetLog("Adding " & $g_aiQuickTroopQty[$i][$j] & "x " & $g_asTroopNames[$iIndex], $COLOR_SUCCESS)
					ClickP($aTrainPos, $g_aiQuickTroopQty[$i][$j], $g_iTrainClickDelay, "QTrain")
					If _Sleep(1500) Then Return
				EndIf
			EndIf
		Next

		; elixir spells on page 1, dark spells on page 2
		For $j = 0 To 6
			Local $iIndex = $g_aiQuickSpellType[$i][$j]
			If _ArrayIndexValid($g_aiArmyQuickSpells, $iIndex) Then

				; still on page 0 move to page 1
				If $iArmyPage = 0 Then
					If _Sleep(250) Then Return
					ClickDrag(810, 445 + $g_iMidOffsetY, 20, 445 + $g_iMidOffsetY, 2000)
					If _Sleep(1500) Then Return
					$iArmyPage = 1
					SetLog("QT Preset Army Page : " &  $iArmyPage)
				EndIf

				If $iArmyPage = 1 Then
					If _Sleep(250) Then Return
					ClickDrag(810, 445 + $g_iMidOffsetY, 20, 445 + $g_iMidOffsetY, 2000)
					If _Sleep(1500) Then Return
					$iArmyPage = 2
					SetLog("QT Preset Army Page : " &  $iArmyPage)
				EndIf

				If $iArmyPage = 2 Then
					If _Sleep(250) Then Return
					ClickDrag(810, 445 + $g_iMidOffsetY, 810 - 292, 445 + $g_iMidOffsetY, 2000)
					If _Sleep(1500) Then Return
					$iArmyPage = 3
					SetLog("QT Preset Army Page : " &  $iArmyPage)
				EndIf
				
				;If $iArmyPage = 3 Then
				;    If _Sleep(250) Then Return
				;	ClickDrag(620, 445 + $g_iMidOffsetY, 620 - 373, 445 + $g_iMidOffsetY, 2000)
				;	If _Sleep(1500) Then Return
				;	;If Not DragIfNeeded("Witc") Then Return
				;	;If _Sleep(1500) Then Return
				;	$iArmyPage = 4
				;	SetLog("QT Preset Army Page : " &  $iArmyPage)
				;EndIf

				Local $sFilter = String($g_asSpellShortNames[$iIndex]) & "_*"
				Local $asImageToUse = _FileListToArray($g_sImgTrainSpells, $sFilter, $FLTA_FILES, True)
				Local $aTrainPos = GetVariable($asImageToUse[1], $iIndex + $eLSpell)
				If IsArray($aTrainPos) And $aTrainPos[0] <> -1 Then
					SetLog("Adding " & $g_aiQuickSpellQty[$i][$j] & "x " & $g_asSpellNames[$iIndex], $COLOR_SUCCESS)
					ClickP($aTrainPos, $g_aiQuickSpellQty[$i][$j], $g_iTrainClickDelay, "QTrain")
				EndIf
			EndIf
		Next

		If _Sleep(1000) Then Return
	EndIf
EndFunc   ;==>CreateQuickTrainPreset

Func getArmyQuickTroopsActiveCombo()
   Local $aiArmyQuickTroops[$eTroopCount] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
   Local $iTroop = 0

   For $iTroop = 0 to $eTroopCount - 1
	  $aiArmyQuickTroops[$iTroop] = $g_aiArmyQuickTroopsCombo[$g_iQuickTrainArmyActive][$iTroop]
   Next

   Return $aiArmyQuickTroops
EndFunc

Func getArmyQuickSpellsActiveCombo()
   Local $aiArmyQuickSpells[$eSpellCount] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
   Local $iSpell = 0

   For $iSpell = 0 to $eSpellCount - 1
	  $aiArmyQuickSpells[$iSpell] = $g_aiArmyQuickSpellsCombo[$g_iQuickTrainArmyActive][$iSpell]
   Next

   Return $aiArmyQuickSpells
EndFunc


; Show what is in the Troop and Spell arrays
Func debugTroopsSpells($aiTroops, $aiSpells, $army = 'Army Array')

   Local $iTroops = 0
   Local $iSpells = 0
   Local $sTroopName = []
   Local $iTroopQuantity = 0
   Local $sSpellName = []
   Local $iSpellQuantity = 0
   Local $sSiegeName = []
   Local $iSiegeQuantity = 0

	Local $aiSieges = $g_aiArmyCompSiegeMachines

   SetLog($army)

   For $iTroops = 0 to $eTroopCount - 1
	  If $aiTroops[$iTroops] > 0 Then
		 $sTroopName = $g_asTroopNamesPlural[$iTroops]
		 $iTroopQuantity = $aiTroops[$iTroops]

		 SetLog($iTroopQuantity & "  " & $sTroopName)
	  EndIf
   Next

   For $iSpells = 0 to $eSpellCount - 1
	  If $aiSpells[$iSpells] > 0 Then
		 $sSpellName = $g_asSpellNames[$iSpells]
		 $iSpellQuantity = $aiSpells[$iSpells]

		 SetLog($iSpellQuantity & "  " & $sSpellName)
	  EndIf
   Next

   For $i = 0 to $eSiegeMachineCount - 1
	  If $aiSieges[$i] > 0 Then
		 $sSiegeName = $g_asSiegeMachineNames[$i]
		 $iSiegeQuantity = $aiSieges[$i]

		 SetLog($iSiegeQuantity & "  " & $sSiegeName)
	  EndIf
   Next
EndFunc

Func debugQuickTroopsSpells()
	Local $aiZeroTroops[$eTroopCount] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	Local $aiZeroSpells[$eSpellCount] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	Local $i, $j

	;_ArrayDisplay($g_aiArmyQuickTroopsCombo, "$g_aiArmyQuickTroopsCombo")
	;_ArrayDisplay($g_aiArmyQuickSpellsCombo, "$g_aiArmyQuickSpellsCombo")	

	For $i = 0 To 2
		Local $aiTroops = $aiZeroTroops
		Local $aiSpells = $aiZeroSpells

		For $j = 0 to $eTroopCount - 1
			$aiTroops[$j] = $g_aiArmyQuickTroopsCombo[$i][$j]
		Next

		For $j = 0 to $eSpellCount - 1
			$aiSpells[$j] = $g_aiArmyQuickSpellsCombo[$i][$j]
		Next

		debugTroopsSpells($aiTroops, $aiSpells, "QT Army : " & String($i))
	Next

EndFunc

; we want to know which of the quick troop armies is closest to the current army
Func findBestMatchQuickTroopArmy()
   Local $i, $iElement
   Local $iTroopTotal[3]=[0,0,0], $iSpellTotal[3]=[0,0,0], $iTotal[3]=[0,0,0]
   Local $iTroop, $iSpell
   Local $iBestMatch

   ; Find the Abs of all the troop elements - lower value means less difference between the arrays
   For $i = 0 to 2
	  SetDebugLog("Troop Array : " & $i)
	  For $iTroop = 0 to $eTroopCount - 1
		 $iElement = $g_aiCurrentTroops[$iTroop] - $g_aiArmyQuickTroopsCombo[$i][$iTroop]
		 SetDebugLog("Troop Element :" & $iElement)
		 $iTroopTotal[$i] = $iTroopTotal[$i] + Abs($iElement)
	  Next
		 SetDebugLog("Normal Troop Total : " & $iTroopTotal[$i])
   Next

   ; Find the Abs of all the spell elements - lower value means less difference between the arrays
   For $i = 0 to 2
	  SetDebugLog("Spell Array : " & $i)
	  For $iSpell = 0 to $eSpellCount - 1
		 $iElement = $g_aiCurrentSpells[$iSpell] - $g_aiArmyQuickSpellsCombo[$i][$iSpell]
		 SetDebugLog("Spell Element :" & $iElement)
		 $iSpellTotal[$i] = $iSpellTotal[$i] + Abs($iElement)
	  Next
	  SetDebugLog("Spell Total : " & $iSpellTotal[$i])
   Next

   For $i = 0 to 2
	  $iTotal[$i] = $iTroopTotal[$i] + $iSpellTotal[$i]
	  SetLog("Total Array: " & $i & " = " & $iTotal[$i])
   Next

   $iBestMatch = _ArrayMinIndex($iTotal)

   SetLog("Best Match :" & $iBestMatch)

   Return($iBestMatch)
EndFunc

; Coord for each line of troops
; 20, 300, 716, 360
; 20, 415, 716, 465
; 20, 518, 716, 576
;
; Search Quick Train Tab for Super Troops, try to boost if found
; It is possible to have multiple Super Troops in the Quick Train Tab
Func ChkQTST()
	Local $bResult = False
	Local $sQTSuperTroopImages = @ScriptDir & "\imgxml\ArmyOverview\QTSuperTroops"
	Local $asSearchAreas[3] = ["18, 300, 716, 360", "18, 415, 716, 465", "18, 518, 716, 576"]

	local $iDistanceBetweenArmies = 110
	Local $aiTrainButton, $aiSearchArea[4] = [720, 270, 850, 380]

	Local $sBoostTroop1 = ""
	Local $sBoostTroop2 = ""

	SetLog("Searching Quick Train Army for Super Troops")

	; loop thro each user select Quick Train army
	For $i = 0 to 2
		If $g_bQuickTrainArmy[$i] Then
			SetLog("Search QT Army : " & $i)

			; look for the train button
			$aiTrainButton = decodeSingleCoord(findImage("QuickTrainButton", $g_sImgQuickTrain, GetDiamondFromArray($aiSearchArea), 1, True))

			SetLog("TrainButton No Coord : " & UBound($aiTrainButton, $UBOUND_ROWS))
			
			; if it is 'grey out' then less look for Super Troops
			If Not IsArray($aiTrainButton) Or UBound($aiTrainButton, $UBOUND_ROWS) < 2 Then
			
				Local $sSearchArea = GetDiamondFromRect($asSearchAreas[$i])

				; search for Super Troops and return filename, screen coord of tile not needed
				Local $avSuperTroops = findMultiple($sQTSuperTroopImages, $sSearchArea, $sSearchArea, 0, 1000, 0, "objectname")

				;_ArrayDisplay($avSuperTroops, "$avSuperTroops")

				; No Super Troops Continue the loop
				If Not IsArray($avSuperTroops) Or UBound($avSuperTroops, $UBOUND_ROWS) < 1 Then 
					SetLog("No SuperTroops")
					ContinueLoop
				EndIf

				; loop thro all SuperTroops
				For $j = 0 to UBound($avSuperTroops, $UBOUND_ROWS) - 1
					; get the first super troop found
					Local $avTempSuperTroop = $avSuperTroops[$j]
					;_ArrayDisplay($avTempSuperTroop, "$avTempSuperTroop")
					SetLog("$avTempSuperTroop : " & $avTempSuperTroop[0])

					;Local $iSuperTroopIndex = TroopIndexLookup($avTempSuperTroop[0])
					;SetLog("$iSuperTroopIndex : " & $iSuperTroopIndex)

					If $sBoostTroop1 = "" Then
						$sBoostTroop1 = $avTempSuperTroop[0]
						SetLog("Boost 1: " & $sBoostTroop1)
					EndIf
						
					If $sBoostTroop2 = "" And $sBoostTroop1 <> $avTempSuperTroop[0] Then
						$sBoostTroop2 = $avTempSuperTroop[0]
						SetLog("Boost 2: " & $sBoostTroop2)
					EndIf
				Next
			EndIf
	
			$aiSearchArea[1] = ($aiSearchArea[1] + $iDistanceBetweenArmies)
			$aiSearchArea[3] = ($aiSearchArea[3] + $iDistanceBetweenArmies)

		EndIf
	Next

	If $sBoostTroop1 <> "" Then
		CloseWindow("TrainWindow")
		$bResult = True
		If Not BoostSuperTroop($sBoostTroop1) Then SetLog("Failed to Boost: " & $sBoostTroop1)
	EndIf

	If $sBoostTroop2 <> "" Then
		If Not BoostSuperTroop($sBoostTroop2) Then SetLog("Failed to Boost: " & $sBoostTroop2)
	EndIf

	If $bResult Then
		If Not OpenArmyOverview(False, "ChkQTST()") Then Return
		If _Sleep(250) Then Return

		If Not OpenQuickTrainTab(False, "ChkQTST()") Then Return
		If _Sleep(500) Then Return
	EndIf

	Return $bResult
EndFunc

; will only boost 2 super troops
Func ChkPresetQTST()
	Local $sBoostTroop1 = ""
	Local $sBoostTroop2 = ""

	For $i = 0 to 2
		If Not $g_abUseInGameArmy[$i] Then

			For $j = 0 To 6
	
				If $g_aiQuickTroopType[$i][$j] >= 0 Then 
					Local $sName = $g_asTroopShortNames[$g_aiQuickTroopType[$i][$j]]
			
					SetLog("Troop : " & $g_aiQuickTroopType[$i][$j])
					SetLog("Troop : " & $sName)

					If IsSuperTroop($sName) Then
					
						If $sBoostTroop1 = "" Then
							$sBoostTroop1 = $sName
						EndIf
						
						If $sBoostTroop2 = "" And $sBoostTroop1 <> $sName Then
							$sBoostTroop2 = $sName
						EndIf
					
						If $sBoostTroop1 <> $sName And $sBoostTroop2 <> $sName Then
							$g_abUseInGameArmy[$i] = 1
							SetLog("Deactivate Preset Army : " & $i)
						EndIf

					EndIf
				EndIf
			Next
		EndIf
	Next

	If $sBoostTroop1 <> "" Then
		If Not BoostSuperTroop($sBoostTroop1) Then SetLog("Failed to Boost: " & $sBoostTroop1)
	EndIf

	If $sBoostTroop2 <> "" Then
		If Not BoostSuperTroop($sBoostTroop2) Then SetLog("Failed to Boost: " & $sBoostTroop2)
	EndIf

EndFunc

;				If $g_aiQuickTroopType[$i][$j] >= 0 Then $aiGUITroop[$g_aiQuickTroopType[$i][$j]] = $g_aiQuickTroopQty[$i][$j]
;				If $g_aiQuickSpellType[$i][$j] >= 0 Then $aiGUISpell[$g_aiQuickSpellType[$i][$j]] = $g_aiQuickSpellQty[$i][$j]
;				If $g_aiQuickSiegeMachineType[$i][$j] >= 0 Then $aiGUISiegeMachine[$g_aiQuickSiegeMachineType[$i][$j]] = $g_aiQuickSiegeMachineQty[$i][$j]
