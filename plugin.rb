require 'json'

Neovim.plugin do |plug|
  state = {
    previous_buffer: nil,
    previous_line: nil,
  }

  comments = {
    5 => { text: 'To nie ma sensu' }
  }

  # Define an autocmd for the BufEnter event on Ruby files.
  plug.autocmd(:BufEnter) do |nvim|
    comments.each do |line, _comment|
      nvim.command("sign place 2 line=#{line} name=neomake_warn file=#{nvim.current.buffer.name}")
    end
  end

  plug.autocmd(:CursorMoved) do |nvim|
    new_buffer = nvim.current.buffer
    new_line = nvim.current.buffer.line_number
    comment = comments[new_line]

    if comment && (new_buffer != state[:previous_buffer] || new_line != state[:previous_line])
      nvim.command("echo 'PR: #{comment[:text]}'")
    end

    state[:previous_buffer] = new_buffer
    state[:previous_line] = new_line
  end
end
