# RIOSHealth

I AirDrop the file from my iphone to my desktop and then read the walking data from today
and plot it.

```
td = RIOSHealth::himport()
plot(td$startDate, td$value/as.numeric(td$diffHr), type = "b", xlab = "Time", ylab = "Miles/hour", main = Sys.Date())
```


We can also read all of the data, not just today's.


This code currently uses my local function mostRecent() and copies the export.zip file from
Downloads to the current directory and gives it today's date.
I'll fix this later for more general use, but that is how I use it.


