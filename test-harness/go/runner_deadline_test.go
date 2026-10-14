// SPDX-License-Identifier: MPL-2.0

package runner_test

import (
	"os"
	"testing"

	lua "github.com/wippyai/go-lua"
)

func TestRunnerDeadlinePolicies(t *testing.T) {
	for _, scenario := range []string{"unbounded", "shared", "expired", "expired_during_teardown", "conflicting"} {
		t.Run(scenario, func(t *testing.T) {
			testRunnerDeadline(t, scenario)
		})
	}
}

func testRunnerDeadline(t *testing.T, scenario string) {
	sourcePath := "../../src/test/runner.lua"
	if baseline := os.Getenv("RUNNER_SOURCE_ROOT"); baseline != "" {
		sourcePath = baseline + "/runner.lua"
	}
	source, err := os.ReadFile(sourcePath)
	if err != nil {
		t.Fatal(err)
	}
	l := lua.NewState()
	defer l.Close()
	var guessed bool
	var suiteTimers, spawns int
	l.SetGlobal("scenario", lua.LString(scenario))
	l.SetGlobal("record_spawn", l.NewFunction(func(l *lua.LState) int { spawns++; return 0 }))
	l.SetGlobal("observe_timeout", l.NewFunction(func(l *lua.LState) int {
		if l.Get(1).String() == "30s" {
			guessed = true
		}
		if l.Get(1).String() == "2m" {
			suiteTimers++
		}
		return 0
	}))
	err = l.DoString(`
local stamp = {sub=function(self) return self end,milliseconds=function() return 0 end}
local current_id="test:one"
local cancel_sent=false
local suite_expired=false
local msg = {from=function() return "child" end,payload=function() return {data=function() return {kind=cancel_sent and "canceled" or "result",ref_id=current_id,value=true,cancel_ok=true} end} end}
local function new_channel() return {receive=function() if cancel_sent then suite_expired=true end; return msg end,case_receive=function(self) return {channel=self,value=msg} end,close=function() end,send=function() end} end
local display = setmetatable({}, {__index=function() return function() end end})
local entry={id="test:one",meta={}}
local entries={entry}
if scenario ~= "unbounded" then entry.meta.suite_timeout="2m"; table.insert(entries,{id="test:two",meta={}}) end
if scenario == "expired_during_teardown" then entry.meta.timeout="1ms" end
if scenario == "conflicting" then entries[2].meta.suite_timeout="3m" end
local modules={
 io={args=function() return nil end}, env={get=function() return nil end}, registry={find=function() return entries end},
 time={now=function() return stamp end,sleep=function() end,MILLISECOND=1,after=function(duration) observe_timeout(duration); local ch=new_channel(); ch.duration=duration; return ch end},
 channel={new=new_channel,select=function(cases)
  if cases.default then
    if suite_expired then return cases[1] end
    return {default=true}
  end
  if scenario == "expired" or scenario == "expired_during_teardown" then
    for _,case in ipairs(cases) do
      if case.channel.duration == (scenario == "expired" and "2m" or "1ms") then return case end
    end
  end
  return cases[1]
 end},
 discovery={group_by_suite=function() return {suite=entries},{} end,sorted_keys=function() return {"suite"} end,short_name=function(id) return id end},
 display=display,verdict={check=function() return nil end},
}
require=function(name) return modules[name] end
coroutine.spawn=function() end
process={listen=new_channel,pid=function() return "parent" end,spawn=function(_,_,args) record_spawn(); current_id=args.entry_id; return "child" end,send=function() cancel_sent=true; return true end,terminate=function() return true end}
`)
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
	expected := "0"
	if scenario == "expired" || scenario == "expired_during_teardown" || scenario == "conflicting" {
		expected = "1"
	}
	if l.Get(-1).String() != expected {
		t.Fatalf("runner failed: %v", l.Get(-1))
	}
	if scenario != "unbounded" && scenario != "conflicting" && suiteTimers != 1 {
		t.Fatalf("suite must have one shared timer, got %d", suiteTimers)
	}
	if (scenario == "expired" || scenario == "expired_during_teardown") && spawns != 1 {
		t.Fatalf("expired suite started %d entries", spawns)
	}
	if scenario == "conflicting" && spawns != 0 {
		t.Fatal("conflicting suite budgets started an entry")
	}
	if guessed {
		t.Fatal("runner imposed an unconfigured 30-second deadline")
	}
}
