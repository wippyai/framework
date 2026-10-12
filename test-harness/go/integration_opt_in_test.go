// SPDX-License-Identifier: MPL-2.0

package runner_test

import (
	"os"
	"regexp"
	"testing"

	lua "github.com/wippyai/go-lua"
)

// Exercise each provider suite's actual switch expression without executing
// the suite or allowing it to contact a provider.
func TestProviderIntegrationRequiresExplicitOptIn(t *testing.T) {
	files := []string{
		"bedrock/integration_test.lua", "claude/integration_test.lua",
		"google/integration_test.lua", "openai/integration_test.lua",
		"openai_compat/integration_test.lua", "typesafe/integration_test.lua",
		"util/compress_test.lua",
	}
	declaration := regexp.MustCompile(`(?m)^\s*local RUN_INTEGRATION_TESTS = (.+)$`)
	scenarios := []struct {
		name    string
		flags   map[string]string
		enabled bool
	}{
		{name: "unset"},
		{name: "false", flags: map[string]string{"ENABLE_INTEGRATION_TESTS": "false"}},
		{name: "zero", flags: map[string]string{"ENABLE_INTEGRATION_TESTS": "0"}},
		{name: "other", flags: map[string]string{"ENABLE_INTEGRATION_TESTS": "yes"}},
		{name: "true", flags: map[string]string{"ENABLE_INTEGRATION_TESTS": "true"}, enabled: true},
		{name: "typesafe_false", flags: map[string]string{"TYPESAFE_INTEGRATION_TESTS": "false"}},
		{name: "typesafe_true", flags: map[string]string{"TYPESAFE_INTEGRATION_TESTS": "true"}},
	}
	for _, file := range files {
		t.Run(file, func(t *testing.T) {
			source, err := os.ReadFile("../../src/llm/test/" + file)
			if err != nil {
				t.Fatal(err)
			}
			expression := declaration.FindSubmatch(source)
			if len(expression) != 2 {
				t.Fatal("integration switch declaration is missing")
			}
			for _, scenario := range scenarios {
				t.Run(scenario.name, func(t *testing.T) {
					l := lua.NewState()
					defer l.Close()
					env := l.NewTable()
					env.RawSetString("get", l.NewFunction(func(l *lua.LState) int {
						value, ok := scenario.flags[l.CheckString(1)]
						if ok {
							l.Push(lua.LString(value))
						} else {
							l.Push(lua.LNil)
						}
						return 1
					}))
					l.SetGlobal("env", env)
					if err := l.DoString("return not not (" + string(expression[1]) + ")"); err != nil {
						t.Fatal(err)
					}
					enabled := scenario.enabled || (file == "typesafe/integration_test.lua" && scenario.name == "typesafe_true")
					if got := l.Get(-1); got != lua.LBool(enabled) {
						t.Fatalf("integration switch returned %v (%s), want boolean %v", got, got.Type(), enabled)
					}
				})
			}
		})
	}
}
