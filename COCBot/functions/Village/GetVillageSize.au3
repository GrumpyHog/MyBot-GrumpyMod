; #FUNCTION# ====================================================================================================================
; Name ..........: GetVillageSize
; Description ...: Measures the size of village. After CoC October 2016 update, max'ed zoomed out village is 440 (reference!)
;                  But usually sizes around 470 - 490 pixels are measured due to lock on max zoom out.
;                  The 'zoom' has changed in the Spring 2022 update.  Prior to the update, the game screen at max'ed zoom has no 'up down'
;                  movement and only a little sideways movement.  This meant the fixed points used to 'center and measure' the village
;                  was always visible.  After the update, at max'ed zoom out, it is now possible to move both the 'tree' fixed points
;                  out of view or move the 'main' stone fixed point out of view.  The top and bottom black bars that sometimes appear
;                  at max'ed zoom are no longer present.
; Syntax ........: GetVillageSize()
; Parameters ....:
; Return values .: 0 if not identified or Array with index
;                      0 = Size of village (float)
;                      1 = Zoom factor based on 440 village size (float)
;                      2 = X offset of village center (int)
;                      3 = Y offset of village center (int)
;                      4 = X coordinate of stone
;                      5 = Y coordinate of stone
;                      6 = stone image file name
;                      7 = X coordinate of tree
;                      8 = Y coordinate of tree
;                      9 = tree image file name
; Author ........: Cosote (Oct 17th 2016)
; Modified ......: GrumpyHog (05-2022)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2022
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Global $g_bMainVillageScenerySupport = False

