# Lua Time Module Specification

## Overview

The `time` module provides a Lua interface for time-related functionality. It provides tools for working with dates,
times, durations, timers, tickers, and time zones. It supports time formatting, parsing, arithmetic operations, and
various timing primitives for concurrent programming. Time package mimics Go's time package, providing a familiar API.

## Module Loading

```lua
local time = require("time")
```

### Objects

The module works with several core types:

- `Duration`: Represents an elapsed time interval
- `Time`: Represents a specific instant in time
- `Location`: Represents a time zone
- `Timer`: Single-use timer that triggers after a duration
- `Ticker`: Repeating timer that triggers at regular intervals

### Duration

A `Duration` represents the elapsed time between two instants as an integer nanosecond count.

#### Duration Constants

```lua
time.NANOSECOND  -- 1
time.MICROSECOND -- 1000
time.MILLISECOND -- 1000000
time.SECOND      -- 1000000000  
time.MINUTE      -- 60000000000
time.HOUR        -- 3600000000000
```

#### Duration Creation

```lua
-- Parse from string
local d, err = time.parse_duration("1h30m")    -- 1 hour 30 minutes
local d2, err = time.parse_duration("500ms")   -- 500 milliseconds
local d3, err = time.parse_duration("1.5s")    -- 1.5 seconds

-- Values can be:
-- "ns" - nanoseconds
-- "us" - microseconds  
-- "ms" - milliseconds
-- "s"  - seconds
-- "m"  - minutes 
-- "h"  - hours
```

#### Duration Methods

- `duration:nanoseconds() -> number`: Returns the duration as a floating-point number of nanoseconds.
- `duration:microseconds() -> number`: Returns the duration as a floating-point number of microseconds.
- `duration:milliseconds() -> number`: Returns the duration as a floating-point number of milliseconds.
- `duration:seconds() -> number`: Returns the duration as a floating-point number of seconds.
- `duration:minutes() -> number`: Returns the duration as a floating-point number of minutes.
- `duration:hours() -> number`: Returns the duration as a floating-point number of hours.

String conversion is handled automatically when using `tostring(duration)`, returning a format like "1h30m0s".

### Location

A `Location` represents a time zone. Every Time has an associated Location that determines wall time display.

#### Location Objects/Values

```lua
time.utc     -- UTC location (userdata object, not a constant)
time.localtz -- System local timezone location (userdata object, not a constant)
```

#### Location Creation

```lua
-- Load location by name
local loc, err = time.load_location("America/New_York")

-- Create fixed offset location
local loc = time.fixed_zone("EST", -5*3600)  -- -5 hours from UTC
```

#### Location Methods

- `location:string() -> string`: Returns the name of the location

String conversion is handled automatically when using `tostring(location)`, returning the location name.

### Time

A `Time` represents an instant in time with nanosecond precision.

#### Time Creation

```lua
-- Current time
local t = time.now()

-- From components
local t = time.date(2024, 1, 15, 14, 30, 0, 0, time.utc) 

-- From Unix timestamp
local t = time.unix(1234567890, 0)  -- seconds, nanoseconds

-- Parse from string
local t, err = time.parse("2006-01-02 15:04:05", "2024-01-15 14:30:00")
```

#### Time Format Constants

```lua
time.RFC3339      -- "2006-01-02T15:04:05Z07:00"
time.RFC3339NANO  -- "2006-01-02T15:04:05.999999999Z07:00"
time.RFC822       -- "02 Jan 06 15:04 MST" 
time.RFC822Z      -- "02 Jan 06 15:04 -0700"
time.RFC850       -- "Monday, 02-Jan-06 15:04:05 MST"
time.RFC1123      -- "Mon, 02 Jan 2006 15:04:05 MST"
time.RFC1123Z     -- "Mon, 02 Jan 2006 15:04:05 -0700"
time.KITCHEN      -- "3:04PM"
time.STAMP        -- "Jan _2 15:04:05"
time.STAMP_MILLI  -- "Jan _2 15:04:05.000"
time.STAMP_MICRO  -- "Jan _2 15:04:05.000000"
time.STAMP_NANO   -- "Jan _2 15:04:05.000000000"
time.DATE_TIME    -- "2006-01-02 15:04:05"
time.DATE_ONLY    -- "2006-01-02"
time.TIME_ONLY    -- "15:04:05"
```

