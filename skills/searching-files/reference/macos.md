### Use Spotlight for searching

#### Search Current Directory and Subdirectories

bash

```bash
mdfind -onlyin . "search term"
```

Or you can be more explicit:

bash

```bash
mdfind -onlyin "$PWD" "search term"
```

#### Examples

**Find all PDF files in current directory tree:**

bash

```bash
mdfind -onlyin . "kMDItemContentType == 'com.adobe.pdf'"
```

**Search for files containing "config" in current directory:**

bash

```bash
mdfind -onlyin . "config"
```

**Find files by name in current directory:**

bash

```bash
mdfind -onlyin . -name "*.txt"
```

### Reading Files

`textutil` is a powerful built-in macOS command-line utility for converting between various document formats. It's particularly useful for extracting text from documents or converting between formats.

#### Supported Input Formats

**Text formats:**

- `.txt` - Plain text
- `.rtf` - Rich Text Format
- `.rtfd` - RTF with attachments
- `.html` - HTML documents
- `.xml` - XML documents

**Document formats:**

- `.doc` - Microsoft Word (older format)
- `.docx` - Microsoft Word (newer format)
- `.odt` - OpenDocument Text
- `.pages` - Apple Pages documents

**Other formats:**

- `.pdf` - PDF documents
- `.webarchive` - Safari web archives

#### Supported Output Formats

You can convert to these formats using the `-convert` option:

- `txt` - Plain text
- `rtf` - Rich Text Format
- `rtfd` - RTF with attachments
- `html` - HTML
- `xml` - XML
- `doc` - Microsoft Word
- `docx` - Microsoft Word (newer)
- `odt` - OpenDocument Text
- `webarchive` - Web archive

#### Common Usage Examples

**Convert PDF to text:**

```bash
textutil -convert txt document.pdf
textutil -convert txt document.pdf -output extracted.txt
```

**Convert Word doc to plain text:**

```bash
textutil -convert txt document.docx
```

**Convert multiple files:**

```bash
textutil -convert txt *.pdf
textutil -convert html *.rtf
```

**Extract text from Pages document:**

```bash
textutil -convert txt document.pages -output text_version.txt
```
