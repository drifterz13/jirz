import clip
import clip/opt
import gleam/bool
import gleam/result
import glenvy/dotenv
import glenvy/env
import jira/issue

pub type Error {
  ConfigNotFoundError(String)
  FetchJiraIssuesError
  DecodingError
}

pub fn command() {
  let _ = dotenv.load()

  clip.command({
    use total <- clip.parameter

    let assert Ok(jira_api_token) = env.get_string("JIRA_API_TOKEN")
    use <- bool.guard(
      jira_api_token == "",
      ConfigNotFoundError("Missing JIRA_API_TOKEN") |> Error,
    )

    let fields = [
      "issuetype", "assignee", "priority", "resolutiondate", "status", "summary",
      "customfield_10008", "customfield_10067",
    ]

    let fetch_issues_result =
      issue.fetch_issues(api_token: jira_api_token, total:, fields:)
      |> result.map_error(fn(_) { FetchJiraIssuesError })

    use resp <- result.try(fetch_issues_result)

    let decode_jira_issues =
      issue.issues_from_json(resp.body)
      |> result.map_error(fn(_) { DecodingError })

    use jira_issues <- result.try(decode_jira_issues)
    Ok(jira_issues)
  })
  |> clip.opt(opt.new("total") |> opt.int |> opt.help("Total results"))
}
