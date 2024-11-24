import gleam/option
import gleeunit/should
import jira/issue.{
  Assignee, Issue, IssueField, IssueType, Issues, Priority, Sprint, Status,
  issues_from_json,
}

pub fn issues_decode_test() {
  let issues_string =
    "{
  \"issues\": [
    {
      \"id\": \"30709\",
      \"key\": \"CBP-206\",
      \"fields\": {
        \"summary\": \"[Backend] - Support internal package (type, constant)\",
        \"issuetype\": {
          \"id\": \"10041\",
          \"description\": \"Tasks track small, distinct pieces of work.\",
          \"name\": \"Task\"
        },
        \"customfield_10008\": [
          {
            \"id\": 756,
            \"name\": \"CBP Sprint 1\",
            \"state\": \"active\"
          }
        ],
        \"resolutiondate\": null,
        \"assignee\": {
          \"avatarUrls\": {
            \"32x32\": \"https://secure.gravatar.com/avatar/614b07c58892cb2d9be2cfaf1631f34a?d=https%3A%2F%2Favatar-management--avatars.us-west-2.prod.public.atl-paas.net%2Finitials%2FS-4.png\"
          },
          \"displayName\": \"sarida\"
        },
        \"priority\": {
          \"name\": \"Medium\",
          \"id\": \"3\"
        },
        \"customfield_10067\": null,
        \"status\": {
          \"name\": \"To Do\",
          \"id\": \"10070\"
        }
      }
    }
  ]
}"

  issues_from_json(issues_string)
  |> should.be_ok()
  |> should.equal(
    Issues(issues: [
      Issue(
        key: "CBP-206",
        fields: IssueField(
          summary: "[Backend] - Support internal package (type, constant)",
          issue_type: IssueType(name: "Task"),
          sprint: option.Some([Sprint(id: 756, name: "CBP Sprint 1")]),
          resolved_date: option.None,
          assignee: Assignee(display_name: "sarida") |> option.Some,
          priority: Priority(name: "Medium") |> option.Some,
          status: Status(id: "10070", name: "To Do"),
          story_points: option.None,
        ),
      ),
    ]),
  )
}
