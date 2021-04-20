require "lfs"
postsDir = [[posts]]
filenames, titles, subtitles, dates = {}, {}, {}, {}
p = 0
html = ""

for filename in lfs.dir(postsDir) do
    if filename ~= "." and filename ~= ".." then
        p = p+1
        filenames[p] = "/posts/" .. filename:sub(1,-4) .. ".html"
        dates[p] = filename:sub(1,10)
        file = io.open(postsDir.."\\"..filename, "r")
        while titles[p] == nil or subtitles[p] == nil do
            line = file:read()
            if line:sub(1, 7) == "title: " then titles[p] = line:sub(8)
            elseif line:sub(1, 10) == "subtitle: " then subtitles[p] = line:sub(11)
            end
        end
    end
end

for i=p,1,-1 do
    html = html.."<a href="..filenames[i].."><li>"..titles[i].."<div class=\"postlist-date\"> | "..dates[i].."</div><div class=\"postlist-subtitle\">"..subtitles[i].."</div></li></a>\n"
end

io.write(html)