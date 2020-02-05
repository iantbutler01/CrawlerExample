defmodule CrawlerExample.Worker do
  alias CrawlerExample.Queue

  def work(depth_limit \\ 5) do
    case Queue.pop() do
      :empty ->
        :ok
      {:value, [url, depth]} ->
        unless depth > depth_limit do
          case request_page(url) do
            #You can add more robust error handling here, typically If the error is an http error
            #then it means the url is likely not crawlable and not worth retrying but
            #I usually break it out by code and atleast log the specific error.
            {:error, _} ->
              :ok
            {:ok, body} ->
              File.mkdir_p!("/tmp/toy_crawler_results")
              file_hash = Base.encode32(:crypto.hash(:sha256, body))
              File.write!("/tmp/toy_crawler_results/#{file_hash}.html", body)

              get_children_urls(body)
              |> Enum.map(fn c_url ->
                Queue.push([depth+1, c_url])
              end)
              :ok
          end
        else
          :ok
        end
    end
  end

  defp request_page(url) do
    case HTTPoison.get(url) do
      {:error, res} ->
        {:error, res.reason}
      {:ok, res} ->
        case res do
          %HTTPoison.Response{status_code: 404} -> {:error, 404}
          %HTTPoison.Response{status_code: 401} -> {:error, 401}
          %HTTPoison.Response{status_code: 403} -> {:error, 403}
          %HTTPoison.Response{status_code: 200, body: body} -> {:ok, body}
        end
    end
  end

  defp get_children_urls(body) do
    Floki.find(body, "div#readme")
    |> Floki.find("div.Box-body")
    |> Floki.find("a")
    |> Floki.attribute("href")
    |> Enum.filter(fn url ->
      %URI{host: host, path: path} = URI.parse(url)
      case host do
        nil -> false
        _ ->
          with false <- path == nil,
               true <- String.match?(host, ~r/.*github\.com$/),
               true <- length(String.split(path, "/")) == 3,
               false <- Enum.at(String.split(path, "/"), 1) == "sponsors" do
            true
          else
            _ -> false
          end
      end
    end)
  end
end

