AddCSLuaFile();

TOOL.Category = "Developers"
TOOL.Name = "#tool.relative_positioner.name"
TOOL.Description = "#tool.relative_positioner.description"
TOOL.Information = {
	{name = "left", stage = 0, icon = "gui/lmb.png"},
	{name = "right", stage = 0, icon = "gui/rmb.png"},
	{name = "left_next", stage = 1, icon = "gui/lmb.png"},
	{name = "reload" }
};

TOOL.EntityClipboard = {}
TOOL.ClientConVar = {
	drawtextside = 1
}

local ConVarsDefault = TOOL:BuildConVarList()
local clrDrawText = Color( 255, 255, 255 )
local clrDrawLine = Color( 255, 180, 0 )
local clrHalo = Color( 255, 180, 0 )
local clrOutputTag = Color( 255, 0, 0 )
local clrOutputText = Color( 255, 255, 255 )
local clrOutputVal = Color( 255, 180, 0 )

/*
	Ladder Creation
*/
function TOOL:LeftClick( trTrace )
	local eEntity = trTrace.Entity
	if not IsValid( eEntity ) then return end

	if self:GetStage() == 0 then 
		self:DeclareParentEntity( eEntity )
	elseif self:GetStage() == 1 then 
		self:DeclareChildEntity( eEntity )
	end

	return true
end

-- Clear Entity Clipboard
function TOOL:RightClick( tTrace )
	self.EntityClipboard = {}

	print("Clipboard Cleared")

	return true
end

function TOOL:Reload()
	if self.NextReload and self.NextReload > CurTime() then return end

	if IsValid( self.EntityClipboard.Parent ) and IsValid( self.EntityClipboard.Child ) then
		local eParent = self.EntityClipboard.Parent
		local eChild = self.EntityClipboard.Child
		
		local vParentWorldPos = eParent:GetPos()
		local aParentWorldAngles = eParent:GetAngles()
		local sParentWorldPos = FormatVectorOrAngle( vParentWorldPos )
		local sParentWorldAngles = FormatVectorOrAngle( aParentWorldAngles )
		local vChildWorldPos = eChild:GetPos()
		local aChildWorldAngles = eChild:GetAngles()
		local vChildRelativePos = eParent:WorldToLocal( eChild:GetPos() )
		local aChildRelativeAngles = eParent:WorldToLocalAngles( eChild:GetAngles() )
		local sChildWorldPos = FormatVectorOrAngle( vChildWorldPos )
		local sChildWorldAngles = FormatVectorOrAngle( aChildWorldAngles )
		local sChildRelativePos = FormatVectorOrAngle( vChildRelativePos )
		local sChildRelativeAngles = FormatVectorOrAngle( aChildRelativeAngles )

		chat.AddText(
			Color( 255, 0, 0 ),
			"[ Relative Positioner ] ",
			Color( 255, 255, 255 ),
			" You have copied the angles/vectors to console!"
		)

		MsgC( clrOutputTag, "========================================\n" )
		MsgC( clrOutputTag, "[ Relative Positioner Tool - Output ]\n" )
		MsgC( clrOutputTag, "========================================\n" )

		MsgC( clrOutputText, "Parent World Position: ", clrOutputVal, sParentWorldPos, "\n" )
		MsgC( clrOutputText, "Parent World Angles: ", clrOutputVal, sParentWorldAngles, "\n" )

		MsgC( clrOutputText, "Child World Position: ", clrOutputVal, sChildWorldPos, "\n" )
		MsgC( clrOutputText, "Child World Angles: ", clrOutputVal, sChildWorldAngles, "\n" )

		MsgC( clrOutputText, "Child Relative Position (Local to Parent): ", clrOutputVal, sChildRelativePos, "\n" )
		MsgC( clrOutputText, "Child Relative Angles (Local to Parent): ", clrOutputVal, sChildRelativeAngles, "\n" )

		MsgC( clrOutputText, "\n\n" )
		MsgC( clrOutputVal, 'NOTE: Use the "Local to Parent" vectors/coordinates via ent:LocalToWorld(...) in your script!\n' )
	end

	self.NextReload = CurTime() + 2
end

function TOOL:Holster()
	self:ClearObjects()
	self:SetStage(0)
end

function TOOL:DeclareParentEntity( eEntity )
	self.EntityClipboard = {}
	self.EntityClipboard.Parent = eEntity

	print("Parent Declared!")
	self:SetStage( 1 )
end

function TOOL:DeclareChildEntity( eEntity )
	self.EntityClipboard.Child = eEntity

	print("Child Declared!")
	self:SetStage( 0 )
end

function TOOL:GetParent()
	return self.EntityClipboard.Parent
end

function TOOL:GetChild()
	return self.EntityClipboard.Child
end

if SERVER then return end

/*
	Client Hooks
*/
hook.Add( "Think", "Tool.Relative_Positioner.VerifyEntIntegrities", function()
	local TOOL = LocalPlayer():GetTool( "relative_positioner" )
	if not TOOL then return end
	if next( TOOL.EntityClipboard ) == nil then return end

	if TOOL.EntityClipboard.Child then
		if not IsValid( TOOL.EntityClipboard.Parent ) then
			chat.AddText(
				Color( 255, 0, 0 ),
				"[ Relative Positioner ] ",
				Color( 255, 255, 255 ),
				"Unable to find the parent. Clearing the clipboard!"
			)

			TOOL.EntityClipboard = {}
		end

		if not IsValid( TOOL.EntityClipboard.Child ) then
			TOOL.EntityClipboard.Child = nil
		end
	end
end )

