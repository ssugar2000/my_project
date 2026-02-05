from __future__ import annotations
from dataclasses import dataclass
import os

@dataclass(frozen=True)
class Settings:
    env: str = os.getenv("ENV", "dev")
    data_dir: str = os.getenv("DATA_DIR", "./data")
