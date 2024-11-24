import gleam/list
import gleam/option
import gleam/string
import jira/issue.{type Issue, IssueType as RawIssueType}

pub type IssueType {
  Bug
  Story
  Task
}

pub type IssueStat {
  IssueStat(assigned: Int, done: Int)
}

pub type CompactIssue {
  CompactIssue(
    key: String,
    summary: String,
    issue_type: IssueType,
    done: Bool,
    points: option.Option(Float),
  )
}

pub type IssueSummary {
  IssueSummary(issues: List(CompactIssue), stats: IssueStat)
}

pub type Report {
  Report(
    total_issues: Int,
    total_points: Float,
    bugs: IssueSummary,
    tasks: IssueSummary,
    stories: IssueSummary,
  )
}

pub fn generate_report(issues: List(Issue)) -> Report {
  let total_issues = list.length(issues)
  let total_points =
    list.fold(issues, 0.0, fn(acc, issue) {
      case issue.fields.story_points {
        option.None -> acc
        option.Some(points) -> acc +. points
      }
    })
  Report(
    total_issues: total_issues,
    total_points: total_points,
    bugs: to_issues_summary(issues, Bug),
    tasks: to_issues_summary(issues, Task),
    stories: to_issues_summary(issues, Story),
  )
}

pub fn to_issues_summary(
  issues: List(Issue),
  issue_type: IssueType,
) -> IssueSummary {
  let filtered_issues = get_filter_issues(issues, issue_type)
  let stats =
    IssueStat(
      assigned: list.length(filtered_issues),
      done: filtered_issues
        |> list.filter(is_issue_done)
        |> list.length,
    )

  let compact_issues = {
    filtered_issues
    |> list.map(fn(issue) { to_compact_issue(issue, issue_type) })
  }
  IssueSummary(issues: compact_issues, stats: stats)
}

fn to_compact_issue(issue: Issue, issue_type: IssueType) -> CompactIssue {
  CompactIssue(
    key: issue.key,
    issue_type:,
    summary: issue.fields.summary,
    done: is_issue_done(issue),
    points: issue.fields.story_points,
  )
}

fn is_issue_done(issue: Issue) -> Bool {
  let issue_type = string.lowercase(issue.fields.issue_type.name)
  let issue_status = string.lowercase(issue.fields.status.name)

  case issue_type {
    "bug" -> issue_status == "done"
    "task" | "story" -> ["deploying", "done"] |> list.contains(issue_status)
    _ -> False
  }
}

fn get_filter_issues(issues: List(Issue), issue_type: IssueType) -> List(Issue) {
  let issue_type = {
    case issue_type {
      Bug -> RawIssueType(name: "Bug")
      Story -> RawIssueType(name: "Story")
      Task -> RawIssueType(name: "Task")
    }
  }

  issues
  |> list.filter(fn(issue) { issue.fields.issue_type == issue_type })
}
