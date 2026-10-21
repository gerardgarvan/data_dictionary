from pathlib import Path

OUT_ROOT: Path = Path(r"P:\PeCAN Master Data\Gerard\data_dictionary")
QC_PATH: Path = OUT_ROOT / "qc"
LOGS_PATH: Path = OUT_ROOT / "logs"
OUT_PATH: Path = OUT_ROOT / "out"
EXCHANGE_PATH: Path = OUT_ROOT / "exchange"

REPO_ROOT: Path = Path(__file__).resolve().parents[2]
DOCS_PATH: Path = REPO_ROOT / "docs"
