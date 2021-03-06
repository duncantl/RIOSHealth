# Leave so can source this directly.
library(XML)
library(Rcompression)

read = 
function(file)
{    
    d = xmlParse(file)
    rr = getNodeSet(d, "//Record")
    tmp = lapply(rr, function(x) as.data.frame(as.list(xmlAttrs(x)), stringsAsFactors = FALSE))
    tmp2 = do.call(rbind, tmp)

    tmp2$value = as.numeric(tmp2$value)
    i = grep("Date", names(tmp2))
    tmp2[i] = lapply(tmp2[i], function(x) as.POSIXct(strptime(x, "%Y-%m-%d %H:%M:%S")))
    tmp2$unit = factor(tmp2$unit)
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
function(f = todaysFile(), today = TRUE)
{
    ar = zipArchive(f)

    tmp2 = (if(today) readToday else read)(ar[["apple_health_export/export.xml"]])
    
    d = subset(tmp2, type == "HKQuantityTypeIdentifierDistanceWalkingRunning")
    d$diff = d$endDate - d$startDate
    d$diffHr = d$diff/(60^2)

    d
}

readToday =
    #
    # This takes some liberties to be a lot faster.
    # It finds all the <Record  type="...WalkingRunning"> nodes each of which is assumed to be entirely on a single line
    #
function(txt,lines = strsplit(txt, "\n")[[1]], date = format(Sys.Date(), "%Y-%m-%d"))
{
    rx = sprintf('<Record.*type="HKQuantityTypeIdentifierDistanceWalkingRunning".*creationDate="%s', date)
    ll = grep(rx, lines, value = TRUE)
    xml = sprintf("<doc>%s</doc>", paste(ll, collapse = "\n"))
    read(xml)
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




