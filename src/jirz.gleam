import gleam/bit_array
import gleam/bool
import gleam/dict
import gleam/httpc
import gleam/io
import gleam/result
import gleam/string
import gleam/uri
import glenvy/dotenv
import glenvy/env
import jira/issue as jira

import gleam/http/request

pub type Error {
  ConfigNotFoundError(String)
  FetchJiraIssuesError
  DecodingError
}

const user = "totsawat@skilllane.com"

pub fn main() {
  let _ = dotenv.load()

  let assert Ok(jira_api_token) = env.get_string("JIRA_API_TOKEN")
  use <- bool.guard(
    jira_api_token == "",
    ConfigNotFoundError("Missing JIRA_API_TOKEN") |> Error,
  )

  let fetch_issues_result =
    fetch_issues(jira_api_token)
    |> result.map_error(fn(_) { FetchJiraIssuesError })

  use resp <- result.try(fetch_issues_result)
  io.debug(resp.body)

  let decode_jira_issues =
    jira.issues_from_json(resp.body)
    |> result.map_error(fn(_) { DecodingError })

  io.debug(decode_jira_issues)
}

fn fetch_issues(jira_api_token: String) {
  let assert Ok(base_req) =
    request.to("https://skilllane.atlassian.net/rest/api/3/search/jql")

  let auth_token =
    user
    |> string.append(":")
    |> string.append(jira_api_token)
    |> bit_array.from_string
    |> bit_array.base64_encode(False)

  let fields =
    [
      "issuetype", "assignee", "priority", "resolutiondate", "status", "summary",
      "customfield_10008", "customfield_10067",
    ]
    |> string.join(",")

  let query =
    dict.new()
    |> dict.insert("fields", fields)
    |> dict.to_list

  let req =
    base_req
    |> request.prepend_header("Authorization", "Basic " <> auth_token)
    |> request.prepend_header("Content-Type", "application/json")
    |> request.set_query([
      #("jql", "project = CBP"),
      #("maxResults", "2"),
      ..query
    ])

  io.debug("Request URI: " <> request.to_uri(req) |> uri.to_string)

  use resp <- result.try(httpc.send(req))
  Ok(resp)
}
