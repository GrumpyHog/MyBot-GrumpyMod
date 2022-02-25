; #FUNCTION# ====================================================================================================================
; Name ..........: Boost a troop to super troop
; Description ...:
; Syntax ........: BoostSuperTroop($iTroopIndex)
; Parameters ....:
; Return values .: True if boosted, False if not
; Author ........: Fliegerfaust (04/2020)
; Modified ......: GrumpyHog (12/2021)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2020
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
#include <Array.au3>
#include <MsgBoxConstants.au3>


;Func BoostSuperTroop($iTroopIndex)
Func BoostSuperTroop($sTroopName, $bTest = False)
	If Not IsSuperTroop($sTroopName) Then Return False

	;Local $sTroopName = GetTroopName($iTroopIndex)
	SetLog("Trying to boost " & $sTroopName, $COLOR_INFO)
	;ClickAway()
	
	If _Sleep(500) Then Return False

	Local $iErr = 0
	
	Local $sSearchArea = GetDiamondFromRect("70,150,250,250")

	
	While 1

		Local $avBarrel = findMultiple($g_sImgBoostTroopsBarrel, $sSearchArea, $sSearchArea, 0, 1000, 1, "objectname,objectpoints", True)

		If Not IsArray($avBarrel) Or UBound($avBarrel, $UBOUND_ROWS) <= 0 Then
			SetLog("Couldn't find super troop barrel on main village", $COLOR_ERROR)
			If $g_bDebugImageSave Then SaveDebugImage("BoostSuperTroop", False)
			$iErr += 1
			SetLog("Failed to find Barrel: " & $iErr)
		Else
			Local $avTempArray, $aiBarrelCoords
			
			; loop thro the detected images
			For $i = 0 To UBound($avBarrel, $UBOUND_ROWS) - 1
				$avTempArray = $avBarrel[$i]
				SetLog("Barrel Search find : " & $avTempArray[0])
				$aiBarrelCoords = decodeSingleCoord($avTempArray[1])

				If Not IsArray($aiBarrelCoords) Or UBound($aiBarrelCoords, $UBOUND_ROWS) < 2 Then
					SetLog("Couldn't get proper barrel coordinates", $COLOR_ERROR)
					$iErr += 1
					SetLog("Failed to find Barrel Coord: " & $iErr)
				Else
					ExitLoop 2 ; found barrel
				EndIf
			Next
		EndIf
	
		If $iErr > 30 Then
			SetLog("Failed to find barrel restart CoC to reset", $COLOR_INFO)
						
			If _Sleep(1000) Then Return 
			
			RebootAndroid()
			
			waitMainScreen()
			
			If _Sleep(1000) Then Return 
			
			Return False
		EndIf
	
		If _Sleep(100) Then Return
	WEnd

	; click on barrel
	ClickP($aiBarrelCoords)
	If _Sleep(500) Then Return False

	If Not IsWindowOpen($g_sImgSuperTroopsWindow, 10, 200, GetDiamondFromRect("300,150,550,250")) Then
		SetLog("Super troop window did not open, exit", $COLOR_ERROR)
		Return False
	EndIf

	; BoostWindow opened from here on it need to be closed before Returning

	; Drag to the correct page
	DragTroopPage($sTroopName)

	If _Sleep(500) Then Return False

 	; load image file
	Local $asTroopIcon = _FileListToArrayRec($g_sImgBoostTroopsIcons, $sTroopName & "*", $FLTAR_FILES, $FLTAR_NORECUR, $FLTAR_NOSORT, $FLTAR_FULLPATH)

	If Not IsArray($asTroopIcon) And UBound($asTroopIcon, $UBOUND_ROWS) < 1 Then
		SetLog("Cannot find file : " & $asTroopIcon, $COLOR_ERROR)
		CloseWindow("CloseBoost")
		Return False
	EndIf

	; look for troop icon
	Local $aiTroopIcon = decodeSingleCoord(findImage($sTroopName, $asTroopIcon[1], GetDiamondFromRect("130,240,730,520"), 1, True))

	If Not IsArray($aiTroopIcon) Or UBound($aiTroopIcon, $UBOUND_ROWS) < 2 Then
		SetLog($sTroopName & " not available", $COLOR_ERROR)
		CloseWindow("CloseBoost")
		Return False
	EndIf

	If CheckBoostedTroop($aiTroopIcon) Then
		SetLog($sTroopName & " already boosted", $COLOR_ERROR)
		CloseWindow("CloseBoost")
		Return True
	EndIf

	; click on Super Troop Icon
	ClickP($aiTroopIcon)
	If _Sleep(300) Then Return False

	$sSearchArea = GetDiamondFromRect("400,500,750,610")
	Local $avBoostButton = findMultiple($g_sImgBoostTroopsButtons, $sSearchArea, $sSearchArea, 0, 1000, 1, "objectname,objectpoints", True)

	If IsArray($avBoostButton) And UBound($avBoostButton, $UBOUND_ROWS) > 0 Then
		For $i = 0 To UBound($avBoostButton, $UBOUND_ROWS) - 1
			$avTempArray = $avBoostButton[$i]
			If StringInStr($avTempArray[0], "Unavailable", $STR_NOCASESENSE) Then
				SetLog("Couldn't boost " & $sTroopName & "! Boost button is not available", $COLOR_ERROR)
				CloseWindow("CloseST")
				CloseWindow("CloseBoost")
				Return False
			Else
				Local $aiBoostButton = decodeSingleCoord($avTempArray[1])
				ClickP($aiBoostButton)
				If _Sleep(800) Then Return False

				Local $aiConfirmBoost = decodeSingleCoord(findImage("ConfirmBoost", $g_sImgBoostTroopsButtons & "Confirm*", GetDiamondFromRect("230,250,630,530"), 1, True))
				If IsArray($aiConfirmBoost) And UBound($aiConfirmBoost) = 2 Then

					If $bTest Then
						SetLog("Test boosted " & $sTroopName & " successfully!", $COLOR_SUCCESS)
						CloseWindow("CloseST")
						CloseWindow("CloseBoost")
						Return True
					EndIf
					
					ClickP($aiConfirmBoost)
					If _Sleep(500) Then Return False

					If isGemOpen(True) Then
						SetDebugLog("Not enough DE for boosting super troop", $COLOR_DEBUG)
						CloseWindow("CloseST")
						CloseWindow("CloseBoost")
						Return False
					EndIf

					$g_sBoostSuperTroop = ""
					SetLog("Boosted " & $sTroopName & " successfully!", $COLOR_SUCCESS)
					CloseWindow("CloseBoost")
					Return True
				EndIf
			EndIf
		Next
	EndIf

	CloseWindow("CloseBoost")
	Return False
 EndFunc   ;==>BoostSuperTroop


