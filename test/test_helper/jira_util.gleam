import gleam/option
import jira/issue as jira
import jira/report.{type IssueType}

pub fn create_mock_issue(
  issue_type: IssueType,
  key key: String,
  summary summary: String,
  status status: String,
  story_points points: Float,
) -> jira.Issue {
  jira.Issue(
    key:,
    fields: jira.IssueField(
      summary:,
      issue_type: jira.IssueType(name: get_issue_type(issue_type)),
      sprint: option.Some([jira.Sprint(id: 756, name: "Test Sprint")]),
      resolved_date: option.None,
      assignee: jira.Assignee(display_name: "Tester") |> option.Some,
      priority: jira.Priority(name: "Medium") |> option.Some,
      status: jira.Status(id: "1234", name: status),
      story_points: option.Some(points),
    ),
  )
}

/// TODO: Simplify issue type
fn get_issue_type(issue_type: IssueType) -> String {
  case issue_type {
    report.Bug -> "Bug"
    report.Story -> "Story"
    report.Task -> "Task"
  }
}
