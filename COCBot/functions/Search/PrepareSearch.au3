; #FUNCTION# ====================================================================================================================
; Name ..........: PrepareSearch
; Description ...: Goes into searching for a match, breaks shield if it has to
; Syntax ........: PrepareSearch()
; Parameters ....:
; Return values .: None
; Author ........: Code Monkey #4
; Modified ......: KnowJack (Aug 2015), MonkeyHunter(2015-12)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2019
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
#include <Array.au3>
#include <MsgBoxConstants.au3>

Func PrepareSearch($Mode = $DB) ;Click attack button and find match button, will break shield

	SetLog("Going to Attack", $COLOR_INFO)

	; RestartSearchPickupHero - Check Remaining Heal Time
	If $g_bSearchRestartPickupHero And $Mode <> $DT Then
		For $pTroopType = $eKing To $eChampion ; check all 4 hero
			For $pMatchMode = $DB To $g_iModeCount - 1 ; check all attack modes
				If IsUnitUsed($pMatchMode, $pTroopType) Then
					If Not _DateIsValid($g_asHeroHealTime[$pTroopType - $eKing]) Then
						getArmyHeroTime("All", True, True)
						ExitLoop 2
					EndIf
				EndIf
			Next
		Next
	EndIf

	ChkAttackCSVConfig()

	If IsMainPage() Then
		If _Sleep($DELAYTREASURY4) Then Return
		If _CheckPixel($aAttackForTreasury, $g_bCapturePixel, Default, "Is attack for treasury:") Then
			SetLog("It isn't attack for Treasury :-(", $COLOR_SUCCESS)
			Return
		EndIf
		If _Sleep($DELAYTREASURY4) Then Return

		Local $aAttack = findButton("AttackButton", Default, 1, True)
		If IsArray($aAttack) And UBound($aAttack, 1) = 2 Then
			ClickP($aAttack, 1, 0, "#0149")
		Else
			SetLog("Couldn't find the Attack Button!", $COLOR_ERROR)
			If $g_bDebugImageSave Then SaveDebugImage("AttackButtonNotFound")
			Return
		EndIf
	EndIf

	If _Sleep($DELAYPREPARESEARCH1) Then Return

	; 3 possible screens, Legend Sign Up, Multiplayer Attack, Legend Attack (Attack, All Attack Done, End of Day)
	If Not IsLaunchAttackPage() Then
		SetLog("Launch Attack Window did not open!", $COLOR_ERROR)
		AndroidPageError("PrepareSearch")
		checkMainScreen()
		$g_bRestart = True
		$g_bIsClientSyncError = False
		Return
	EndIf

	$g_bCloudsActive = True ; early set of clouds to ensure no android suspend occurs that might cause infinite waits

	$g_bLaunchAttack[$g_iCurAccount] = False
	$g_bAllLeagueAttacksMade = False
	#cs
	
	
	SaveDebugImage("PrepareSearch")
	
	Do
		Local $bSignedUpLegendLeague = False
		Local $sSearchDiamond = GetDiamondFromRect("271,185,834,659")
		Local $avAttackButton = findMultiple($g_sImgPrepareLegendLeagueSearch, $sSearchDiamond, $sSearchDiamond, 0, 1000, 1, "objectname,objectpoints", True)
		If IsArray($avAttackButton) And UBound($avAttackButton, 1) > 0 Then
			$g_bLeagueAttack = True
			Local $avAttackButtonSubResult = $avAttackButton[0]
			Local $sButtonState = $avAttackButtonSubResult[0]
			;If StringInStr($sButtonState, "Ended", 0) > 0 Then
			;	SetLog("League Day ended already! Trying again later", $COLOR_INFO)
			;	$g_bRestart = True
			;	ClickAway()
			;	$g_bForceSwitch = True     ; set this switch accounts next check
			;	Return
			;Else
			If StringInStr($sButtonState, "Made", 0) > 0 Then
				SetLog("All Attacks already made! Returning home", $COLOR_INFO)
				;$g_bRestart = True
				ClickAway()
				$g_bForceSwitch = True     ; set this switch accounts next check
				$g_bAllLeagueAttacksMade = True
				Return
			ElseIf StringInStr($sButtonState, "FindMatchLegend", 0) > 0 Then
				Local $aCoordinates = StringSplit($avAttackButtonSubResult[1], ",", $STR_NOCOUNT)
				ClickP($aCoordinates, 1, 0, "#0149")
				Local $aConfirmAttackButton
				For $i = 0 To 10
					If _Sleep(200) Then Return
					$aConfirmAttackButton = findButton("ConfirmAttack", Default, 1, True)
					If IsArray($aConfirmAttackButton) And UBound($aConfirmAttackButton, 1) = 2 Then
						ClickP($aConfirmAttackButton, 1, 0)
						ExitLoop
					EndIf
				Next
				If Not IsArray($aConfirmAttackButton) And UBound($aConfirmAttackButton, 1) < 2 Then
					SetLog("Couldn't find the confirm attack button!", $COLOR_ERROR)
					Return
				EndIf
			ElseIf StringInStr($sButtonState, "FindMatchNormal") > 0 Then
				Local $aCoordinates = StringSplit($avAttackButtonSubResult[1], ",", $STR_NOCOUNT)
				If IsArray($aCoordinates) And UBound($aCoordinates, 1) = 2 Then
					$g_bLeagueAttack = False
					ClickP($aCoordinates, 1, 0, "#0150")
					ExitLoop
				Else
					SetLog("Couldn't find the Find a Match Button!", $COLOR_ERROR)
					If $g_bDebugImageSave Then SaveDebugImage("FindAMatchBUttonNotFound")
					Return
				EndIf
			ElseIf StringInStr($sButtonState, "Sign", 0) > 0 Then
				SetLog("Sign-up to Legend League", $COLOR_INFO)
				Local $aCoordinates = StringSplit($avAttackButtonSubResult[1], ",", $STR_NOCOUNT)
				ClickP($aCoordinates, 1, 0, "#0000")
				If _Sleep(1000) Then Return
				$aCoordinates = findButton("OK")
				If UBound($aCoordinates) > 1 Then
					SetLog("Sign-up to Legend League done", $COLOR_INFO)
					$bSignedUpLegendLeague = True
					ClickP($aCoordinates, 1, 0, "#0000")
					If _Sleep(1000) Then Return
				Else
					SetLog("Cannot find OK button to sign-up for Legend League", $COLOR_WARNING)
				EndIf
			ElseIf StringInStr($sButtonState, "Oppo", 0) > 0 Then
				SetLog("Finding opponents! Waiting 5 minutes and then try again to find a match", $COLOR_INFO)
				If _Sleep(300000) Then Return     ; Wait 5mins before searching again
				$bSignedUpLegendLeague = True
			Else
				$g_bLeagueAttack = False
				SetLog("Unknown Find a Match Button State: " & $sButtonState, $COLOR_WARNING)
				Return
			EndIf
		ElseIf Number($g_aiCurrentLoot[$eLootTrophy]) >= Number($g_asLeagueDetails[21][4]) Then
			SetLog("Couldn't find the Attack Button!", $COLOR_ERROR)
			Return
		EndIf
	Until Not $bSignedUpLegendLeague
	#ce


	#cs
		If Not $g_bLeagueAttack Then
			Local $aFindMatch = findButton("FindMatch", Default, 1, True)
			If IsArray($aFindMatch) And UBound($aFindMatch, 1) = 2 Then
				ClickP($aFindMatch, 1, 0, "#0150")
			Else
				SetLog("Couldn't find the Find a Match Button!", $COLOR_ERROR)
				If $g_bDebugImageSave Then SaveDebugImage("FindAMatchBUttonNotFound")
				Return
			EndIf
		EndIf
	#ce

	; Legend League
	If $g_bLeagueAttack Then
		Local $aSignUpLeague[4] = [560, 455, 0x3583F3, 25] ; blue sign up
		Local $aRemoveShield[4] = [515, 445, 0x6DBC1F, 25] ; remove shield
		
		; check for Legend League Sign Up
		SetLog("Checking for Legend SignUp: 0x" & _GetPixelColor(560, 455, True))
		
		If _CheckPixel($aSignUpLeague, True, Default, "PrepareSearch") Then
			SetLog("Found Legend SignUp Button")
			Click(Random(560-10, 560+10, 1), Random(455-10, 455+10, 1))
			
			If _Sleep(3000) Then Return
			
			; check for Remove Shield
			SetLog("Checking for Remove Shield Window: 0x" & _GetPixelColor(515, 445, True))
		
			If _CheckPixel($aRemoveShield, True, Default, "PrepareSearch") Then
				SetLog("Found Remove Shield Window")
				Click(Random(515-20, 515+20, 1), Random(445-10, 445+10, 1))
			
				If _Sleep(1000) Then Return
			EndIf
		EndIf
	
		; 4 conditions: FindMatch, All Attacks Made, End of League Day, Searching for Opponent
		; FM : click FM, click Attack!
		; AAM: has a timer to indicate when next attack avaliable
		; ELD: no timer, wait 10 mins?
		; SFO: fading timer could be difficult to read, wait 10 mins?
		Local $sSearchDiamond = GetDiamondFromRect("271,185,834,659")
		Local $avAttackButton = findMultiple($g_sImgPrepareLegendLeagueSearch, $sSearchDiamond, $sSearchDiamond, 0, 1000, 1, "objectname,objectpoints", True)

		$g_sNewLeagueTime[$g_iCurAccount] = NewLeagueTime()
		
		If _DateIsValid($g_sNewLeagueTime[$g_iCurAccount]) Then
			Local $iLastCheck = _DateDiff('n', _NowCalc(), $g_sNewLeagueTime[$g_iCurAccount]) ; elapse time from last check (minutes)
			SetLog("NL Time: " & $g_sNewLeagueTime[$g_iCurAccount] & ", Time to NL: " & $iLastCheck & " min")
		EndIf		
		
		If IsArray($avAttackButton) And UBound($avAttackButton, 1) > 0 Then
			Local $avAttackButtonSubResult = $avAttackButton[0]
			Local $sButtonState = $avAttackButtonSubResult[0]

			If StringInStr($sButtonState, "Ended", 0) > 0 Then
				SetLog("League Day ended already! Trying again later", $COLOR_INFO)
				; trigger a 10 minute wait
				$g_sNewLeagueTime[$g_iCurAccount] = _DateAdd('s', 600, _NowCalc())				
				Return
			ElseIf StringInStr($sButtonState, "Made", 0) > 0 Then
				SetLog("All Attacks already made! Returning home", $COLOR_INFO)
				$g_sNewLeagueTime[$g_iCurAccount] = NewLeagueTime()
				$g_bAllLeagueAttacksMade = True
				Return
			ElseIf StringInStr($sButtonState, "Oppo", 0) > 0 Then
				SetLog("Searching For Opponents! Trying again later", $COLOR_INFO)
				; tigger a 15 minute wait - there is a timer but difficult to read as it fades in/out
				$g_sNewLeagueTime[$g_iCurAccount] = _DateAdd('s', 900, _NowCalc())
				Return
			ElseIf StringInStr($sButtonState, "Legends", 0) > 0 Then
				Local $aCoordinates = StringSplit($avAttackButtonSubResult[1], ",", $STR_NOCOUNT)
				ClickP($aCoordinates, 1, 0, "#0149")

				If _Sleep(500) Then Return

				Local $aConfirmAttackButton = findButton("ConfirmAttack", Default, 1, True)
				If IsArray($aConfirmAttackButton) And UBound($aConfirmAttackButton, 1) = 2 Then
					ClickP($aConfirmAttackButton, 1, 0)
					$g_bLaunchAttack[$g_iCurAccount] = True
					$g_bLeagueAttack = True
			
				Else
					SetLog("Couldn't find the Confirm Attack Button!", $COLOR_ERROR)
					Return
				EndIf
			Else
				SetLog("Unknown Find a Match Button State: " & $sButtonState, $COLOR_WARNING)
				Return
			EndIf
		Else
			SetLog("Couldn't find the Attack Button!", $COLOR_ERROR)
			$g_sNewLeagueTime[$g_iCurAccount] = _DateAdd('s', 600, _NowCalc())
			Return
		EndIf
	Else
		Local $aFindMatch = findButton("FindMatch", Default, 1, True)
		If IsArray($aFindMatch) And UBound($aFindMatch, 1) = 2 Then
			ClickP($aFindMatch, 1, 0, "#0150")
			$g_bLaunchAttack[$g_iCurAccount] = True
		Else
			; may need a restart as $g_bLaunchAttack is now False
			SetLog("Couldn't find the Find a Match Button!", $COLOR_ERROR)
			Return
		EndIf
	EndIf
	
	If $g_iTownHallLevel <> "" And $g_iTownHallLevel > 0 Then
		$g_iSearchCost += $g_aiSearchCost[$g_iTownHallLevel - 1]
		$g_iStatsTotalGain[$eLootGold] -= $g_aiSearchCost[$g_iTownHallLevel - 1]
	EndIf
	UpdateStats()

	If _Sleep($DELAYPREPARESEARCH2) Then Return

	Local $Result = getAttackDisable(346, 182) ; Grab Ocr for TakeABreak check

	If isGemOpen(True) Then ; Check for gem window open)
		SetLog(" Not enough gold to start searching!", $COLOR_ERROR)
		Click(585, 252, 1, 0, "#0151") ; Click close gem window "X"
		If _Sleep($DELAYPREPARESEARCH1) Then Return
		Click(822, 32, 1, 0, "#0152") ; Click close attack window "X"
		If _Sleep($DELAYPREPARESEARCH1) Then Return
		$g_bOutOfGold = True ; Set flag for out of gold to search for attack
	EndIf

	checkAttackDisable($g_iTaBChkAttack, $Result) ;See If TakeABreak msg on screen

	If $g_bDebugSetlog Then SetDebugLog("PrepareSearch exit check $g_bRestart= " & $g_bRestart & ", $g_bOutOfGold= " & $g_bOutOfGold, $COLOR_DEBUG)

	If $g_bRestart Or $g_bOutOfGold Then ; If we have one or both errors, then return
		$g_bIsClientSyncError = False ; reset fast restart flag to stop OOS mode, collecting resources etc.
		Return
	EndIf
	If IsAttackWhileShieldPage(False) Then ; check for shield window and then button to lose time due attack and click okay
		Local $offColors[3][3] = [[0x000000, 144, 1], [0xFFFFFF, 54, 17], [0xFFFFFF, 54, 28]] ; 2nd Black opposite button, 3rd pixel white "O" center top, 4th pixel White "0" bottom center
		Local $ButtonPixel = _MultiPixelSearch(359, 404 + $g_iMidOffsetY, 510, 445 + $g_iMidOffsetY, 1, 1, Hex(0x000000, 6), $offColors, 20) ; first vertical black pixel of Okay
		If $g_bDebugSetlog Then SetDebugLog("Shield btn clr chk-#1: " & _GetPixelColor(441, 344 + $g_iMidOffsetY, True) & ", #2: " & _
				_GetPixelColor(441 + 144, 344 + $g_iMidOffsetY, True) & ", #3: " & _GetPixelColor(441 + 54, 344 + 17 + $g_iMidOffsetY, True) & ", #4: " & _
				_GetPixelColor(441 + 54, 344 + 10 + $g_iMidOffsetY, True), $COLOR_DEBUG)
		If IsArray($ButtonPixel) Then
			If $g_bDebugSetlog Then
				SetDebugLog("ButtonPixel = " & $ButtonPixel[0] & ", " & $ButtonPixel[1], $COLOR_DEBUG) ;Debug
				SetDebugLog("Shld Btn Pixel color found #1: " & _GetPixelColor($ButtonPixel[0], $ButtonPixel[1], True) & ", #2: " & _GetPixelColor($ButtonPixel[0] + 144, $ButtonPixel[1], True) & ", #3: " & _GetPixelColor($ButtonPixel[0] + 54, $ButtonPixel[1] + 17, True) & ", #4: " & _GetPixelColor($ButtonPixel[0] + 54, $ButtonPixel[1] + 27, True), $COLOR_DEBUG)
			EndIf
			Click($ButtonPixel[0] + 75, $ButtonPixel[1] + 25, 1, 0, "#0153") ; Click Okay Button
		EndIf
	EndIf

