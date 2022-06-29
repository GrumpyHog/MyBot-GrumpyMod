; #FUNCTION# ====================================================================================================================
; Name ..........: Forge
; Description ...:
; Syntax ........: 
; Parameters ....:
; Return values .: Bool
; Author ........: GrumpyHog (05-2022)
; Modified ......:
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2019
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func OpenForgeWindow($bTest = False)
	Local $sForgeSearchArea = GetDiamondFromRect("185,580,520,730")
	Local $sImgForgeWindow = @ScriptDir & "\imgxml\Resources\Forge\ForgeWindow*"
	Local $sForgeWindowArea = GetDiamondFromRect("330,180,520,225")

	
	If $bTest Then
		Local $sImgForgeButton = @ScriptDir & "\imgxml\Resources\Forge\ForgeButton*"
	Else
		Local $sImgForgeButton = @ScriptDir & "\imgxml\Resources\Forge\ForgeFullButton*"
	EndIf

	; clear any BuildingInfo
	ClickAway()
	
	If _Sleep(250) Then Return False
	
	Local $aiForgeButton = decodeSingleCoord(findImage("ForgeFullButton", $sImgForgeButton, $sForgeSearchArea, 1, True))

	If Not IsArray($aiForgeButton) Or UBound($aiForgeButton, $UBOUND_ROWS) < 2 Then
		SetLog("Failed to locate Forge Button", $COLOR_INFO)
		SaveDebugRectImage("OpenForgeWindow","185,580,520,730");
		Return False
	EndIf	

	If _Sleep(250) Then Return

	ClickP($aiForgeButton)

	If _Sleep(250) Then Return

	If Not IsWindowOpen($sImgForgeWindow, 10, 200, $sForgeWindowArea) Then
		SetLog("Forge window did not open, exit", $COLOR_ERROR)
		Return False
	EndIf

	If _Sleep(250) Then Return

	Return True
EndFunc


Func Forge($bTest = False)
	If Not $g_bChkCollectCapitalGold Then Return

	Local $aiCloseButton[2] = [737, 204]
	; For Crafting....
	VillageReport(True, True)

	If Not OpenForgeWindow($bTest) Then Return False

	Local $iPage = 0

	CollectCapitalGold($iPage, $bTest)
	
	If _Sleep(250) Then Return

	Local $iActiveBuilderBuilder = ForgeActiveBuilders($iPage, $bTest)
	
	SetLog("Current ActiveBuilder Builders : " & $iActiveBuilderBuilder, $COLOR_INFO)
	
	If $iActiveBuilderBuilder < $g_iReserveCraftBuilder Then CraftCapitalGold($iPage, $bTest)
	
	ClickP($aiCloseButton)
	
	If _Sleep(250) Then Return
	
	VillageReport(True, True)
	
EndFunc

; First Craft slot is free and can be collect every 24h, 
Func CollectCapitalGold(ByRef $iPage, $bTest = False)
	If Not $g_bChkCollectCapitalGold Then Return

	Local $sImgForgeCollectButton = @ScriptDir & "\imgxml\Resources\Forge\ForgeCollectButtons\ForgeCollectButton*"
	Local $sForgeCollectArea = GetDiamondFromRect("115,384,750,666")
	Local $bExit = False

	While Not $bExit
		Local $avForgeCollectButtons = decodeMultipleCoords(findImage("ForgeCollectButton", $sImgForgeCollectButton, $sForgeCollectArea, 4, True), Default, Default, 0)
		
		;_ArrayDisplay($avForgeCollectButtons)

		If IsArray($avForgeCollectButtons) Then
			For $aiForgeCollectButton In $avForgeCollectButtons
			
			;_ArrayDisplay($aiForgeCraftButton)
				SetLog("Found ForgeCollectButton at : " & $aiForgeCollectButton[0] & "," & $aiForgeCollectButton[1], $COLOR_INFO)
					
				If Not $bTest Then ClickP($aiForgeCollectButton)

				If _Sleep(3000) Then Return False
			Next
		Else
			SetLog("Failed to locate Forge Collect Button", $COLOR_INFO)
		EndIf

		If $g_iTownHallLevel = 14 And $iPage = 0 Then
			DragForgeIfNeeded($iPage)
		Else
			$bExit = True
		EndIf
	WEnd
	
	If _Sleep(250) Then Return
	
	Return True
EndFunc

