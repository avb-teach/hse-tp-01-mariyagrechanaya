#!/bin/bash
set -e

function error_exit {
    echo "Error: $1" >&2
    exit 1
}

if [[ "$#" -lt 2 ]]; then
    error_exit "Usage: $0 [--max_depth N] /path/to/input_dir /path/to/output_dir"
fi


if [[ "$1" == "--max_depth" ]]; then
    MAX_DEPTH="$2"
    INPUT_DIR="$3"
    OUTPUT_DIR="$4"

    if [[ -z "$MAX_DEPTH" || -z "$INPUT_DIR" || -z "$OUTPUT_DIR" ]]; then
        error_exit "Usage: $0 [--max_depth N] /path/to/input_dir /path/to/output_dir"
    fi
else
    MAX_DEPTH=""
    INPUT_DIR="$1"
    OUTPUT_DIR="$2"
fi

if [[ ! -d "$INPUT_DIR" ]]; then
    error_exit "Input directory does not exist: $INPUT_DIR"
fi

mkdir -p "$OUTPUT_DIR"

if [[ -n "$MAX_DEPTH" ]]; then
    find "$INPUT_DIR" -mindepth 1 -maxdepth "$MAX_DEPTH" -type f | while read -r file; do
        RELATIVE_PATH=$(realpath --relative-to="$INPUT_DIR" "$file")
        DEST_FILE="$OUTPUT_DIR/$RELATIVE_PATH"

        mkdir -p "$(dirname "$DEST_FILE")"
        cp "$file" "$DEST_FILE"
    done
else
    declare -A filenames

    find "$INPUT_DIR" -type f | while read -r file; do
        filename=$(basename "$file")

        # Если файл с таким именем уже существует, добавляем суффикс
        if [[ -e "$OUTPUT_DIR/$filename" || ${filenames[$filename]+_} ]]; then
            base="${filename%.*}"
            ext="${filename##*.}"
            counter=1
            new_filename="${base}${counter}.${ext}"

            while [[ -e "$OUTPUT_DIR/$new_filename" ]]; do
                ((counter++))
                new_filename="${base}${counter}.${ext}"
            done
            filenames["$new_filename"]=1
            cp "$file" "$OUTPUT_DIR/$new_filename"
        else
            filenames["$filename"]=1
            cp "$file" "$OUTPUT_DIR/$filename"
        fi
    done
fi

echo "Files have been collected successfully."