Func GetVillageSize($DebugLog = False, $sStonePrefix = Default, $sTreePrefix = Default, $sFixedPrefix = Default, $bOnBuilderBase = Default)

	If $sStonePrefix = Default Then $sStonePrefix = "stone"
	If $sTreePrefix = Default Then $sTreePrefix = "tree"

	Local $aResult = 0
	Local $sDirectory
	Local $stone[6] = [0, 0, 0, 0, 0, ""], $tree[6] = [0, 0, 0, 0, 0, ""]
	Local $x0, $y0, $d0, $x, $y, $x1, $y1, $right, $bottom, $a

	Local $iAdditionalX = 200
	Local $iAdditionalY = 125
	
	Local $iTreeIndex = 0

	Local $bOnClanCapitial = isOnClanCapital(True)
	
	Local $bIsOnMainBase = isOnMainVillage()
	
	$g_bOnBuilderBaseEnemyVillage = isOnBuilderBaseEnemyVillage(True)

	If $bOnBuilderBase = Default Then
		$bOnBuilderBase = isOnBuilderBase(True)
	EndIf

	If $bOnBuilderBase Or $g_bOnBuilderBaseEnemyVillage Then
		$sDirectory = @ScriptDir & "\imgxml\village\BuilderBase\"
	ElseIf $bOnClanCapitial Then
		$sDirectory = @ScriptDir & "\imgxml\village\ClanCapital\"
	ElseIf $bIsOnMainBase And Not $g_bMainVillageScenerySupport Then
		$sDirectory = @ScriptDir & "\imgxml\village\NormalVillage\" ; classic and jungle scenery support
	Else
		$sDirectory = @ScriptDir & "\imgxml\village\EnemyVillage\" ; all sceneries support
	EndIf

	Local $hTimer = TimerInit()

	Local $aStoneFiles = _FileListToArray($sDirectory, $sStonePrefix & "*.*", $FLTA_FILES)
	If @error Then
		SetLog("Error: Missing stone files (" & @error & ")", $COLOR_ERROR)
		Return $aResult
	EndIf

	Local $i, $findImage, $sArea, $a

	For $i = 1 To $aStoneFiles[0]
		$findImage = $aStoneFiles[$i]
		$a = StringRegExp($findImage, ".*-(\d+)-(\d+)-(\d*,*\d+)_.*[.](xml|png|bmp)$", $STR_REGEXPARRAYMATCH)
		If UBound($a) = 4 Then

			$x0 = $a[0]
			$y0 = $a[1]
			$d0 = StringReplace($a[2], ",", ".")

			$x1 = $x0 - $iAdditionalX
			$y1 = $y0 - $iAdditionalY
			$right = $x0 + $iAdditionalX
			$bottom = $y0 + $iAdditionalY
			$sArea = Int($x1) & "," & Int($y1) & "|" & Int($right) & "," & Int($y1) & "|" & Int($right) & "," & Int($bottom) & "|" & Int($x1) & "," & Int($bottom)
			;SetDebugLog("GetVillageSize check for image " & $findImage)
			$a = decodeSingleCoord(findImage($findImage, $sDirectory & "\" & $findImage, $sArea, 1, False))
			If $DebugLog Then SaveDebugRectImage("GetVillageSize", $x1 & "," & $y1 & "," & $right & "," & $bottom) 
			If UBound($a) = 2 Then
				$x = Int($a[0])
				$y = Int($a[1])
				SetDebugLog("Found stone image at " & $x & ", " & $y & ": " & $findImage)
				;SetLog("Found Stone image at " & $x & ", " & $y & ": " & $findImage)
				$stone[0] = $x ; x center of stone found
				$stone[1] = $y ; y center of stone found
				$stone[2] = $x0 ; x ref. center of stone
				$stone[3] = $y0 ; y ref. center of stone
				$stone[4] = $d0 ; distance to village map in pixel
				$stone[5] = $findImage
				
				Local $asStoneName = StringSplit($findImage,"-") ; get filename only
				Local $asStoneScenery = StringRight($asStoneName[1], 2) ; get extension

				SetLog("Stone Scenery : " & $asStoneScenery, $COLOR_ERROR)
				
				ExitLoop
			EndIf

		Else
			;SetDebugLog("GetVillageSize ignore image " & $findImage & ", reason: " & UBound($a), $COLOR_WARNING)
		EndIf
	Next

	If $stone[0] = 0 Then
		SetLog("GetVillageSize cannot find stone", $COLOR_WARNING)
		;Return $aResult
	EndIf
	
	SetLog("Stone search (in " & Round(TimerDiff($hTimer) / 1000, 2) & " seconds)", $COLOR_INFO)
	$hTimer = TimerInit()
		
	If $stone[0] = 0 Then
		SetLog("Load ALL tree files!")
		Local $aTreeFiles = _FileListToArray($sDirectory, $sTreePrefix & "*.*", $FLTA_FILES)
	ElseIf $asStoneScenery = "DS" Then
		Local $aTreeFiles = _FileListToArray($sDirectory, $sTreePrefix & "D*.*", $FLTA_FILES)
	Else
		Local $aTreeFiles = _FileListToArray($sDirectory, $sTreePrefix & $asStoneScenery & "*.*", $FLTA_FILES)
	EndIf

	If @error Then
		SetLog("Error: Missing tree (" & @error & ")", $COLOR_ERROR)
		Return FuncReturn($aResult)
	EndIf	
	
	For $i = 1 To $aTreeFiles[0]
		$findImage = $aTreeFiles[$i]
		$a = StringRegExp($findImage, ".*-(\d+)-(\d+)-(\d*,*\d+)_.*[.](xml|png|bmp)$", $STR_REGEXPARRAYMATCH)
		If UBound($a) = 4 Then

			$x0 = $a[0]
			$y0 = $a[1]
			$d0 = StringReplace($a[2], ",", ".")

			$x1 = $x0 - $iAdditionalX
			$y1 = $y0 - $iAdditionalY
			$right = $x0 + $iAdditionalX
			$bottom = $y0 + $iAdditionalY
			$sArea = Int($x1) & "," & Int($y1) & "|" & Int($right) & "," & Int($y1) & "|" & Int($right) & "," & Int($bottom) & "|" & Int($x1) & "," & Int($bottom)
			;SetDebugLog("GetVillageSize check for image " & $findImage)
			$a = decodeSingleCoord(findImage($findImage, $sDirectory & "\" & $findImage, $sArea, 1, False))
			If $DebugLog Then SaveDebugRectImage("GetVillageSize", $x1 & "," & $y1 & "," & $right & "," & $bottom)
			If UBound($a) = 2 Then
				$x = Int($a[0])
				$y = Int($a[1])
				SetDebugLog("Found tree image at " & $x & ", " & $y & ": " & $findImage)
				;SetLog("Found tree image at " & $x & ", " & $y & ": " & $findImage)
				$tree[0] = $x ; x center of tree found
				$tree[1] = $y ; y center of tree found
				$tree[2] = $x0 ; x ref. center of tree
				$tree[3] = $y0 ; y ref. center of tree
				$tree[4] = $d0 ; distance to village map in pixel
				$tree[5] = $findImage
				
				Local $asTreeName = StringSplit($findImage,"-") ; get filename only
				Local $sTreeName = $asTreeName[1]
				If StringInStr($sTreeName, "2tree") Then
					SetLog("Using 2tree")
					$sTreeName = StringReplace($sTreeName, "2", "") ; remove 2 in 2tree
					$iTreeIndex = 5
				EndIf
					
				$g_iTree = Int(Eval("e" & $sTreeName))
				;If $DebugLog Then 
				SetLog($sTreeName & " " & $g_iTree, $COLOR_INFO)
				ExitLoop
			EndIf

		Else
			;SetDebugLog("GetVillageSize ignore image " & $findImage & ", reason: " & UBound($a), $COLOR_WARNING)
		EndIf
	Next

	If $tree[0] = 0 Then
		SetLog("GetVillageSize cannot find tree", $COLOR_WARNING)
		;Return $aResult
	EndIf

	SetLog("Tree search (in " & Round(TimerDiff($hTimer) / 1000, 2) & " seconds)", $COLOR_INFO)
	$hTimer = TimerInit()

	Local $iX_Exp = 0
	Local $iY_Exp = 0
	Local $z = 1	; for centering only
	Local $c = 0	; for centering only
	Local $a = 0, $b = 0, $iRefSize = 0

	; Failed to locate Stone Or Tree ; zoom out
	If $stone[0] = 0 And $tree[0] = 0 Then
		SetLog("GetVillageSize cannot find stone or tree", $COLOR_WARNING)
		Return $aResult
	ElseIf $stone[0] = 0 And $tree[0] > 0 Then ; calculate offset using trees
		$iX_Exp = $tree[2]
		$iY_Exp = $tree[3]
		ConvertVillagePos($iX_Exp, $iY_Exp, $z)
		$x = $tree[0] - $iX_Exp
		$y = $tree[1] - $iY_Exp
		SetLog("Found Tree! Offset : " & $x & ", " & $y, $COLOR_INFO)
	ElseIf $tree[0] = 0 And $stone[0] > 0 Then ; calculate offset using stone
		$iX_Exp = $stone[2]
		$iY_Exp = $stone[3]
		ConvertVillagePos($iX_Exp, $iY_Exp, $z)
		$x = $stone[0] - $iX_Exp
		$y = $stone[1] - $iY_Exp
		SetLog("Found Stone! Offset : " & $x & ", " & $y, $COLOR_INFO)
	Else
		; calculate village size, see https://en.wikipedia.org/wiki/Pythagorean_theorem
		$a = $tree[0] - $stone[0]
		$b = $stone[1] - $tree[1]
		$c = Sqrt($a * $a + $b * $b) - $stone[4] - $tree[4]

		$iRefSize = $g_afRefVillage[$g_iTree][$iTreeIndex]
		
		$z = $c / $iRefSize

		Local $stone_x_exp = $stone[2]
		Local $stone_y_exp = $stone[3]
		ConvertVillagePos($stone_x_exp, $stone_y_exp, $z) ; expected x, y position of stone
		$x = $stone[0] - $stone_x_exp
		$y = $stone[1] - $stone_y_exp

		SetLog("Found Stone and Tree!", $COLOR_INFO);
		SetLog("Village Size : " & $c, $COLOR_INFO)
		SetLog("Zoom Factor : " & $z, $COLOR_INFO)
		SetLog("Offset : " & $x & ", " & $y, $COLOR_INFO)
		If $DebugLog Then SetDebugLog("GetVillageSize measured: " & $c & ", Zoom factor: " & $z & ", Offset: " & $x & ", " & $y, $COLOR_INFO)
	EndIf

	Dim $aResult[11]
	$aResult[0] = $c
	$aResult[1] = $z
	$aResult[2] = $x
	$aResult[3] = $y
	$aResult[4] = $stone[0]
	$aResult[5] = $stone[1]
	$aResult[6] = $stone[5]
	$aResult[7] = $tree[0]
	$aResult[8] = $tree[1]
	$aResult[9] = $tree[5]
	$aResult[10] = $iRefSize
	
	$g_aVillageSize[0] = $aResult[0]
	$g_aVillageSize[1] = $aResult[1]
	$g_aVillageSize[2] = $aResult[2]
	$g_aVillageSize[3] = $aResult[3]
	$g_aVillageSize[4] = $aResult[4]
	$g_aVillageSize[5] = $aResult[5]
	$g_aVillageSize[6] = $aResult[6]
	$g_aVillageSize[7] = $aResult[7]
	$g_aVillageSize[8] = $aResult[8]
	$g_aVillageSize[9] = $aResult[9]
	
	SetLog("GetVillageSize calculations (in " & Round(TimerDiff($hTimer) / 1000, 2) & " seconds)", $COLOR_INFO)
	
	Return FuncReturn($aResult)
EndFunc   ;==>GetVillageSize

Func UpdateGlobalVillageOffset($x, $y)

	Local $updated = False

	If $g_sImglocRedline <> "" Then

		Local $newReadLine = ""
		Local $aPoints = StringSplit($g_sImglocRedline, "|", $STR_NOCOUNT)

		For $sPoint In $aPoints

			Local $aPoint = GetPixel($sPoint, ",")
			$aPoint[0] += $x
			$aPoint[1] += $y

			If StringLen($newReadLine) > 0 Then $newReadLine &= "|"
			$newReadLine &= ($aPoint[0] & "," & $aPoint[1])

		Next

		; set updated red line
		$g_sImglocRedline = $newReadLine

		$updated = True
	EndIf

	If $g_aiTownHallDetails[0] <> 0 And $g_aiTownHallDetails[1] <> 0 Then
		$g_aiTownHallDetails[0] += $x
		$g_aiTownHallDetails[1] += $y
		$updated = True
	EndIf
	If $g_iTHx <> 0 And $g_iTHy <> 0 Then
		$g_iTHx += $x
		$g_iTHy += $y
		$updated = True
	EndIf

	ConvertInternalExternArea()

	Return $updated

EndFunc   ;==>UpdateGlobalVillageOffset

; Based on grumpy mod
Func CenterVillage($iX, $iY, $iOffsetX, $iOffsetY, $bLayOut = False)
	Local $aScrollPos[2] = [0, 0]

	; If IsCoordSafe($iX, $iY) Then
		; $aScrollPos[0] = $iX
		; $aScrollPos[1] = $iY
	; Else
		$aScrollPos[0] = $aCenterHomeVillageClickDrag[0]
		$aScrollPos[1] = $aCenterHomeVillageClickDrag[1]
	; EndIf

	If $g_bDebugSetlog Then SetDebugLog("CenterVillage at point : " & $aScrollPos[0] & ", " & $aScrollPos[1] & " Offset : " & $iOffsetX & ", " & $iOffsetY, $COLOR_INFO)
 	If $g_bDebugImageSave Then SaveDebugPointImage("CenterVillage", $aScrollPos)
	ClickAway()
	Local $iOffsetXFixed = _Max($iOffsetX, Random(95, 100, 1))
	If $bLayOut = True Then
		; It is like grumpy mod but the X offset is inverted in tree case
		ClickDrag($aScrollPos[0], $aScrollPos[1], $aScrollPos[0] + $iOffsetXFixed, $aScrollPos[1] - $iOffsetY)
	Else
		; 57, -75
		ClickDrag($aScrollPos[0], $aScrollPos[1], $aScrollPos[0] - $iOffsetXFixed, $aScrollPos[1] - $iOffsetY)
	EndIf
	If _Sleep(1000) Then Return
EndFunc

Func IsCoordSafe($x, $y)
	Local $bResult = True
	Local $bIsOnMainBase = isOnMainVillage()
	If $bIsOnMainBase Then SetLog("In the Main Village!")
	
	SetLog("Testing Coords : " & $x & "," & $y)
	
	If $x < 82 And $y > 487 And $bIsOnMainBase Then ; coordinates where the game will click on the War Button (safe margin)
	;If $x < 82 And $y > 487 Then ; coordinates where the game will click on the War Button (safe margin)
		If $g_bDebugSetlog Then SetDebugLog("Too close to War Button")
		SetLog("Too close to War Button")
		$bResult = False
	ElseIf $x < 68 And $y > 316 Then ; coordinates where the game will click on the CHAT tab (safe margin)
		If $g_bDebugSetlog Then SetDebugLog("Too close to CHAT Tab")
		SetLog("Too close to CHAT Tab")
		$bResult = False
	ElseIf $y < 63 Then ; coordinates where the game will click on the BUILDER button or SHIELD button (safe margin)
		If $g_bDebugSetlog Then SetDebugLog("Too close to Builder and Shield")
		SetLog("Too close to Builder and Shield")
		$bResult = False
	ElseIf $x > 692 And $y > 156 And $y < 210 Then ; coordinates where the game will click on the GEMS button (safe margin)
		If $g_bDebugSetlog Then SetDebugLog("Too close to GEMS")
		SetLog("Too close to GEMS")
		$bResult = False
	EndIf
	
	If _Sleep(500) Then Return
	
	Return $bResult
EndFunc
