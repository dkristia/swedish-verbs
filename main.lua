local http = require("socket.http")
local json = require("dkjson")

local function korpusLink(word)
    return "https://ws.spraakbanken.gu.se/ws/korp/v8/query?default_context=1%20sentence&start=0&end=24&corpus=ATTASIDOR%2CDA%2CSVT-2004%2CSVT-2005%2CSVT-2006%2CSVT-2007%2CSVT-2008%2CSVT-2009%2CSVT-2010%2CSVT-2011%2CSVT-2012%2CSVT-2013%2CSVT-2014%2CSVT-2015%2CSVT-2016%2CSVT-2017%2CSVT-2018%2CSVT-2019%2CSVT-2020%2CSVT-2021%2CSVT-2022%2CSVT-2023%2CSVT-NODATE&cqp=%5Bword%20%3D%20%22" .. word .. "%22%5D&context=&incremental=true&default_within=sentence&within=&show=sentence%2Csense%2Ccompwf%2Ccomplemgram%2Cufeats%2Cdeprel%2Cdephead%2Cref%2Csentiment_label%2Cblingbring%2Cswefn%2Cne_ex%2Cne_name%2Cne_type%2Cne_subtype%2Clemma%2Clex%2Cmsd%2Cpos%2Cparagraph&show_struct=text_blingbring%2Ctext_swefn%2Ctext_lix%2Ctext_ovix%2Ctext_nk%2Ctext_author%2Ctext_date%2Ctext_tags%2Ctext_title%2Ctext_url%2Ctext_data_collected%2Ctext_id%2Cparagraph_type%2Ctext_authors%2Ctext_section%2Ctext_subtitle"
end

local function fetchExampleSentence(word)
    local url = korpusLink(word)
    local response, status = http.request(url)
    if status ~= 200 then
        print("Error: Could not fetch data from the server.")
        return
    end

    local data, pos, err = json.decode(response, 1, nil)
    if err then
        print("Error: Could not parse JSON response.")
        return
    end

    local examples = data.kwic
    if not examples or #examples == 0 then
        print("No examples found.")
        return
    end

    local randomIndex = math.random(1, #examples)
    local randomExample = examples[randomIndex]
    local sentence = ""
    for i, token in ipairs(randomExample.tokens) do
        local hasSpace = i < #randomExample.tokens - 1
        sentence = sentence .. token.word .. (hasSpace and " " or "")
    end
    sentence = sentence:gsub("– ", "")
    return sentence
end

local args = {...}
if not args[1] or not args[2] then
    print("Usage: lua main.lua <input file> <output file>")
    os.exit(1)
end
local inputFile = io.open(args[1], "r")
local outputFile = io.open(args[2], "a")
if not inputFile then
    print("Error: Could not open input file.")
    os.exit(1)
end
if not outputFile then
    print("Error: Could not open output file.")
    os.exit(1)
end
local index = 1
for line in inputFile:lines() do
    local words = {}
    for word in line:gmatch("%S+") do
        table.insert(words, word)
    end
    local perusmuoto = words[1]
    print("Fetching examples for " .. index .. ". " .. perusmuoto .. "-verbi")
    outputFile:write(index .. ". " .. perusmuoto .. "-verbi\n")
    outputFile:flush()
    for i, word in ipairs(words) do
        local exampleSentence = fetchExampleSentence(word)
        print(i .. ". " .. exampleSentence)
        outputFile:write("  " .. i .. ". " .. exampleSentence .. "\n")
        outputFile:flush()
    end
    index = index + 1
end
inputFile:close()
outputFile:close()