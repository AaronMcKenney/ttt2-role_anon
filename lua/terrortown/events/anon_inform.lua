if SERVER then
    AddCSLuaFile()

    resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_anon.vmt")
end

if CLIENT then
	EVENT.title = "title_event_anon_inform"
	EVENT.icon = Material("vgui/ttt/dynamic/roles/icon_anon.vmt")

	function EVENT:GetText()
		return {
			{
				string = "desc_event_anon_inform",
				params = {
					name1 = self.event.anon_receiver_name,
					name2 = self.event.anon_sender_name
				},
				translateParams = true
			}
		}
    end
end

if SERVER then
	function EVENT:Trigger(ply1, ply2)

		self:AddAffectedPlayers(
			{ply1:SteamID64(), ply2:SteamID64()},
			{ply1:GetName(), ply2:GetName()}
		)

		return self:Add({
			serialname = self.event.title,
			anon_receiver_name = ply1:GetName(),
			anon_sender_name = ply2:GetName()
		})
	end

	function EVENT:Serialize()
		return self.event.serialname
	end
end