; page 0 = $eSBard -> $eSGobl
; page 1 = $eSWall -> $eSDrag
; page 2 = $eInfernoD -> $eSWitc
; page 3 = $eIceH
Func DragTroopPage($sTroopName)
	Local $iPage
	Local $iTroopIndex = Int(Eval("e" & $sTroopName))
	
	If $iTroopIndex >= $eSBarb And $iTroopIndex <= $eSGobl Then
		Return
	EndIf
	
	If $iTroopIndex >= $eSWall And $iTroopIndex <= $eSDrag Then
		$iPage = 1
	EndIf
	
	If $iTroopIndex >= $eInfernoD And $iTroopIndex <= $eSWitc Then
		$iPage = 2
	EndIf
	
	If $iTroopIndex >= $eIceH Then
		$iPage = 3
	EndIf

	Local $up = 260 ; first page

	For $i = 1 To $iPage

		If $i > 1 Then $up = 320
		If $i = 3 Then $up = 450 ; last page
		
		ClickDrag(428,500,428,$up, 200, "SLOW")
		If _Sleep(500) Then Return False
		SetLog("Page : " & $i)
	Next

EndFunc

; look for clockface on icon
 Func CheckBoostedTroop($aiTroopIcon)
	Local $sImgClockFaceImages = @ScriptDir & "\imgxml\Main Village\BoostSuperTroop\Clock"

	; $aiTroopIcon is x, y coord 
	; calculate bottom left area for clock search
	Local $clock_x = $aiTroopIcon[0];
	Local $clock_y = $aiTroopIcon[1];

	Local $x1 = $clock_x - 100
	Local $y1 = $clock_y
	Local $x2 = $clock_x
	Local $y2 = $clock_y + 90

	Local $sIconSearchArea = string($x1) & "," & string($y1) & "," & string($x2) & "," & string($y2)

	Local $sSearchIcon = GetDiamondFromRect($sIconSearchArea) ; Contains iXStart, $iYStart, $iXEnd, $iYEnd

	; search for a clock face in the Boost window
	Local $avClockFace = findMultiple($sImgClockFaceImages, $sSearchIcon, $sSearchIcon, 0, 1000, 0, "objectname,objectpoints")

	SaveDebugImage("BoostClock", False)

	; no clockface 
	If Not IsArray($avClockFace) Or UBound($avClockFace, $UBOUND_ROWS) <= 0 Then
		Return False
	EndIf

	SetLog("Found a clock!")
	Return True
EndFunc

Func IsSuperTroop($sTroopName = "")

	For $i = 0 to $eSuperTroopCount - 1
		If $g_asSuperTroopShortNames[$i] = $sTroopName Then Return True
	Next
	
	Return False
EndFunc