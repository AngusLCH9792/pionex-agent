# strategy/ma_rsi_strategy.py
class MAStrategy:
    def __init__(self, cfg):
        self.cfg = cfg
        self.last_price = None

    def decide(self, market):
        price = market.get("price")
        if price is None:
            return None
        if self.last_price is None:
            self.last_price = price
            return None
        # 示範策略（非常簡單，僅作測試用）
        if price > self.last_price:
            action = {"action": "sell", "size": 0.001, "symbol": "BTCUSDT"}
        else:
            action = {"action": "buy", "size": 0.001, "symbol": "BTCUSDT"}
        self.last_price = price
        return action
