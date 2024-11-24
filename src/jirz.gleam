import argv
import clip
import clip/help
import gleam/io
import gleam/string
import jira/cli as jira_cli

pub fn main() {
  let jira_issues =
    jira_cli.command()
    |> clip.help(help.simple("issues", "List issues"))
    |> clip.run(argv.load().arguments)

  case jira_issues {
    Error(e) -> io.print_error(e)
    Ok(issues) -> issues |> string.inspect |> io.println
  }
}
