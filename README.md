# CrawlerExample

This is an example crawler I've written to go along with part 2 of a 3 part blog series on writing basic 
web crawlers specifically in Elixir. I hope this can serve as a good base for someone to get started on their own project.
The architecture is a bit overly simple for medium to larger scale projects but the concepts here should allow someone with
the curiosity and experience with Elixir to expand pretty quickly.

Some quick suggestions for someone wanting to take on a bigger crawling project:

- Look into a proper DB backed or a mutable in memory store like Redis for managing worker state
- Build a separate GenServer that is the worker manager and is responsible from doling out work from the queue to workers
- Make workers into a long running process instead of a simple function call, let them possibly manage a small separate work queue per worker
- Store results in a document store like MongoDB or a kv-store like S3 or Riak.
- Currently this silently swallows errors from the workers - fine for a blog demo not great for a production run.

# Running

- Clone this project and change into the project folder
- Install the dependencies with mix deps.get
- Run with iex -S mix
- In the console, add the first URL with CrawlerExample.Queue.push(URL)
- https://github.com/sindresorhus/awesome (This is the root list that a slightly more mature version of this crawler was built to crawl you can use that as the seed url)

# Author's Note

I wrote this as a quick toy crawler for people to learn from to that end:

- I do not intend to support this repo or make changes unless there are glaring errors that prevent it from running in a learning tool capacity.
- Pull requests will similarly be ignored unless they fix something incredibly broken.
- You are welcome to fork this and do whatever you want with it.
