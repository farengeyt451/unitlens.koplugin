local H = {}

-- Print table, debugging purpose
function H.dump(o)
	if type(o) == "table" then
		local s = "{ "

		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. H.dump(v) .. ","
		end

		return s .. "} "
	else
		return tostring(o)
	end
end

return H
