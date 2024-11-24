import gleam/bit_array
import gleam/dict
import gleam/dynamic.{field, float, int, string}
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json.{type DecodeError}
import gleam/option.{type Option}
import gleam/result
import gleam/string
import gleam/uri

pub type Issues {
  Issues(issues: List(Issue))
}

pub type Issue {
  Issue(key: String, fields: RawIssueField)
}

pub type RawIssueField {
  RawIssueField(
    summary: String,
    issuetype: IssueType,
    customfield_10008: List(Sprint),
    resolutiondate: Option(String),
    assignee: Assignee,
    priority: Priority,
    status: Status,
    customfield_10067: Option(Float),
  )
}

pub type Sprint {
  Sprint(id: Int, name: String)
}

pub type IssueType {
  IssueType(name: String)
}

pub type Assignee {
  Assignee(display_name: String)
}

pub type Priority {
  Priority(name: String)
}

pub type Status {
  Status(id: String, name: String)
}

fn issue_type_decoder() -> dynamic.Decoder(IssueType) {
  dynamic.decode1(IssueType, field("name", of: string))
}

fn sprint_decoder() -> dynamic.Decoder(Sprint) {
  dynamic.decode2(Sprint, field("id", of: int), field("name", of: string))
}

fn assignee_decoder() -> dynamic.Decoder(Assignee) {
  dynamic.decode1(Assignee, field("displayName", of: string))
}

fn priority_decoder() -> dynamic.Decoder(Priority) {
  dynamic.decode1(Priority, field("name", of: string))
}

fn status_decoder() -> dynamic.Decoder(Status) {
  dynamic.decode2(Status, field("id", of: string), field("name", of: string))
}

fn issue_fields_decoder() -> dynamic.Decoder(RawIssueField) {
  dynamic.decode8(
    RawIssueField,
    field("summary", of: string),
    field("issuetype", of: issue_type_decoder()),
    field("customfield_10008", of: dynamic.list(sprint_decoder())),
    field("resolutiondate", of: dynamic.optional(string)),
    field("assignee", of: assignee_decoder()),
    field("priority", of: priority_decoder()),
    field("status", of: status_decoder()),
    field("customfield_10067", of: dynamic.optional(float)),
  )
}

pub fn issue_decoder() -> dynamic.Decoder(Issue) {
  dynamic.decode2(
    Issue,
    field("key", of: string),
    field("fields", of: issue_fields_decoder()),
  )
}

pub fn issues_from_json(json_string: String) -> Result(Issues, DecodeError) {
  let issue_list_decoder =
    dynamic.decode1(Issues, field("issues", of: dynamic.list(issue_decoder())))

  json.decode(json_string, issue_list_decoder)
}

const user = "totsawat@skilllane.com"

pub fn fetch_issues(jira_api_token: String) {
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
