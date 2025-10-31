### Searching

Search current directory and subdirectories

fd "search term"

Find all PDFs

fd -e pdf

Find files by name

fd -g "\*.txt"

Search file contents for “config”

rg "config"

#### Reading & Converting Files (with pandoc)

Convert PDF to text

pdftotext document.pdf

# or via pandoc

pandoc document.pdf -t plain -o document.txt

Convert Word document to text

pandoc document.docx -t plain -o document.txt

Convert RTF or HTML to text

pandoc document.rtf -t plain -o document.txt
pandoc document.html -t plain -o document.txt

Batch convert all PDFs to text

for f in \*.pdf; do pdftotext "$f" "${f%.pdf}.txt"; done

#### Summary

• fd replaces mdfind for fast file search.
• rg (ripgrep) replaces Spotlight content search.
• pandoc + pdftotext replace textutil for format conversion.
