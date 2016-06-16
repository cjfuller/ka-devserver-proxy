defmodule Proxy do
  use Plug.Builder
  import Plug.Conn

  @kake_target "http://localhost:5000"
  @default_target "http://localhost:8080"

  plug Plug.Logger
  plug Plug.Static, at: "/images", from: Path.expand("~/khan/webapp/images")
  plug :dispatch

  def start(_argv) do
    port = 8081
    IO.puts "Running Proxy with Cowboy on http://localhost:#{port}"
    Plug.Adapters.Cowboy.http __MODULE__, [], port: port
    :timer.sleep(:infinity)
  end

  def dispatch(conn, _opts) do
    # Start a request to the client saying we will stream the body.
    # We are simply passing all req_headers forward.
    method = (
      conn.method
      |> String.downcase
      |> String.to_atom)
    {:ok, client} = :hackney.request(method, uri(conn), conn.req_headers, :stream, [])

    conn
    |> write_proxy(client)
    |> read_proxy(client)
  end

  # Reads the connection body and write it to the
  # client recursively.
  defp write_proxy(conn, client) do
    # Check Plug.Conn.read_body/2 docs for maximum body value,
    # the size of each chunk, and supported timeout values.
    case read_body(conn, []) do
      {:ok, body, conn} ->
        :hackney.send_body(client, body)
        conn
      {:more, body, conn} ->
        :hackney.send_body(client, body)
        write_proxy(conn, client)
    end
  end

  # Reads the client response and sends it back.
  defp read_proxy(conn, client) do
    {:ok, status, headers, client} = :hackney.start_response(client)
    {:ok, body} = :hackney.body(client)

    # Delete the transfer encoding header. Ideally, we would read
    # if it is chunked or not and act accordingly to support streaming.
    #
    # We may also need to delete other headers in a proxy.
    headers = List.keydelete(headers, "Transfer-Encoding", 0)

    %{conn | resp_headers: headers}
    |> send_resp(status, body)
  end

  defp uri(conn) do
    url = Enum.join(conn.path_info, "/")
    {target, mod_url} = if String.match?(url, ~r/_kake/) do
      {@kake_target, String.replace(url, "_kake/", "")}
    else
      if String.match?(url, ~r/genfiles/) do
        {@kake_target, url}
      else
        {@default_target, url}
      end
    end
    base = target <> "/" <> mod_url
    case conn.query_string do
      "" -> base
      qs -> base <> "?" <> qs
    end
  end
end