; count the number of builder(s) working in the Forge
Func ForgeActiveBuilders(ByRef $iPage, $bTest = False)
	Local $sImgForgeActiveBuilderButton = @ScriptDir & "\imgxml\Resources\Forge\ForgeActiveBuilderButton*" ; look for the GEM 
	Local $sForgeCollectArea = GetDiamondFromRect("115,384,750,666")

	Local $iActiveBuilder = 0

	; If TH14 drag to reveal Slots 2 - 5
	If $g_iTownHallLevel = 14 And $iPage = 0 Then DragForgeIfNeeded($iPage)

	Local $avForgeActiveBuilderButtons = decodeMultipleCoords(findImage("ForgeCollectButton", $sImgForgeActiveBuilderButton, $sForgeCollectArea, 4, True), Default, Default, 0)

	If IsArray($avForgeActiveBuilderButtons) Then
		$iActiveBuilder = UBound($avForgeActiveBuilderButtons, 1)
		SetLog("Number of Active Builders : " & $iActiveBuilder, $COLOR_INFO)
	Else
		SetLog("Failed to locate ForgeActiveBuilderButton", $COLOR_INFO)
	EndIf

	If _Sleep(250) Then Return
	
	Return $iActiveBuilder
EndFunc

;Craft - some thoughts
; - need resources management?
; - need time management? do we to visit forge every loop? only we collect?
; - max 4 builders - TH9 1, TH14 - 4 (clickdrag at TH14) - builder management?
; - start crafting window - Elixir, Gold, DE, Builder Gold, Builder Elixir
; - icon grey out with 'a lock icon' if not available to TownHall
; - cost text white if resources sufficient to craft, red if not
; - use ocr to read cost or use array to store cost?  ocr requires pressing icon to show cost use array allows resources management similar to wall upgrade
; - builder piority wall - heroes - craft?
; - function need to be after BB to get updated resources

