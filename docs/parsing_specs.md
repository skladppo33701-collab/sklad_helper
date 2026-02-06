# Excel Parsing Specs

## 1) Transfer Excel ("Перемещение ТМЗ ...")
Input: .xlsx

### Extract metadata
- Title: cell B3 (e.g. "Накладная на перемещение № 52 от 22 января 2026 г.")
- Sender: row 8, col G
- Receiver: row 10, col G
- Additional fields if present: base document info (row 6)

### Table header row
Header is around row 12 (merged cells possible).

Columns (by observed file):
- lineNo: column B
- article: column D
- itemName: column I
- qty: column AD (planned)
Optional:
- places: X
- volume: AN

### Row types
- Category/group rows: article empty, itemName contains group label.
  - For MVP: ignore group label OR store as `rawGroupLabel`.
- Item rows: article present and qty numeric.

### Output normalization
- qtyPlanned: int >= 1
- article: string required
- itemName: string required
- category resolution:
  - if product exists in catalog: use product.category
  - else: "Uncategorized" and set transfer.flags.needsCatalogAttention=true

### Validation rules
Hard errors (block publish):
- missing article on item row
- qtyPlanned <= 0
- empty document number/date (if cannot parse)
Soft warnings (allow publish):
- duplicates of same article (merge lines or keep separate; decision required in implementation)
- product missing in catalog

## 2) Products import ("Остатки ...")
Input: .xls

Goal: build initial products catalog (ignore stock quantities).

Pattern:
- hierarchical grouping rows:
  - warehouse bucket (e.g. "33701_0090")
  - brand row
  - product rows contain article in column C and name in column B

Output:
- article, name, brand (optional), category (to be filled later), barcode empty
- category can initially be inferred from name keywords (optional) or set "Uncategorized"
