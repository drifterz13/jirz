import fmglee
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import glenvy/env
import jira/issue.{type Issues, ListIssuesOption}
import jira/report

pub type Error {
  ConfigNotFoundError(String)
  FetchJiraIssuesError
  GetJiraReportError
  DecodingError
}

const required_fields = [
  "issuetype", "assignee", "priority", "resolutiondate", "status", "summary",
  "customfield_10008", "customfield_10067",
]

const default_total = 100

const base_jql = "project in (CBP) AND created > 2024-06-30"

fn build_jql_query(jql_dict: Dict(String, String)) {
  use projects <- result.try(dict.get(jql_dict, "projects"))
  use assignee <- result.try(dict.get(jql_dict, "assignee"))

  fmglee.new(
    "project in (%s) AND created > 2024-06-30 AND assignee = %s AND sprint in openSprints()",
  )
  |> fmglee.s(projects)
  |> fmglee.s(assignee)
  |> fmglee.try_build
  |> result.replace_error(Nil)
}

fn get_valid_options(opts: List(String)) -> issue.ListIssuesOption {
  let opts_dict =
    list.sized_chunk(opts, 2)
    |> list.filter_map(fn(chunk) {
      case chunk {
        [key, value] -> {
          case key {
            "--fields" | "--total" | "--jql" | "--assignee" | "--projects" ->
              Ok(#(key |> string.replace("--", ""), value))
            _ -> Error(Nil)
          }
        }
        _ -> Error(Nil)
      }
    })
    |> dict.from_list

  let total =
    dict.get(opts_dict, "total")
    |> result.unwrap(int.to_string(default_total))

  let jql =
    {
      case dict.get(opts_dict, "jql") {
        Ok(query) -> query
        Error(_) -> build_jql_query(opts_dict) |> result.unwrap(base_jql)
      }
    }
    |> io.debug

  case dict.get(opts_dict, "fields") {
    Ok(fields) -> {
      let f =
        string.split(fields, ",") |> list.append(required_fields) |> list.unique
      ListIssuesOption(total:, fields: f, jql:)
    }
    Error(_) -> {
      ListIssuesOption(total: total, fields: required_fields, jql:)
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

  use resp <- result.try(fetch_issues_result |> io.debug)

  let decode_jira_issues =
    issue.issues_from_json(resp.body)
    |> result.map_error(fn(err) {
      io.debug(err)
      DecodingError
    })

  use jira_issues <- result.try(decode_jira_issues)
  Ok(jira_issues)
}

pub fn report_issues_command(opts: List(String)) -> Result(report.Report, Error) {
  use list_issues <- result.try(list_issues_command(opts))
  let gen_report = report.generate_report(list_issues.issues)
  Ok(gen_report)
}
