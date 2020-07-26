postfile = os.getenv("ZS_FILE")
io.write(postfile:sub(postfile:find("\\[^\\]*$") + 1):sub(1,10))