# Leave so can source this directly.
library(XML)
library(Rcompression)

cp =
function(zip = mostRecent(pattern = "export.*.zip", dir = "~/Downloads"),
         to = sprintf("export_%s.xml", format(Sys.Date(), "%m_%d_%y")))    
{
    if(file.exists(to))
        return(to)
    
    system(sprintf("unzip -p %s apple_health_export/export.xml > %s", shQuote(zip), shQuote(to)))
    to
}


read = 
function(file, doc = xmlParse(file))
{
    rr = getNodeSet(doc, "//Record")
    processNodes(rr)
}

read2 = 
function(file, when, doc = xmlParse(file), dateAttr = "startDate")
{
    rr = getNodeSet(doc, "//Record")
    dt0 = sapply(rr, xmlGetAttr, dateAttr)
    dt = as.POSIXct(strptime(dt0, "%Y-%m-%d %H:%M:%S", tz = "America/Los_Angeles"))
    w = !is.na(dt) & dt >= as.POSIXct(when)
    processNodes(rr[w])
}



processNodes =
function(rr)    
{
    tmp = lapply(rr, function(x) as.data.frame(as.list(xmlAttrs(x)), stringsAsFactors = FALSE))
    tmp2 = #if(require("data.table"))
               as.data.frame(data.table::rbindlist(tmp))
           #else
            #   do.call(rbind, tmp)

    tmp2$value = as.numeric(tmp2$value)
    i = grep("Date", names(tmp2))
    tmp2[i] = lapply(tmp2[i], function(x) as.POSIXct(strptime(x, "%Y-%m-%d %H:%M:%S")))
    tmp2$unit = factor(tmp2$unit)

    tmp2$type = gsub("^HKQuantityTypeIdentifier", "", tmp2$type)
    
    tmp2
}


copyMostRecent =
function()    
{
    ff = mostRecent("^export")
    f2 = todaysFile()
    if(length(ff) == 0)
        return(f2)
    file.copy(ff, f2)
    f2
}

mostRecent
function (pattern, dir = "~/Downloads") 
{
    info = file.info(list.files(dir, pattern = pattern, full.names = TRUE))
    rownames(info)[which.max(info$ctime)]
}

todaysFile =
function(find = FALSE)
{
    f = sprintf("export_%s.zip",  format(Sys.Date(), "%m_%d_%y"))
    if(!find)
        return(f)
    
    if(!file.exists(f))
        return(mostRecent("export.*\\.zip"))

    f
}


himport =
function(f = todaysFile(), today = TRUE, type = "HKQuantityTypeIdentifierDistanceWalkingRunning")
{
    ar = zipArchive(f)

    tmp2 = (if(today) readToday else read)(ar[["apple_health_export/export.xml"]])
    
    d = subset(tmp2, type == type)
    d$diff = d$endDate - d$startDate
    d$diffHr = d$diff/(60^2)

    d
}


readToday = readToday0 =
    # Not used. See version below.
    #
    # This takes some liberties to be a lot faster.
    # It finds all the <Record  type="...WalkingRunning"> nodes each of which is assumed to be entirely on a single line
    #
function(txt, date = format(Sys.Date(), "%Y-%m-%d"), lines = strsplit(txt, "\n")[[1]])
{
    rx = sprintf('<Record.*type="HKQuantityTypeIdentifierDistanceWalkingRunning".*creationDate="%s', date)
    ll = grep(rx, lines, value = TRUE)
    xml = sprintf("<doc>%s</doc>", paste(ll, collapse = "\n"))
    read(xml)
}

# New version
readToday = readDay =
    #
    # This does not takes the liberties above.
    #
function(txt, types = character(), date = format(Sys.Date(), "%Y-%m-%d"), doc = xmlParse(txt), ...)
{

    cond = sprintf("starts-with(@creationDate , '%s')", date)
    if(length(types)) {
       types =  mkTypes(types)
       cond = c(cond, sprintf("( %s )", paste(sprintf("@type = '%s'", types), collapse = " or ")))
    }
    xp = sprintf("//Record[ %s ] ", paste(cond, collapse = " and "))
    rec = getNodeSet(doc, xp)
    processNodes(rec)
}

mkTypes =
function(x)    
{
    pre = "HKQuantityTypeIdentifier"
    w = !grepl(paste0("^", pre), x)
    x[w] = paste0(pre, x[w])
    x
}

walkDist =
    #e.g.,  walkDist("13:25", "14:30")
function(start, end, x = td)
{
    start = strptime(start, "%H:%M")
    end = strptime(end, "%H:%M")
    dist = sum(x$value [ x$startDate >= start & x$startDate <= end ])
    c(distance = dist, mph = dist/as.numeric(end - start))
}