EndFunc   ;==>PrepareSearch

Func NewLeagueTime()

	Local $test = getLeagueDayTimer(325, 625)
	
	SetLog($test)

	;Check if OCR returned a valid timer format
	If Not StringRegExp($test, "([0-2]?[0-9]?[Hm]+)", $STR_REGEXPMATCH, 1) Then
		SetLog("getLeagueDayTimer(): no valid return value (" & $test & ")", $COLOR_ERROR)
		Return -1
	EndIf

	; time format 00H00m, 00H, 00m00s, 00m
	; add 1H to avoid any hiccups during start
	; convert to sec add to current DATETIME

	If stringinstr($test, "H") Then
		Local $h = StringSplit($test, "H")

		SetLog($h[0])
		SetLog($h[1])
		SetLog($h[2])
		
		Local $hour = int($h[1])
		Local $m = StringSplit($h[2], "m")
		
		SetLog($m[0])
		SetLog($m[1])
		;SetLog($m[2])
		
		Local $min = int($m[1])
		
		Local $sec = ($hour * 60 * 60) + ($min * 60) + 3600
		
		Local $newLeagueDate = _DateAdd('s', $sec, _NowCalc())
		
		SetLog($newLeagueDate)
	Else
		; in the last hour
		Local $newLeagueDate = _DateAdd('s', 4600, _NowCalc())
		
		SetLog($newLeagueDate)
	EndIf

	Return($newLeagueDate)
EndFunc