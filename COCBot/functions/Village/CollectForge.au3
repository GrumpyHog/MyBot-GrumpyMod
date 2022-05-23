; #FUNCTION# ====================================================================================================================
; Name ..........: CollectForge
; Description ...:
; Syntax ........: CollectForge()
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

; ImgLoc ForgeFull 185, 580, 520, 730
; Click ForgeFull
; IsWindow Forge 330, 180, 520, 225
; ImgLoc CollectBtn 115, 370, 750, 420
; Loop
; Click Button
; If TH14 and loop 4 times click drag
; imlog CollectBtn
; exit window 737, 204

Func CollectForge($bTest = False)
	If Not $g_bChkCollectForge Then Return

	Local $sImgForgeFullButton = @ScriptDir & "\imgxml\Resources\Forge\ForgeFullButton*"
	Local $sImgForgeCollectButton = @ScriptDir & "\imgxml\Resources\Forge\ForgeCollectButtons\"
	Local $sImgForgeWindow = @ScriptDir & "\imgxml\Resources\Forge\ForgeWindow*"
	Local $sForgeFullArea = GetDiamondFromRect("185,580,520,730")
	Local $sForgeCollectArea = GetDiamondFromRect("115,370,750,420")
	Local $sForgeWindowArea = GetDiamondFromRect("330,180,520,225")
	Local $aiCloseButton[2] = [737, 204]

	;checkMainScreen(True, False)
	
	ClickAway()
	
	If _Sleep(500) Then Return False
	
	Local $aiForgeFullButton = decodeSingleCoord(findImage("ForgeFullButton", $sImgForgeFullButton, $sForgeFullArea, 1, True))

	If Not IsArray($aiForgeFullButton) Or UBound($aiForgeFullButton, $UBOUND_ROWS) < 2 Then
		SetLog("Failed to locate Forge Full Button", $COLOR_INFO)
		SaveDebugRectImage("CollectForge","185,580,520,730");
		Return False
	EndIf	

	If _Sleep(250) Then Return

	ClickP($aiForgeFullButton)

	If _Sleep(250) Then Return

	If Not IsWindowOpen($sImgForgeWindow, 10, 200, $sForgeWindowArea) Then
		SetLog("Forge window did not open, exit", $COLOR_ERROR)
		Return False
	EndIf

	Local $avForgeCollectButton = findMultiple($sImgForgeCollectButton, $sForgeCollectArea, $sForgeCollectArea, 0, 1000, 1, "objectpoints", True)

	If IsArray($avForgeCollectButton) And UBound($avForgeCollectButton, $UBOUND_ROWS) > 0 Then
		For $i = 0 To UBound($avForgeCollectButton, $UBOUND_ROWS) - 1
			Local $avForgeCollectTemp = $avForgeCollectButton[$i]
			
			If isArray($avForgeCollectTemp) Then
				Local  $aiForgeCollectButton = decodeSingleCoord($avForgeCollectTemp[0])
				
				SetLog("Found ForgeCollectButton at : " & $aiForgeCollectButton[0] & "," & $aiForgeCollectButton[1], $COLOR_INFO)
				
				If Not $bTest Then ClickP($aiForgeCollectButton)
			EndIf
				
			If _Sleep(250) Then Return
		Next
	EndIf
	
	ClickP($aiCloseButton)
	
	If _Sleep(250) Then Return
	
	Return True
EndFunc
