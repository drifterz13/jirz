import gleam/bool
import gleam/io
import gleam/result
import glenvy/dotenv
import glenvy/env
import jira/issue as jira

pub type Error {
  ConfigNotFoundError(String)
  FetchJiraIssuesError
  DecodingError
}

pub fn main() {
  let _ = dotenv.load()

  let assert Ok(jira_api_token) = env.get_string("JIRA_API_TOKEN")
  use <- bool.guard(
    jira_api_token == "",
    ConfigNotFoundError("Missing JIRA_API_TOKEN") |> Error,
  )

  let fetch_issues_result =
    jira.fetch_issues(jira_api_token)
    |> result.map_error(fn(_) { FetchJiraIssuesError })

  use resp <- result.try(fetch_issues_result)

  let decode_jira_issues =
    jira.issues_from_json(resp.body)
    |> result.map_error(fn(_) { DecodingError })

  io.debug(decode_jira_issues)
}
