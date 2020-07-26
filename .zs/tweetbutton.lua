url = os.getenv("ZS_URL"):gsub("\\", "/")
title = os.getenv("ZS_TITLE")
io.write("<a href=\"https://twitter.com/intent/tweet?text=" .. title .. " https://fpsvogel.netlify.app/" .. url .. "\" class=\"flexrow center\"><i class=\"fab fa-twitter\"></i><div>Tweet</div></a>")