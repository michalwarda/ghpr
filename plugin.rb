require 'net/http'
require 'json'

Neovim.plugin do |plug|
  state = {
    previous_buffer: nil,
    previous_line: nil,
    branch: nil,
    pull_request: nil,
    comments: nil,
  }

  comments = {}

  plug.command(:SetBranch, nargs: 0) do |nvim|
    dir = nvim.command_output("pwd").strip
    state[:branch] = %x(cd #{dir} && git rev-parse --abbrev-ref HEAD).strip
  end

  plug.command(:PlaceSigns, nargs: 0) do |nvim|
    # Get branch
    dir = nvim.command_output("pwd").strip
    state[:branch] = %x(cd #{dir} && git rev-parse --abbrev-ref HEAD).strip
    # Check for PR
    res = Net::HTTP.get_response(URI("https://api.github.com/repos/michalwarda/ghpr/pulls?access_token=e4509d0c10f99eab95a3593ec237793f4e1a3c80&head=michalwarda:#{state[:branch]}"))
    state[:pull_request] =
      if res.code == "200"
        body = JSON.parse(res.body)
        body[0]["number"] unless body.empty?
      end
    # Get Comments
    if state[:pull_request]
      res = Net::HTTP.get_response(URI("https://api.github.com/repos/michalwarda/ghpr/pulls/#{state[:pull_request]}/comments?access_token=e4509d0c10f99eab95a3593ec237793f4e1a3c80"))
      state[:comments] = JSON.parse(res.body) if res.code == "200"
    end
    # Get comment positions
    state[:comments].each do |comment|
      starting_line = comment["diff_hunk"].split("\n")[0].split(" ")[1].split(",")[0].to_i.abs
      starting_line = 0 if starting_line == 1
      line = (comment["diff_hunk"].split("\n")[1..-1].reduce(0) { |acc, line| line[0] == "-" ? acc : (acc + 1) }) + starting_line
      comments[line] = { text: comment["body"] }
    end

    comments.each do |line, comment|
      nvim.command("sign place #{line + 666} line=#{line} name=neomake_err file=#{nvim.current.buffer.name}")
    end
  end

  plug.command(:UnplaceSigns, nargs: 0) do |nvim|
    comments.each do |line, _comment|
      nvim.command("sign unplace #{line + 666}")
    end
  end

  plug.command(:EchoState, nargs: 1) do |nvim, attr|
    nvim.command("echo '#{state[attr.to_sym]}'")
  end

  plug.autocmd(:BufEnter) do |nvim|
    nvim.command_output("PlaceSigns")
  end

  plug.autocmd(:BufWrite) do |nvim|
  end

  plug.autocmd(:CursorMoved) do |nvim|
    new_buffer = nvim.current.buffer
    new_line = nvim.current.buffer.line_number
    comment = comments[new_line]

    if comment && (new_buffer != state[:previous_buffer] || new_line != state[:previous_line])
      nvim.command("echo 'GHPR: #{comment[:text]}'")
    end

    state[:previous_buffer] = new_buffer
    state[:previous_line] = new_line
  end
end
