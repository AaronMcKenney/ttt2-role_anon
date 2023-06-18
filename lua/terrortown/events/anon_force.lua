if SERVER then
    AddCSLuaFile()

    resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_anon.vmt")
end

if CLIENT then
	EVENT.title = "title_event_anon_force"
	EVENT.icon = Material("vgui/ttt/dynamic/roles/icon_anon.vmt")

	function EVENT:GetText()
		return {
			{
				string = "desc_event_anon_force",
				params = {
					name = self.event.inno_name
				},
				translateParams = true
			}
		}
    end
end

if SERVER then
	function EVENT:Trigger(ply)

		self:AddAffectedPlayers(
			{ply:SteamID64()},
			{ply:GetName()}
		)

		return self:Add({
			serialname = self.event.title,
			inno_name = ply:GetName()
		})
	end

	function EVENT:Serialize()
		return self.event.serialname
	end
end