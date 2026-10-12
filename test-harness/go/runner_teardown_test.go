// SPDX-License-Identifier: MPL-2.0

package runner_test

import (
	"os"
	"testing"
	"testing/synctest"

	lua "github.com/wippyai/go-lua"
)

// Run both actual Lua sources with controlled cancellation and future completion.
// The expired entry cannot acknowledge or let the runner start its successor
// while its execution-frame teardown is still blocked.
func TestExpiredEntryTeardownCompletesBeforeNextEntry(t *testing.T) {
	root := "../../src/test"
	if baseline := os.Getenv("RUNNER_SOURCE_ROOT"); baseline != "" {
		root = baseline
	}
	runnerSource, err := os.ReadFile(root + "/runner.lua")
	if err != nil {
		t.Fatal(err)
	}
	entrySource, err := os.ReadFile(root + "/runner_entry.lua")
	if err != nil {
		t.Fatal(err)
	}
	synctest.Test(t, func(t *testing.T) {
		teardown := make(chan struct{})
		cancelRequested := make(chan struct{})
		acknowledged := make(chan struct{})
		childDone := make(chan error, 1)
		runnerDone := make(chan error, 1)
		teardownFinished := false
		ackOK := false
		startedEarly := false
		spawns := 0
		child := lua.NewState()
		defer child.Close()
		child.SetGlobal("wait_cancel", child.NewFunction(func(l *lua.LState) int { <-cancelRequested; return 0 }))
		child.SetGlobal("finish_teardown", child.NewFunction(func(l *lua.LState) int {
			<-teardown
			teardownFinished = true
			return 0
		}))
		child.SetGlobal("acknowledge", child.NewFunction(func(l *lua.LState) int {
			ackOK = l.CheckTable(1).RawGetString("cancel_ok") == lua.LTrue
			close(acknowledged)
			return 0
		}))
		if err := child.DoString(`
local response = {case_receive=function(self) return {channel=self} end, receive=function() finish_teardown() end}
local inbox = {case_receive=function(self) return {channel=self} end}
local cmd = {response=function() return response end, cancel=function() return true end}
local executor = {with_context=function(self) return self end, async=function() return cmd end}
local modules = {funcs={new=function() return executor end}, channel={select=function(cases) if cases[2].channel == inbox then wait_cancel(); return {channel=inbox} end; return cases[1] end},
 time={after=function() return {case_receive=function(self) return {channel=self} end} end}}
require=function(name) return modules[name] end
process={listen=function(topic) if topic == "runner:cancel" then return inbox end; return {receive=function() end} end,
 send=function(_,_,data) acknowledge(data); return true end}
`); err != nil {
			t.Fatal(err)
		}
		runner := lua.NewState()
		defer runner.Close()
		runner.SetGlobal("launch_entry", runner.NewFunction(func(l *lua.LState) int {
			spawns++
			if spawns == 2 {
				startedEarly = !teardownFinished
				return 0
			}
			go func() {
				err := child.DoString(string(entrySource))
				if err == nil {
					module := child.Get(-1).(*lua.LTable)
					args := child.NewTable()
					args.RawSetString("parent_pid", lua.LString("parent"))
					args.RawSetString("entry_id", lua.LString("test:expired"))
					err = child.CallByParam(lua.P{Fn: module.RawGetString("run"), NRet: 0, Protect: true}, args)
				}
				childDone <- err
			}()
			return 0
		}))
		runner.SetGlobal("request_cancel", runner.NewFunction(func(l *lua.LState) int { close(cancelRequested); return 0 }))
		runner.SetGlobal("wait_ack", runner.NewFunction(func(l *lua.LState) int { <-acknowledged; l.Push(lua.LBool(ackOK)); return 1 }))
		if err := runner.DoString(`
local current_id = "test:expired"
local stamp = {sub=function(self) return self end, milliseconds=function() return 0 end}
local function message(kind, cancel_ok) return {from=function() return "child" end, payload=function() return {data=function() return {kind=kind,ref_id=current_id,value=true,cancel_ok=cancel_ok} end} end} end
local function new_channel() return {receive=function() if current_id=="test:expired" then return message("canceled", wait_ack()) end; return message("result") end,
 case_receive=function(self) return {channel=self,value=message("result")} end,close=function() end,send=function() end} end
local entries={{id="test:expired",meta={timeout="1ms"}},{id="test:next",meta={}}}
local modules={
 io={args=function() end},env={get=function() return nil end},registry={find=function() return entries end},
 time={now=function() return stamp end,sleep=function() end,MILLISECOND=1,after=function(duration) local ch=new_channel();ch.duration=duration;return ch end},
 channel={new=new_channel,select=function(cases) if current_id=="test:expired" then for _,case in ipairs(cases) do if case.channel.duration then return case end end end;return cases[1] end},
 discovery={group_by_suite=function() return {suite=entries},{} end, sorted_keys=function() return {"suite"} end,short_name=function(id) return id end},
 display=setmetatable({}, {__index=function() return function() end end}), verdict={check=function() end},
}
require=function(name) return modules[name] end
coroutine.spawn=function() end
process={pid=function() return "parent" end,listen=new_channel,
 spawn=function(_,_,args) current_id=args.entry_id;launch_entry();return "child" end,
 send=function() request_cancel();return true end,terminate=function() return true end}
`); err != nil {
			t.Fatal(err)
		}
		go func() {
			err := runner.DoString(string(runnerSource))
			if err == nil {
				module := runner.Get(-1).(*lua.LTable)
				err = runner.CallByParam(lua.P{Fn: module.RawGetString("main"), NRet: 1, Protect: true})
			}
			runnerDone <- err
		}()
		synctest.Wait()
		spawnsBeforeTeardown := spawns
		close(teardown)
		err := <-runnerDone
		if spawns == 0 {
			t.Fatalf("runner did not start entry: %v", err)
		}
		childErr := <-childDone
		if err != nil {
			t.Fatal(err)
		}
		if childErr != nil {
			t.Fatal(childErr)
		}
		if spawnsBeforeTeardown != 1 || startedEarly {
			t.Fatal("runner started the next case before the expired case finished teardown")
		}
		if spawns != 2 {
			t.Fatalf("expected successor case to start after teardown, got %d entries", spawns)
		}
	})
}
