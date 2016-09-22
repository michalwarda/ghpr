require 'net/http'

Neovim.plugin do |plug|
  comments = { 5 => { text: "This is a comment." } }

  plug.command(:PlaceSigns, nargs: 0) do |nvim|
    res = Net::HTTP.get_response(URI('https://api.github.com/repos/michalwarda/ghpr/pulls'))

    comments.each do |line, _comment|
      nvim.command("sign place #{line + 666} line=#{line} name=neomake_err file=#{nvim.current.buffer.name}")
    end
  end

  plug.command(:UnplaceSigns, nargs: 0) do |nvim|
    comments.each do |line, _comment|
      nvim.command("sign unplace #{line + 666}")
    end
  end

  plug.autocmd(:BufEnter) do |nvim|
    nvim.command('UnplaceSigns')
    nvim.command('PlaceSigns')
  end

  plug.autocmd(:BufWrite) do |nvim|
    nvim.command('UnplaceSigns')
    nvim.command('PlaceSigns')
  end

  state = {
    previous_buffer: nil,
    previous_line: nil,
  }

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
