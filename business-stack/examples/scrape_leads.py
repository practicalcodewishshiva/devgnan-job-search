"""Pull structured data from any website with ScrapeGraphAI (#03), in plain English.

Usage:
    python scrape_leads.py <url> "<what you want>"

LLM choice (first match wins):
    OPENAI_API_KEY set       -> openai/gpt-4o-mini   (override with SCRAPE_MODEL)
    otherwise                -> ollama/llama3.2 running locally (`ollama pull llama3.2`)
"""

import json
import os
import sys

from scrapegraphai.graphs import SmartScraperGraph


def llm_config() -> dict:
    if os.environ.get("OPENAI_API_KEY"):
        return {
            "api_key": os.environ["OPENAI_API_KEY"],
            "model": os.environ.get("SCRAPE_MODEL", "openai/gpt-4o-mini"),
        }
    return {
        "model": os.environ.get("SCRAPE_MODEL", "ollama/llama3.2"),
        "model_tokens": 8192,
        "format": "json",
    }


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    url, prompt = sys.argv[1], sys.argv[2]
    graph = SmartScraperGraph(
        prompt=prompt,
        source=url,
        config={"llm": llm_config(), "headless": True, "verbose": False},
    )
    print(json.dumps(graph.run(), indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
