# agent_core/agent_core.py
import time
import os
import yaml
from collector.collector import Collector
from executor.executor import Executor
from strategy.ma_rsi_strategy import MAStrategy

def load_config(path="config.yaml"):
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)

def main():
    cfg = load_config(os.environ.get("CONFIG_PATH", "config.yaml"))
    mode = os.environ.get("ENV", cfg.get("agent", {}).get("mode", "paper"))
    interval = cfg.get("agent", {}).get("loop_interval_seconds", 10)

    collector = Collector(cfg, mode=mode)
    executor = Executor(cfg, mode=mode)
    strategy = MAStrategy(cfg)

    print(f"[Agent] start mode={mode} interval={interval}s")
    try:
        while True:
            market = collector.get_latest()
            decision = strategy.decide(market)
            if decision:
                executor.execute(decision)
            time.sleep(interval)
    except KeyboardInterrupt:
        print("Agent stopped by user")

if __name__ == "__main__":
    main()

