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
        _ -> io.println("Unknown action")
      }
    }
    ["jira", "report", ..opts] -> {
      cli.report_issues_command(opts)
      |> string.inspect
      |> io.println
    }
    _ -> io.println_error("Unknown command")
  }
}
