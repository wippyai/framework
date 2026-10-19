// SPDX-License-Identifier: MPL-2.0

package runner_test

import (
	"os"
	"testing"
	"testing/synctest"

	lua "github.com/wippyai/go-lua"
)

func TestRunnerCancellationWaitsForFutureBeforeAcknowledging(t *testing.T) {
	sourcePath := "../../src/test/runner_entry.lua"
	if baseline := os.Getenv("RUNNER_SOURCE_ROOT"); baseline != "" {
		sourcePath = baseline + "/runner_entry.lua"
	}
	source, err := os.ReadFile(sourcePath)
	if err != nil {
		t.Fatal(err)
	}
	synctest.Test(t, func(t *testing.T) {
		teardown := make(chan struct{})
		done := make(chan error, 1)
		acknowledged := false
		l := lua.NewState()
		defer l.Close()
		l.SetGlobal("wait_teardown", l.NewFunction(func(l *lua.LState) int { <-teardown; return 0 }))
		l.SetGlobal("acknowledge", l.NewFunction(func(l *lua.LState) int { acknowledged = true; return 0 }))
		if err := l.DoString(`
local response = {case_receive = function(self) return {channel=self} end, receive=function() wait_teardown(); return nil,true end}
local cancel_inbox = {case_receive=function(self) return {channel=self} end}
local cmd = {response=function() return response end, cancel=function() return true end}
local executor = {with_context=function(self) return self end, async=function() return cmd end}
local modules = {
 funcs={new=function() return executor end},
 channel={select=function(cases) if cases[1].channel == response and cases[2].channel == cancel_inbox then return {channel=cancel_inbox} end; return {channel=cases[2].channel} end},
 time={after=function() return {case_receive=function(self) return {channel=self} end} end},
}
require=function(name) return modules[name] end
process={listen=function(topic) if topic == "runner:cancel" then return cancel_inbox end; return {receive=function() end} end,
 send=function(_,_,data) if data.kind == "canceled" then acknowledge() end end}
`); err != nil {
			t.Fatal(err)
		}
		go func() {
			err := l.DoString(string(source))
			if err == nil {
				module := l.Get(-1).(*lua.LTable)
				args := l.NewTable()
				args.RawSetString("parent_pid", lua.LString("parent"))
				args.RawSetString("entry_id", lua.LString("entry"))
				err = l.CallByParam(lua.P{Fn: module.RawGetString("run"), NRet: 0, Protect: true}, args)
			}
			done <- err
		}()
		synctest.Wait()
		if acknowledged {
			close(teardown)
			<-done
			t.Fatal("runner acknowledged cancellation before future completion")
		}
		close(teardown)
		if err := <-done; err != nil {
			t.Fatal(err)
		}
		if !acknowledged {
			t.Fatal("runner did not acknowledge cancellation after future completion")
		}
	})
}