function GetTool()
	local ply = LocalPlayer()
	if not IsValid(ply) then return false end

	return ply:GetTool( "relative_positioner" ) or false
end

function FormatVectorOrAngle( vValue )
	if isvector(vValue) then
		return string.format( "Vector(%d, %d, %d)", vValue.x, vValue.y, vValue.z )
	elseif isangle(vValue) then
		return string.format( "Angle(%d, %d, %d)", vValue.p, vValue.y, vValue.r )
	end

	return tostring(vValue)
end

hook.Add( "PreDrawHalos", "Tool.Relative_Positioner.Halos", function()
	local TOOL = GetTool()
	if not TOOL or not TOOL.EntityClipboard then return end
	if next( TOOL.EntityClipboard ) == nil then return end

	halo.Add( TOOL.EntityClipboard, clrHalo, 2, 2, 4, true )
end )

hook.Add( "PostDrawTranslucentRenderables", "Tool.Relative_Positioner.ESP", function()
	local TOOL = GetTool( "relative_positioner" )
	if not TOOL or not TOOL.EntityClipboard then return end
	if next( TOOL.EntityClipboard ) == nil then return end

	local pPlayer = LocalPlayer()
	if not IsValid( pPlayer ) then return end

	local aPlayerAngles = pPlayer:EyeAngles()
	local aTextAngles = Angle( 0, aPlayerAngles.y - 90, 90 )

	local iSide = TOOL:GetClientNumber( "drawtextside", 1 )

	-- We're only running a loop on 2 entities, this is fine...
	for sType, eEntity in pairs( TOOL.EntityClipboard ) do
		if not IsValid( eEntity ) then continue end

		local mins = eEntity:OBBMins()
		local maxs = eEntity:OBBMaxs()
		local center = eEntity:OBBCenter()
		local vTextPos = eEntity:LocalToWorld( Vector( center.x, center.y, maxs.z + 15 ) )

		if iSide == 2 then
			vTextPos = eEntity:LocalToWorld( Vector( center.x, center.y, mins.z - 8 ) )
		elseif iSide == 3 then
			vTextPos = eEntity:LocalToWorld( Vector( mins.x - 20, center.y, center.z ) )
		elseif iSide == 4 then
			vTextPos = eEntity:LocalToWorld( Vector( maxs.x + 20, center.y, center.z ) )
		end

		local vEntPos = eEntity:GetPos()
		local aEntAngles = eEntity:GetAngles()
		local sEntPos = FormatVectorOrAngle( vEntPos )
		local sEntAngles = FormatVectorOrAngle( aEntAngles )

		local sWorldToLocal = ""
		local sWorldToLocalAngles = ""

		local eParent = TOOL.EntityClipboard.Parent

		if sType == "Child" then
			if IsValid( eParent ) then
				local vWorldToLocal = eParent:WorldToLocal( vEntPos )
				local vWorldToLocalAngles = eParent:WorldToLocalAngles( aEntAngles )
				sWorldToLocal = FormatVectorOrAngle( vWorldToLocal )
				sWorldToLocalAngles = FormatVectorOrAngle( vWorldToLocalAngles )
			else
				sWorldToLocal = "No Parent Entity Found"
				sWorldToLocalAngles = "No Parent Entity Found"
			end
		end

		local clrDrawText = Color( 255, 255, 255 )

		cam.Start3D2D( vTextPos, aTextAngles, 0.1 )
			draw.SimpleText( "[ " .. string.upper( sType ) .. " ]", "Trebuchet24", 0, 0, clrDrawText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( "Position: " .. sEntPos, "Trebuchet24", 0, 25, clrDrawText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( "Angles: " .. sEntAngles, "Trebuchet24", 0, 50, clrDrawText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			if sType == "Child" and IsValid( eParent ) then
				draw.SimpleText( "Relative Position: " .. sWorldToLocal, "Trebuchet24", 0, 75, clrDrawText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				draw.SimpleText( "Relative Angles: " .. sWorldToLocalAngles, "Trebuchet24", 0, 100, clrDrawText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end
		cam.End3D2D()

		if sType == "Child" and IsValid( eParent ) then
			render.DrawLine( eParent:GetPos(), vEntPos, clrDrawLine, true )
		end
	end
end )

/*
	Control Panel
*/

function TOOL.BuildCPanel( dPanel )
	dPanel:Help( "#tool.relative_positioner.desc" )
	dPanel:ToolPresets( "slider", ConVarsDefault )
	dPanel:NumSlider( "#tool.relative_positioner.drawTextSide", "relativepositioner_drawtextside", 1, 4, 0 )
end

/*
	Language strings
*/

if (CLIENT) then
	language.Add("tool.relative_positioner.name", "Relative Positioner")
	language.Add("tool.relative_positioner.left", "Select entity to designate as origin.")
	language.Add("tool.relative_positioner.right", "Clear entity clipboard.")
	language.Add("tool.relative_positioner.left_next", "Select entity to designate as the relative to the origin.")
	language.Add("tool.relative_positioner.reload", "Clear Clipboard")
	language.Add("tool.relative_positioner.desc", "View the position of an Entity based off another Entity's world position.")
	language.Add("tool.relative_positioner.drawTextSide", "Draw Text Side")
	language.Add("tool.relative_positioner.drawTextSide_desc", "Which side of the Entity to draw the text on. [ 1 = Top, 2 = Bottom, 3 = Left, 4 = Right ]")
end