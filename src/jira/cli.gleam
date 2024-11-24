import gleam/bool
import gleam/dict
import gleam/list
import gleam/result
import gleam/string
import glenvy/env
import jira/issue.{type Issues, ListIssuesOption}

pub type Error {
  ConfigNotFoundError(String)
  FetchJiraIssuesError
  DecodingError
}

const required_fields = [
  "issuetype", "assignee", "priority", "resolutiondate", "status", "summary",
  "customfield_10008", "customfield_10067",
]

fn get_valid_options(opts: List(String)) {
  let opts_dict =
    list.sized_chunk(opts, 2)
    |> list.filter_map(fn(chunk) {
      case chunk {
        [key, value] -> {
          case key {
            "--fields" | "--total" -> Ok(#(key, value))
            _ -> Error(Nil)
          }
        }
        _ -> Error(Nil)
      }
    })
    |> dict.from_list

  let total =
    dict.get(opts_dict, "--total")
    |> result.unwrap("10")

  case dict.get(opts_dict, "--fields") {
    Ok(fields) -> {
      let f =
        string.split(fields, ",") |> list.append(required_fields) |> list.unique
      ListIssuesOption(total:, fields: f)
    }
    Error(_) -> {
      ListIssuesOption(total: total, fields: required_fields)
    }
  }
}

pub fn list_issues_command(opts: List(String)) -> Result(Issues, Error) {
  let assert Ok(jira_api_token) = env.get_string("JIRA_API_TOKEN")
  use <- bool.guard(
    jira_api_token == "",
    ConfigNotFoundError("Missing JIRA_API_TOKEN") |> Error,
  )

  let fetch_issues_result = {
    let valid_opts = get_valid_options(opts)

    issue.fetch_issues(api_token: jira_api_token, opts: valid_opts)
    |> result.map_error(fn(_) { FetchJiraIssuesError })
  }

  use resp <- result.try(fetch_issues_result)

  // io.debug(resp.body)

  let decode_jira_issues =
    issue.issues_from_json(resp.body)
    |> result.map_error(fn(_) { DecodingError })

  use jira_issues <- result.try(decode_jira_issues)
  Ok(jira_issues)
}
