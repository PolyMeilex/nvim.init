local m =  {}

function m.IsVsCode()
	return vim.g.vscode ~= nil
end

function m.IsNotVsCode()
	return vim.g.vscode == nil
end

return m
