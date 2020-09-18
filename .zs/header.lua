header = io.open("header.amber", "r")
headerStr = header:read("*all")
header:close()

function prependHeader (filename, title)
    template = io.open(filename, "r")
    templateStr = template:read("*all")
    headerEnd = templateStr:find("\n\n")
    thisHeaderStr = ""
    if filename:find("index") then
        thisHeaderStr = headerStr:gsub("%.active\n\t+a%[href=\"/index.html\"%]", "")
    elseif filename:find("about") then
        thisHeaderStr = headerStr:gsub("%.active\n\t+a%[href=\"/about.html\"%]", "")
    else
        thisHeaderStr = headerStr
    end
    templateStr = thisHeaderStr:gsub("<< from header.lua >>", title) .. templateStr:sub(headerEnd)
    template = io.open(filename, "w+")
    template:write(templateStr)
    template:close()
end

prependHeader("layout.amber", "#{title}")
prependHeader("..\\index.amber", "Felipe's blog")
prependHeader("..\\about.amber", "About Felipe")