import json
from pathlib import Path
from typing import List, Dict

from langchain_community.vectorstores import FAISS
from langchain_core.documents import Document
from langchain_huggingface import HuggingFaceEmbeddings


BASE_DIR = Path(__file__).resolve().parent
DATA_PATH = BASE_DIR / "data" / "9480_wine_final_master.json"
INDEX_DIR = BASE_DIR / "data" / "wine_faiss_index"


def load_wine_records(path: Path) -> List[Dict]:
    """Load wine records from the JSON file."""
    if not path.exists():
        raise FileNotFoundError(f"Data file not found at {path}")

    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, list):
        raise ValueError("Expected top-level JSON array of wine records.")

    return data


def build_documents(records: List[Dict]) -> List[Document]:
    """Convert raw records into LangChain Documents."""
    documents: List[Document] = []

    for r in records:
        tasting_notes = r.get("lcbo_tastingnotes")
        if not tasting_notes:
            continue

        tasting_notes_str = str(tasting_notes).strip()
        if not tasting_notes_str:
            continue

        metadata = {
            "systitle": r.get("systitle") or r.get("title") or "Unknown Wine",
            "ec_final_price": r.get("ec_final_price"),
            "lcbo_tastingnotes": tasting_notes_str,
            "ec_thumbnails": r.get("ec_thumbnails"),
            "permanentid": r.get("permanentid"),
            "ec_skus": r.get("ec_skus"),
        }

        documents.append(
            Document(
                page_content=tasting_notes_str,
                metadata=metadata,
            )
        )

    return documents


def build_and_persist_index(documents: List[Document]) -> None:
    """Create a FAISS index from documents and persist it to disk."""
    if not documents:
        raise ValueError("No documents to index. Check your input data.")

    embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")

    print(f"Creating FAISS index for {len(documents)} documents...")
    vectorstore = FAISS.from_documents(documents, embeddings)

    INDEX_DIR.mkdir(parents=True, exist_ok=True)
    vectorstore.save_local(str(INDEX_DIR))
    print(f"FAISS index saved to {INDEX_DIR}")


def main() -> None:
    """Entry point for building the wine recommendation FAISS index."""

    print(f"Loading wine records from {DATA_PATH}...")
    records = load_wine_records(DATA_PATH)
    print(f"Loaded {len(records)} total records.")

    documents = build_documents(records)
    print(f"Built {len(documents)} documents with tasting notes.")

    build_and_persist_index(documents)


if __name__ == "__main__":
    main()