#### Time Methods

- `time:add(duration) -> Time`: Returns time t+d
- `time:sub(other) -> Duration`: Returns the duration t-u
- `time:add_date(years, months, days) -> Time`: Returns the time corresponding to adding years, months, days
- `time:after(other) -> boolean`: Reports whether t is after u
- `time:before(other) -> boolean`: Reports whether t is before u
- `time:equal(other) -> boolean`: Reports whether t and u represent the same time instant
- `time:format(layout) -> string`: Returns formatted time according to layout
- `time:format_rfc3339() -> string`: Returns time formatted according to RFC3339
- `time:unix() -> number`: Returns Unix time in seconds
- `time:unix_nano() -> number`: Returns Unix time in nanoseconds
- `time:date() -> year, month, day`: Returns year, month, day
- `time:clock() -> hour, min, sec`: Returns hour, minute, second
- `time:year() -> number`: Returns year
- `time:month() -> number`: Returns month (1-12)
- `time:day() -> number`: Returns day of month
- `time:hour() -> number`: Returns hour (0-23)
- `time:minute() -> number`: Returns minute (0-59)
- `time:second() -> number`: Returns second (0-59)
- `time:nanosecond() -> number`: Returns nanosecond offset
- `time:weekday() -> number`: Returns day of week (0=Sunday)
- `time:year_day() -> number`: Returns day of year
- `time:is_zero() -> boolean`: Reports whether t represents the zero time
- `time:in_location(loc) -> Time`: Returns time with location loc
- `time:location() -> Location`: Returns time's location
- `time:utc() -> Time`: Returns time in UTC location
- `time:in_local() -> Time`: Returns time in local location
- `time:round(duration) -> Time`: Returns time rounded to nearest multiple of duration
- `time:truncate(duration) -> Time`: Returns time truncated to multiple of duration

#### Time Month Constants

```lua
time.JANUARY   -- 1
time.FEBRUARY  -- 2
time.MARCH     -- 3
time.APRIL     -- 4 
time.MAY       -- 5
time.JUNE      -- 6
time.JULY      -- 7
time.AUGUST    -- 8
time.SEPTEMBER -- 9
time.OCTOBER   -- 10
time.NOVEMBER  -- 11
time.DECEMBER  -- 12
```

#### Time Weekday Constants

```lua
time.SUNDAY    -- 0
time.MONDAY    -- 1
time.TUESDAY   -- 2
time.WEDNESDAY -- 3
time.THURSDAY  -- 4
time.FRIDAY    -- 5
time.SATURDAY  -- 6
```

### Timer

A `Timer` represents a single event that will occur after a specified duration.

#### Timer Creation and Methods

```lua
-- Create timer with duration (duration object, string, or milliseconds)
local timer = time.timer("100ms")
local timer = time.timer(duration_obj)
local timer = time.timer(100) -- milliseconds

-- Methods
timer:stop() -> boolean       -- Stops timer, returns if it was active
timer:reset(duration) -> boolean   -- Restarts timer with new duration 
timer:channel() -> Channel    -- Returns channel that receives time when timer triggers
```

### Ticker

A `Ticker` represents a periodic event occurring at regular intervals.

#### Ticker Creation and Methods

```lua
-- Create ticker with interval (duration object, string, or milliseconds)
local ticker = time.ticker("100ms")
local ticker = time.ticker(duration_obj)
local ticker = time.ticker(100) -- milliseconds

-- Methods
ticker:stop()              -- Stops ticker
ticker:channel() -> Channel   -- Returns channel that receives time on each tick
```

### Utility Functions

#### time.sleep

```lua
local err = time.sleep(duration)  -- duration can be Duration object or string
```

Pauses execution for specified duration. Returns error if interrupted by context cancellation.

#### time.after

```lua
local ch = time.after(duration)  -- duration can be Duration, string, or milliseconds
```

Returns a channel that will receive a signal (true) after the specified duration. Channel is closed after sending.

Both Timer/Ticker channels and after() can be used with channel.select:

```lua
local result = channel.select{
    timer:channel():case_receive(),
    done:case_receive()
}
```