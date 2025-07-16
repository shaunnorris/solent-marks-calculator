#!/bin/bash

# Script to organize development files into a proper structure
# This helps separate development work from production code

set -e  # Exit on any error

echo "📁 Organizing development files..."

# Create development directories
mkdir -p dev/scripts
mkdir -p dev/data
mkdir -p dev/backups
mkdir -p dev/tests

echo "📦 Moving development scripts..."
# Move development scripts
mv add_marks_*.py dev/scripts/ 2>/dev/null || true
mv clean_marks_*.py dev/scripts/ 2>/dev/null || true
mv fix_marks_*.py dev/scripts/ 2>/dev/null || true
mv *_marks_*.py dev/scripts/ 2>/dev/null || true

echo "📄 Moving data files..."
# Move data files
mv "Lym Inshore Marks"*.txt dev/data/ 2>/dev/null || true

echo "💾 Moving backup files..."
# Move backup files
mv "Lym Inshore Marks"*.backup* dev/backups/ 2>/dev/null || true

echo "🧪 Moving test files..."
# Move test files
mv test_app.py dev/tests/ 2>/dev/null || true

echo "🗑️ Cleaning cache directories..."
# Remove cache directories
rm -rf __pycache__
rm -rf .pytest_cache

echo "✅ Development files organized!"
echo ""
echo "📁 New structure:"
echo "  dev/scripts/ - Development and working scripts"
echo "  dev/data/    - Data files and sources"
echo "  dev/backups/ - Backup files"
echo "  dev/tests/   - Test files"
echo ""
echo "🚀 Production files remain in root directory" 