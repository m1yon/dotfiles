#!/bin/bash

# Create bin directory if it doesn't exist
mkdir -p ./bin

# Build each TypeScript file in src/ as an executable
for file in ./src/*.ts; do
    filename=$(basename "$file" .ts)
    echo "Building $filename..."
    bun build "./src/$filename.ts" --compile --outfile "./bin/$filename"
done

echo "Done!"
