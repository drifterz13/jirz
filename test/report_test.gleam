import gleam/list
import gleam/option
import gleeunit/should
import jira/report.{Bug, Story, Task}
import test_helper/jira_util

pub fn to_issues_summary_test() {
  let issues = [
    jira_util.create_mock_issue(
      Story,
      key: "STORY-001",
      summary: "Create report CLI from Gleam",
      status: "Deploying",
      story_points: 3.0,
    ),
    jira_util.create_mock_issue(
      Task,
      key: "TASK-001",
      summary: "Migrate code to Gleam",
      status: "To Do",
      story_points: 1.0,
    ),
  ]

  issues
  |> report.to_issues_summary(Story)
  |> should.equal(report.IssueSummary(
    issues: [
      report.CompactIssue(
        key: "STORY-001",
        summary: "Create report CLI from Gleam",
        issue_type: Story,
        done: True,
        points: option.Some(3.0),
      ),
    ],
    stats: report.IssueStat(assigned: 1, done: 1),
  ))

  issues
  |> report.to_issues_summary(Task)
  |> should.equal(report.IssueSummary(
    issues: [
      report.CompactIssue(
        key: "TASK-001",
        summary: "Migrate code to Gleam",
        issue_type: Task,
        done: False,
        points: option.Some(1.0),
      ),
    ],
    stats: report.IssueStat(assigned: 1, done: 0),
  ))
}

pub fn generate_report_test() {
  let stories = [
    #(Story, "STORY-002", "Story 2", "DEPLOYING", 2.0),
    #(Story, "STORY-003", "Story 3", "REVIEWING", 3.0),
    #(Story, "STORY-004", "Story 4", "DONE", 4.0),
  ]
  let bugs = [
    #(Bug, "BUG-001", "Bug 1", "DONE", 0.0),
    #(Bug, "BUG-002", "Bug 2", "DEPLOYING", 0.0),
  ]
  let tasks = [
    #(Task, "TASK-001", "Task 1", "DONE", 2.0),
    #(Task, "TASK-002", "Task 2", "DEPLOYING", 1.0),
  ]
  let issues =
    [stories, tasks, bugs]
    |> list.flatten
    |> list.map(fn(issue) {
      let #(issue_type, key, summary, status, story_points) = issue
      jira_util.create_mock_issue(
        issue_type,
        key:,
        summary:,
        status:,
        story_points:,
      )
    })

  issues
  |> report.generate_report
  |> should.equal(report.Report(
    total_issues: 7,
    total_points: 12.0,
    bugs: report.IssueSummary(
      issues: [
        report.CompactIssue(
          key: "BUG-001",
          summary: "Bug 1",
          issue_type: Bug,
          done: True,
          points: option.Some(0.0),
        ),
        report.CompactIssue(
          key: "BUG-002",
          summary: "Bug 2",
          issue_type: Bug,
          done: False,
          points: option.Some(0.0),
        ),
      ],
      stats: report.IssueStat(assigned: 2, done: 1),
    ),
    stories: report.IssueSummary(
      issues: [
        report.CompactIssue(
          key: "STORY-002",
          summary: "Story 2",
          issue_type: Story,
          done: True,
          points: option.Some(2.0),
        ),
        report.CompactIssue(
          key: "STORY-003",
          summary: "Story 3",
          issue_type: Story,
          done: False,
          points: option.Some(3.0),
        ),
        report.CompactIssue(
          key: "STORY-004",
          summary: "Story 4",
          issue_type: Story,
          done: True,
          points: option.Some(4.0),
        ),
      ],
      stats: report.IssueStat(assigned: 3, done: 2),
    ),
    tasks: report.IssueSummary(
      issues: [
        report.CompactIssue(
          key: "TASK-001",
          summary: "Task 1",
          issue_type: Task,
          done: True,
          points: option.Some(2.0),
        ),
        report.CompactIssue(
          key: "TASK-002",
          summary: "Task 2",
          issue_type: Task,
          done: True,
          points: option.Some(1.0),
        ),
      ],
      stats: report.IssueStat(assigned: 2, done: 2),
    ),
  ))
}
