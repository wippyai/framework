// SPDX-License-Identifier: MPL-2.0

package runner_test

import (
	"os"
	"testing"

	lua "github.com/wippyai/go-lua"
)

func TestRunnerOrderedCompletion(t *testing.T) {
	for _, scenario := range []struct {
		name string
		want string
	}{
		{"simple", "0"},
		{"bdd", "0"},
		{"missing_completion", "1"},
		{"duplicate_completion", "1"},
		{"wrong_sender", "1"},
	} {
		t.Run(scenario.name, func(t *testing.T) {
			l := lua.NewState()
			defer l.Close()
			l.SetGlobal("scenario", lua.LString(scenario.name))
			root := "../../src/test"
			if baseline := os.Getenv("RUNNER_SOURCE_ROOT"); baseline != "" {
				root = baseline
			}
			verdict, err := os.ReadFile(root + "/runner_verdict.lua")
			if err != nil {
				t.Fatal(err)
			}
			if err := l.DoString(string(verdict)); err != nil {
				t.Fatal(err)
			}
			l.SetGlobal("actual_verdict", l.Get(-1))
			l.Pop(1)
			if err := l.DoString(`
local processor
local spawned = 0
local failure
local delays = {}
local queues = {}
local select
local function new_channel()
 local ch={queue={}}
 function ch:send(value) self.queue[#self.queue+1]=value end
 function ch:receive() return select({self:case_receive()}).value end
 function ch:case_receive() return {channel=self} end
 function ch:close() self.closed=true end
 return ch
end
local inbox = new_channel()
local function emit(topic, data, sender)
 local msg={topic=function() return topic end,from=function() return sender or "child" end,
  payload=function() return {data=function() return data end} end}
 local ch=queues[topic] or inbox
 ch:send(msg)
end
local function ready(cases)
 for _,case in ipairs(cases) do
  local ch=case.channel
  if #ch.queue>0 then return {channel=ch,value=table.remove(ch.queue,1),ok=true} end
  if ch.closed then return {channel=ch,ok=false} end
 end
end
select = function(cases)
 local result=ready(cases)
 if result then return result end
 if coroutine.running()==processor then coroutine.yield(); return select(cases) end
 if processor and coroutine.status(processor)~="dead" then
  local ok,err=coroutine.resume(processor);assert(ok,err)
  result=ready(cases);if result then return result end
 end
 for _,case in ipairs(cases) do if case.channel.timer then return {channel=case.channel,ok=true} end end
 error("runner blocked without pending work or a configured timeout")
end
local stamp={sub=function(self) return self end,milliseconds=function() return 0 end}
local entries={{id="test:case",meta={timeout="5s"}}}
local modules={
 io={args=function() end},env={get=function() end},registry={find=function() return entries end},
 time={now=function() return stamp end,MILLISECOND=1,
  sleep=function() error("runner slept instead of using runtime readiness") end,
  after=function(duration) delays[#delays+1]=duration;local ch=new_channel();ch.timer=true;return ch end},
 channel={new=new_channel,select=select},
 discovery={group_by_suite=function() return {suite=entries},{} end,sorted_keys=function() return {"suite"} end,short_name=function(id) return id end},
 display=setmetatable({case_fail=function(_,_,message) failure=message end}, {__index=function() return function() end end}),verdict=actual_verdict,
}
require=function(name) return assert(modules[name],name) end
coroutine.spawn=function(fn) processor=coroutine.create(fn) end
process={pid=function() return "parent" end,inbox=function() return inbox end,
 listen=function(topic) local ch=new_channel();queues[topic]=ch;return ch end,
 spawn=function()
  spawned=spawned+1
  if scenario~="simple" and scenario~="wrong_sender" then
   emit("test:update",{type="test:plan",data={ref_id="test:case",suites={{tests={"one"}}}}})
   emit("test:update",{type="test:case:pass",data={ref_id="test:case",suite="suite",test="one"}})
   if scenario~="missing_completion" then
    emit("test:update",{type="test:complete",data={ref_id="test:case",total=1,passed=1,failed=0,skipped=0}})
    if scenario=="duplicate_completion" then emit("test:update",{type="test:complete",data={ref_id="test:case",total=1,passed=1,failed=0,skipped=0}}) end
   end
  end
  emit("runner:control",{kind="result",ref_id="test:case",value=true},scenario=="wrong_sender" and "other" or "child")
  return "child"
 end,send=function() emit("runner:control",{kind="canceled",ref_id="test:case",cancel_ok=true});return true end,terminate=function() return true end}
function verify_coordination()
 assert(spawned==1,"runner did not execute the test")
 local expected={missing_completion="test process did not report completion",duplicate_completion="test process reported more than one completion",wrong_sender="test result attributed"}
 if expected[scenario] then assert(failure and failure:find(expected[scenario],1,true),"runner failed for the wrong reason: "..tostring(failure)) end
 for _,delay in ipairs(delays) do assert(delay~="1s","runner waited for an event barrier after the function returned") end
end
`); err != nil {
				t.Fatal(err)
			}
			source, err := os.ReadFile(root + "/runner.lua")
			if err != nil {
				t.Fatal(err)
			}
			if err := l.DoString(string(source)); err != nil {
				t.Fatal(err)
			}
			module := l.Get(-1).(*lua.LTable)
			if err := l.CallByParam(lua.P{Fn: module.RawGetString("main"), NRet: 1, Protect: true}); err != nil {
				t.Fatal(err)
			}
			if got := l.Get(-1).String(); got != scenario.want {
				t.Fatalf("runner returned %s, want %s", got, scenario.want)
			}
			if err := l.DoString("verify_coordination()"); err != nil {
				t.Fatal(err)
			}
		})
	}
}
