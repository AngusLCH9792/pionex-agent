# executor/executor.py
import os
import json
import datetime


class Executor:
    def __init__(self, cfg, mode="paper"):
        self.cfg = cfg
        self.mode = mode
        self.log_path = os.path.join("logs", "paper_orders.log")
        os.makedirs("logs", exist_ok=True)

    def _record(self, decision):
        line = f"{datetime.datetime.utcnow().isoformat()}Z {json.dumps(decision)}\n"
        with open(self.log_path, "a", encoding="utf-8") as f:
            f.write(line)

    def execute(self, decision):
        if self.mode == "paper":
            print(f"[Executor][PAPER] Simulated order: {json.dumps(decision)}")
            self._record(decision)
        else:
            print(f"[Executor][REAL] Would send order: {json.dumps(decision)}")
            # TODO: implement real order logic
