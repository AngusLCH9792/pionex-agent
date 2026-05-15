# collector/collector.py
import random
import time


class Collector:
    def __init__(self, cfg, mode="paper"):
        self.cfg = cfg
        self.mode = mode

    def get_latest(self):
        # 最小模擬：回傳簡單價格時間序列片段
        price = 100 + random.uniform(-1, 1)
        ts = int(time.time())
        return {"timestamp": ts, "price": price}
