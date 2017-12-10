laptop.register_app("calculator", {
	app_name = "Calculator",
	app_icon = "laptop_calculator.png",
	app_info = "Calculate things",
	formspec_func = function(app, mtos)
		local data = app:get_storage_ref()

		if not data.tab then
			data.tab = {}
		end
		if not data.tab[1] then
			table.insert(data.tab, {})
		end

		local formspec = "tablecolumns[" ..
			"text,align=right,padding=1.5,width=6;".. -- first value
			"text,align=right,padding=1.5;".. -- operator
			"text,align=right,padding=1.5,width=6]".. -- last value
			"table[1,1;7,2;tab;"

		for idx,entry in ipairs(data.tab) do
			if idx > 1 then
				formspec = formspec..','
			end
			formspec = formspec..(entry.var1 or "")..","..(entry.operator or "")..","..(entry.var2 or "0")
		end

		formspec = formspec .. ";"..#data.tab.."]"..
				"image_button[1,3;1,1;"..mtos.theme.minor_button..";number;1]"..
				"image_button[2,3;1,1;"..mtos.theme.minor_button..";number;2]"..
				"image_button[3,3;1,1;"..mtos.theme.minor_button..";number;3]"..
				"image_button[1,4;1,1;"..mtos.theme.minor_button..";number;4]"..
				"image_button[2,4;1,1;"..mtos.theme.minor_button..";number;5]"..
				"image_button[3,4;1,1;"..mtos.theme.minor_button..";number;6]"..
				"image_button[1,5;1,1;"..mtos.theme.minor_button..";number;7]"..
				"image_button[2,5;1,1;"..mtos.theme.minor_button..";number;8]"..
				"image_button[3,5;1,1;"..mtos.theme.minor_button..";number;9]"..
				"image_button[1,6;1,1;"..mtos.theme.minor_button..";number;0]"..
				"image_button[2,6;1,1;"..mtos.theme.minor_button..";number;.]"..

				"image_button[5,3;1,1;"..mtos.theme.minor_button..";operator;+]"..
				"image_button[5,4;1,1;"..mtos.theme.minor_button..";operator;-]"..
				"image_button[5,5;1,1;"..mtos.theme.minor_button..";operator;/]"..
				"image_button[5,6;1,1;"..mtos.theme.minor_button..";operator;*]"..
				"image_button[6,6;2,1;"..mtos.theme.minor_button..";operator;=]"..

				"image_button[6,3;2,1;"..mtos.theme.minor_button..";del_char;DEL-1]"..
				"image_button[6,4;2,1;"..mtos.theme.minor_button..";del_line;DEL-L]"..
				"image_button[6,5;2,1;"..mtos.theme.minor_button..";del_all;DEL-A]"
		return formspec
	end,

	receive_fields_func = function(app, mtos, fields, sender)
		local data = app:get_storage_ref()
		local entry = data.tab[#data.tab]

		if fields.number then
			-- simple number entry
			entry.var2 = (entry.var2 or "")..fields.number
		elseif fields.del_char then
			-- delete char
			if entry.var2 and entry.var2 ~= "" then
				-- remove char from current number
				entry.var2 = entry.var2:sub(1, -2)
				if entry.var2 == "" then
					entry.var2 = nil
				end
			else
				-- get previous number
				if #data.tab > 1 then
					-- go back to previous line if exists
					table.remove(data.tab, #data.tab)
				else
					-- get from left site if first entry
					entry.var2 = entry.var1
					entry.operator = nil
					entry.var1 = nil
				end
			end
		elseif fields.del_line then
			-- just delete full number if exists
			if entry.var2 and entry.var2 ~= "" then
				entry.var2 = nil
			else
				-- go back to previous line and delete the full number if exists
				table.remove(data.tab, #data.tab)
				if #data.tab > 0 then
					entry = data.tab[#data.tab]
					entry.var2 = nil
				end
			end
		elseif fields.del_all then
			data.tab = nil
		elseif fields.operator then
			local entry = data.tab[#data.tab]
			-- no previous operator
			if not entry.operator then
				if fields.operator == '=' then
					table.insert(data.tab, {}) -- add empty line
				elseif entry.var2 and entry.var2 ~= "" then
					-- move to the left
					entry.var1 = entry.var2
					entry.operator = fields.operator
					entry.var2 = nil
				end

			-- process previous operator
			else
				local result
				if entry.operator == '+' then
					result = tonumber(entry.var1) + tonumber(entry.var2)
				elseif entry.operator == '-' then
					result = tonumber(entry.var1) - tonumber(entry.var2)
				elseif entry.operator == '/' then
					result = tonumber(entry.var1) / tonumber(entry.var2)
				elseif entry.operator == '*' then
					result = tonumber(entry.var1) * tonumber(entry.var2)
				elseif entry.operator == '=' then
					result = tonumber(entry.var2)
				end
				if fields.operator == '=' then
					table.insert(data.tab, {var2 = tostring(result)})
				else
					table.insert(data.tab, {var1 = tostring(result), operator = fields.operator})
				end
			end
		end
	end
})
