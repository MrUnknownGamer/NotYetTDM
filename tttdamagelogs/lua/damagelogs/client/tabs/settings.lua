function Damagelog:DrawSettings(x, y)
	local selectedcolor

    self.Settings = vgui.Create("DPanelList")
	self.Settings:SetSpacing(10)
	self.Settings:EnableVerticalScrollbar(true)
	
	self.ColorSettings = vgui.Create("DForm")
	self.ColorSettings:SetName("#Damagelog.Colors")
	
	self.ColorChoice = vgui.Create("DComboBox")
	for k,v in pairs(self.colors) do
	    self.ColorChoice:AddChoice(k)
	end
	self.ColorChoice:ChooseOptionID(1)
	self.ColorChoice.OnSelect = function(panel,index,value,data)
	    self.ColorMixer:SetColor(self.colors[value].Custom)
		selectedcolor = value
	end
	self.ColorSettings:AddItem(self.ColorChoice)
	
	self.ColorMixer = vgui.Create("DColorMixer")
	self.ColorMixer:SetHeight(200)
	local found = false
	for k,v in pairs(self.colors) do
	    if not found then
	        self.ColorMixer:SetColor(v.Custom)
			selectedcolor = k
			found = true
		end
	end
	self.ColorSettings:AddItem(self.ColorMixer)
	
	self.SaveColor = vgui.Create("DButton")
	self.SaveColor:SetText("#Damagelog.Save")
	self.SaveColor.DoClick = function()
	    local c = self.ColorMixer:GetColor()
		self.colors[selectedcolor].Custom = c
		self:SaveColors()
	end
	self.ColorSettings:AddItem(self.SaveColor)
	
	self.defaultcolor = vgui.Create("DButton")
	self.defaultcolor:SetText("#Damagelog.SetDefault")
	self.defaultcolor.DoClick = function()
		local c = self.colors[selectedcolor].Default
	    self.ColorMixer:SetColor(c)
		self.colors[selectedcolor].Custom = c
		self:SaveColors()
	end	
	self.ColorSettings:AddItem(self.defaultcolor)
	
	self.Settings:AddItem(self.ColorSettings)
	
	self.WeaponForm = vgui.Create("DForm")
	self.WeaponForm:SetName("#Damagelog.EditNames")
		
	self.AddWeapon = vgui.Create("DButton")
	self.AddWeapon:SetText("#Damagelog.AddWeaponEntity")
	self.AddWeapon.DoClick = function()
		if not LocalPlayer():IsSuperAdmin() then return end
		Derma_StringRequest("#Damagelog.WeaponID", "#Damagelog.WeaponNameExample :", "weapon_", function(class)
			Derma_StringRequest("#Damagelog.WeaponDisplayName", "#Damagelog.WeaponDisplayExample :", "", function(name)
				net.Start("DL_AddWeapon")
				net.WriteString(class)
				net.WriteString(name)
				net.SendToServer()
			end)
		end)
	end
	self.WeaponForm:AddItem(self.AddWeapon)
		
	self.RemoveWeapon = vgui.Create("DButton")
	self.RemoveWeapon:SetText(#Damagelog.RemoveSelectedWeapons)
	self.RemoveWeapon.DoClick = function()
		if not LocalPlayer():IsSuperAdmin() then return end
		local classes = {}
		for k,v in pairs(self.WepListview:GetSelected()) do
			table.insert(classes, v:GetValue(1))
		end
		net.Start("DL_RemoveWeapon")
		net.WriteTable(classes)
		net.SendToServer()
	end
	self.WeaponForm:AddItem(self.RemoveWeapon)
		
	self.DefautTable = vgui.Create("DButton")
	self.DefautTable:SetText(#Damagelog.ResetDefault)
	self.DefautTable.DoClick = function()
		if not LocalPlayer():IsSuperAdmin() then return end
		Derma_Query("#Damagelog.ResetDefault ?", "#Damagelog.Yoursure", "#Damagelog.Yes", function()
			net.Start("DL_WeaponTableDefault")
			net.SendToServer()
		end, "#Damagelog.No", function() end)
	end
	self.WeaponForm:AddItem(self.DefautTable)
		
	self.WepListview = vgui.Create("DListView")
	self.WepListview:SetHeight(136)
	self.WepListview:AddColumn("#Damagelog.WeaponEntityID")
	self.WepListview:AddColumn("#Damagelog.DisplayName")
	self.WepListview.Update = function(panel)
		panel:Clear()
		for k,v in pairs(Damagelog.weapon_table) do
			local line = panel:AddLine(k,v)
			if not self.weapon_table_default[k] then
				line.PaintOver = function()
					line.Columns[1]:SetTextColor(Color(50, 255, 50))
					line.Columns[2]:SetTextColor(Color(50, 255, 50))
				end
			end			
		end
	end
	self.WepListview:Update()
		
	self.WeaponForm:AddItem(self.WepListview)
		
	self.Settings:AddItem(self.WeaponForm)
	
	
	self.Tabs:AddSheet( "#Damagelog.Settings", self.Settings, "icon16/wrench.png", false, false)	

end

net.Receive("DL_SendWeaponTable", function()
	local full = net.ReadUInt(1) == 1
	if full then
		Damagelog.weapon_table = net.ReadTable()
	else
		Damagelog.weapon_table[net.ReadString()] = net.ReadString()
	end
	if IsValid(Damagelog.WepListview) then
		Damagelog.WepListview:Update()
	end
end)