; collect
; check townhall - exit < 9
; check no builder free $iAvailBldr = $g_iFreeBuilderCount - ($g_bAutoUpgradeWallsEnable And $g_bUpgradeWallSaveBuilder ? 1 : 0) - ReservedBuildersForHeroes()
; check resources
; upgrade[$eCraftCount]=[F,F,F,F,F]
; if current_resources > g_iSetCraftMinimum Then upgrade = True
; etc
; etc
; if all upgrade 0 then exit
; look for free craft slot
; loop
; 	click craft
;	loop thro icon
;	builder free?
;	upgrade?
;   then click craft
;	else next icon
;
Func CraftCapitalGold(ByRef $iPage, $bTest = False)

	If Not $g_bChkCraftCapitalGold Then Return False
	
	If $g_iTownHallLevel < 9 Then
		SetLog("Need Townhall 9+ to Craft Capital Gold!", $COLOR_WARNING)
		Return False
	EndIf
	
	; builder count should be up to date as entering from main loop
	Local $iAvailBldr = $g_iFreeBuilderCount - ($g_bAutoUpgradeWallsEnable And $g_bUpgradeWallSaveBuilder ? 1 : 0) - ReservedBuildersForHeroes()

	SetLog("Builders : " & $iAvailBldr, $COLOR_INFO)

	If $iAvailBldr <= 0 Then
		SetLog("No builder available to Craft Capital Gold!", $COLOR_INFO)
		Return False
	EndIf

	If $g_iReserveCraftBuilder <= 0 Then
		SetLog("No builder reserve to Craft Capital Gold!", $COLOR_INFO)
		Return False
	EndIf

	Local $iCraftCost[$eCraftCount] = [99999999, 99999999, 99999999, 99999999, 99999999]
	Local $iResources[$eCraftCount] = [99999999, 99999999, 99999999, 99999999, 99999999] ; current resources
	
	; confirm resources and user setting
	If $g_iTownHallLevel >= 9 Then
		; Gold
		$iCraftCost[$eCraftGold] = $g_iCraftElixirGoldCost[$g_iTownHallLevel - 9]
		$iResources[$eCraftGold] = $g_aiCurrentLoot[$eLootGold]

		; Elixir
		$iCraftCost[$eCraftElixir] = $g_iCraftElixirGoldCost[$g_iTownHallLevel - 9]
		$iResources[$eCraftElixir] = $g_aiCurrentLoot[$eLootElixir]
		
		; Dark Elixir
		If $g_iTownHallLevel >=13 Then
			$iCraftCost[$eCraftDarkElixir] = $g_iCraftDarkElixirCost[$g_iTownHallLevel - 13]
			$iResources[$eCraftDarkElixir] = $g_aiCurrentLoot[$eLootDarkElixir]
		EndIf
	EndIf
	
	If $g_iBuilderHallLevel >= 8 Then
		; Builder Gold
		$iCraftCost[$eCraftBuilderGold] = $g_iCraftBuilderElixirGoldCost[$g_iBuilderHallLevel - 8]
		$iResources[$eCraftBuilderGold] = $g_aiCurrentLootBB[$eLootGoldBB]
	
		; Builder Gold
		$iCraftCost[$eCraftBuilderElixir] = $g_iCraftBuilderElixirGoldCost[$g_iBuilderHallLevel - 8]
		$iResources[$eCraftBuilderElixir] = $g_aiCurrentLootBB[$eLootElixirBB]
	EndIf

	; Do not use more the Reserved Builders
	If $iAvailBldr >= $g_iReserveCraftBuilder Then
		Local $iFreeBuilder = $g_iReserveCraftBuilder
	Else
		Local $iFreeBuilder = $iAvailBldr
	EndIf
		
	Local $sImgForgeCraftButton = @ScriptDir & "\imgxml\Resources\Forge\ForgeCraftButtons\ForgeCraftButton*"
	Local $sForgeCraftArea = GetDiamondFromRect("115,370,750,420")
	Local $aiCloseCraftWindowButton[2] = [645, 227]	

	; If TH14 drag to reveal Slots 2 - 5
	If $g_iTownHallLevel = 14 And $iPage = 0 Then DragForgeIfNeeded($iPage)

	Local $avForgeCraftButtons = decodeMultipleCoords(findImage("ForgeCraftButton", $sImgForgeCraftButton, $sForgeCraftArea, 4, True), Default, Default, 0)
	
	;_ArrayDisplay($avForgeCraftButtons)
	Local $aiTrackResources[$eCraftCount] = [1, 1, 1, 1, 1] ; track resources which not longer meet the minimum requirement
	
	If IsArray($avForgeCraftButtons) Then
		
		For $aiForgeCraftButton In $avForgeCraftButtons ; loop thro' each craft slot
		;_ArrayDisplay($aiForgeCraftButton)
			
			If $iFreeBuilder > 0 And _ArrayMax($aiTrackResources) > 0 Then ; available builder
				SetLog("Free builder : " & $iFreeBuilder, $COLOR_INFO)
				SetLog("Found ForgeCraftButton at : " & $aiForgeCraftButton[0] & "," & $aiForgeCraftButton[1], $COLOR_INFO)
				ClickP($aiForgeCraftButton)
				; select resources to craft.....
				If _Sleep(3000) Then Return False
				; IsWindow....
					Local $aCraftIconDisable = [210, 275, 0xC7C7C7, 10] ; grey icon background
					Local $iResourcesButton[2] = [210, 275]
					Local $iIconDistance = 92
				; loop thro' each resources icon
				For $i = 0 To $eCraftCount - 1
					If Not _CheckPixel($aCraftIconDisable, True, Default, "CraftCapitalGold") Then ; Craft icon NOT disabled
						If $iResources[$i] > ($g_iSetCraftMinimum[$i] + $iCraftCost[$i]) Then ; resources limit exceeded
							SetLog("Village Resources: " & $iResources[$i] & "  Minimum : " & ($g_iSetCraftMinimum[$i] + $iCraftCost[$i]), $COLOR_INFO)
							If $i > 0 Then ; click on icon except 1st
								SetLog("Click Resources button : " & $i)				
								ClickP($iResourcesButton)
								If _Sleep(250) Then Return
							EndIf
							SetLog("Click Craft button for Icon : " & $i, $COLOR_INFO)
							If Not $bTest Then Click(435, 485) ; click Craft button - craft window will closed
							; reduce resources
							$iResources[$i] -= $iCraftCost[$i]
							$iFreeBuilder -= 1
							If _Sleep(250) Then Return
							If $bTest Then
								If _Sleep(3000) Then Return
								ClickP($aiCloseCraftWindowButton)
							EndIf
							ExitLoop ; exit For...Next loop
						Else
							$aiTrackResources[$i] = 0
							SetLog("Not enough resources : "& $g_asCraftResName[$i] & " - " & $iResources[$i] & "  Minimum : " & ($g_iSetCraftMinimum[$i] + $iCraftCost[$i]), $COLOR_INFO)
						EndIf
					Else
						SetLog("Crafting Icon Locked : " & $g_asCraftResName[$i], $COLOR_INFO)
					EndIf
				

					If _Sleep(250) Then Return
									
					If $bTest Then
						If _Sleep(3000) Then Return
					EndIf
												
					; move to next icon
					$aCraftIconDisable[0] += $iIconDistance
					$iResourcesButton[0] += $iIconDistance

				Next

				If _Sleep(250) Then Return
				
				If $bTest Then
					If _Sleep(3000) Then Return
				EndIf
									
				ClickP($aiCloseCraftWindowButton)
			Else
				SetLog("No Free builder!", $COLOR_INFO)
			EndIf
		Next
		
	Else
		SetLog("Failed to locate craft button", $COLOR_INFO)
	EndIf		
EndFunc

Func DragForgeIfNeeded(ByRef $iPage)
	Local $iDragX1 = Random(110,500,1)
	Local $iDragY1 = Random(255,365,1)
	Local $iDragY2 = Random(255,365,1)
	
	If $iPage = 0 Then
		ClickDrag($iDragX1,$iDragY1,$iDragX1-125,$iDragY2)
		$iPage += 1
	EndIf	
EndFunc

Func ReservedBuildersForForge()
	Local $iBuilder = 0
	
	If $g_bChkCraftCapitalGold Then $iBuilder = $g_iReserveCraftBuilder
	
	Return $iBuilder
EndFunc