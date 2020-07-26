header = io.open("header.amber", "r")
headerStr = header:read("*all")
header:close()

function prependHeader (filename, title)
    template = io.open(filename, "r")
    templateStr = template:read("*all")
    headerEnd = templateStr:find("\n\n")
    templateStr = headerStr:gsub("<< from header.lua >>", title) .. templateStr:sub(headerEnd)
    template = io.open(filename, "w+")
    template:write(templateStr)
    template:close()
end

prependHeader("layout.amber", "#{title}")
prependHeader("..\\index.amber", "Felipe's blog")
prependHeader("..\\about.amber", "About Felipe")