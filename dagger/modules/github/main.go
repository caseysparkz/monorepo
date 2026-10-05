// A generated module for Github functions
//
// This module performs specific operations against GitHub objects (pull requests, issues, etc.).

package main

import (
	"context"
	"dagger/github/internal/dagger"
	//"fmt"
	"maps"
	"slices"
	"strings"
)

var mountPoint = "/mnt"
var validTypes = []string{ // Valid commit types
	"build",
	"chore",
	"ci",
	"docs",
	"feat",
	"fix",
	"perf",
	"refactor",
	"revert",
	"style",
	"test",
}

// New - Default options for the GitHub Dagger module.
func New(
	// GitHub Token
	githubToken *dagger.Secret,
	// Repository root dir.
	// +optional
	// +defaultPath="/"
	// +ignore["*cache*",".coverage",".env",".terraform/",".venv","build/","dist/","node_modules/","*.log"]
	source *dagger.Directory,
) *Github {
	return &Github{
		GithubToken: githubToken,
		Source:      source,
	}
}

// Github - the Dagger GitHub module
type Github struct {
	GithubToken *dagger.Secret
	Source      *dagger.Directory
}

// Get the intersection of two slices
func (m *Github) getPrCommitTypes(ctx context.Context) []string {
	commitTypes := make(map[string]bool)

	var stdout, stderr = m.container().
		WithExec([]string{"gh", "pr", "view", "--json", "commits", "-q", ".commits[].messageHeadline"}).
		Stdout(ctx)

	if stderr != nil {
		return []string{}
	}

	commitLog := strings.Split(stdout, "\n")

	for k := range commitLog { // Parse commit log to map of valid types
		for j := range validTypes {
			if strings.HasPrefix(commitLog[k], validTypes[j]) { // Remove invalid commit types from log
				commitTypes[validTypes[j]] = true
			}
		}
	}

	return slices.Collect(maps.Keys(commitTypes)) // Cast map to slice
}

// Returns a container with an initialized Git repository, and the GH CLI tool
func (m *Github) container() *dagger.Container {
	return dag.Container().
		From("770088062852.dkr.ecr.us-west-2.amazonaws.com/dagger_github:0.0.1").
		WithMountedDirectory(
			mountPoint,
			m.Source,
			dagger.ContainerWithMountedDirectoryOpts{Owner: "app"},
		).
		WithWorkdir(mountPoint).
		WithSecretVariable("GH_TOKEN", m.GithubToken)
}

// LabelPr - Automatically applies labels to a pull request
// +check
func (m *Github) LabelPr(ctx context.Context) (string, error) {
	commitTypes := m.getPrCommitTypes(ctx)

	if len(commitTypes) == 0 {
		return "", nil
	}

	return m.container().
		WithExec([]string{"gh", "pr", "edit", "--add-label", strings.Join(commitTypes, ",")}). // Label PR
		Stdout(ctx)
}
