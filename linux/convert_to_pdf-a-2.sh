#!/bin/bash

# ==============================================================================
# Script: convert_to_pdfa2.sh
# Description: Converts all PDF files in the current directory to PDF/A-2b 
#              using Ghostscript.
# Requirements: ghostscript
# ==============================================================================

# Create an output directory to keep things organized
OUTPUT_DIR="archived_pdfa2"
mkdir -p "$OUTPUT_DIR"

echo "-------------------------------------------------------"
echo "Starting PDF/A-2b conversion..."
echo "Output directory: ./$OUTPUT_DIR"
echo "-------------------------------------------------------"

for file in *.pdf; do
    # Skip files already in the output directory
    [ -e "$file" ] || continue
    
    echo "Processing: $file"

    # Ghostscript command for PDF/A-2b conversion
    gs -dPDFA=2 \
       -dBATCH \
       -dNOPAUSE \
       -dNOOUTERSAVE \
       -dNOSAFER \
       -sDEVICE=pdfwrite \
       -sProcessColorModel=DeviceRGB \
       -dPDFACompatibilityPolicy=1 \
       -sOutputFile="$OUTPUT_DIR/${file%.pdf}_PDFA2.pdf" \
       "$file" > /dev/null 2>&1

    # Check if the conversion was successful
    if [ $? -eq 0 ]; then
        echo "SUCCESS: Created $OUTPUT_DIR/${file%.pdf}_PDFA2.pdf"
    else
        echo "ERROR: Failed to convert $file"
    fi
done

echo "-------------------------------------------------------"
echo "Conversion task finished."
echo "-------------------------------------------------------"
