import argv
import gleam/io
import gleam/string
import glenvy/dotenv
import jira/cli

pub fn main() {
  let _ = dotenv.load()

  case argv.load().arguments {
    ["jira", "issues", ..opts] -> {
      case opts {
        ["list", ..params] -> {
          params |> string.inspect |> io.println
          cli.list_issues_command(params)
          |> string.inspect
          |> io.println
        }
        ["report", ..params] -> {
          let report_params = [
            "--jql",
            "project in (CBP) AND created > 2024-06-30 AND assignee = thearrawit AND sprint in openSprints()",
            ..params
          ]
          cli.report_issues_command(report_params)
          |> string.inspect
          |> io.println
        }
        _ -> io.println("Unknown action")
      }
    }
    _ -> io.println_error("Unknown command")
  }
}
