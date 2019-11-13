defmodule Tmate.UserMailer do
  import Bamboo.Email

  def api_key_email(%{email: email, username: _username, api_key: api_key}) do
    new_email(
      to: email,
      from: "tmate <support@tmate.io>",
      subject: "Your tmate API key",
      text_body:
"Dear tmate user,

Your API key is: #{api_key}

You can use it to name sessions as such:

From the CLI:
  tmate -k #{api_key} -n testname

Or from the ~/.tmate.conf file:
  set tmate-api-key \"#{api_key}\"
  set tmate-session-name \"testname\"

It is also useful to put the API key in the tmate configuration file,
and specify the session name on the CLI.

Note that tmate version should be at least 2.4.0.
Check tmate version by running: tmate -V

More information can be found at https://tmate.io/#named_sessions

Good day,
Jackie the tmate robot
")
  end
end
