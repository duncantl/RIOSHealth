# RIOSHealth

I AirDrop the file from my iphone to my desktop and then read the walking data from today
and plot it.

```
td = RIOSHealth::himport()
plot(td$startDate, td$value/as.numeric(td$diffHr), type = "b", xlab = "Time", ylab = "Miles/hour", main = Sys.Date())
```

We can also read all of the data, not just today's.
```
td = RIOSHealth::himport(today = FALSE)
```

The default value for the export.zip file to read is customized to my way of reading the files.
I have a script that moves the export.zip from the Downloads directory and rename it in the current
working directory as export_%m-%d-%y.zip where %m, %d and %y are the month, day and year (as
numbers.)
If that doesn't exist, it looks for the most recent export.zip file in the ~/Downloads directory,
accounting for download numbering, e.g., export-2.zip.

You can specify the path to the file directly.


