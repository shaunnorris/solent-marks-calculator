#!/usr/bin/env python3
"""
Final robust data cleaning script for Lym Inshore Marks.txt
Properly handles all coordinate format variations
"""

import re
import shutil
from datetime import datetime

def parse_coordinates_robust(lat_str, lon_str):
    """
    Robust coordinate parsing that handles all format variations
    """
    def parse_single_coord(coord_str):
        # Remove trailing periods and clean up
        coord_str = coord_str.strip().rstrip('.')
        
        # Handle space-separated format like "50 42.767"
        if ' ' in coord_str:
            parts = coord_str.split()
            if len(parts) >= 2:
                degrees = parts[0]
                minutes = parts[1]
                # Add seconds if not present
                if '.' in minutes:
                    return f"{degrees}.{minutes}.00"
                else:
                    return f"{degrees}.{minutes}.00"
        
        # Handle dot-separated format like "50.41.50"
        if coord_str.count('.') == 2:
            return coord_str
        
        # Handle format like "50.42" (degrees.minutes)
        if coord_str.count('.') == 1:
            return f"{coord_str}.00"
        
        return coord_str
    
    lat_clean = parse_single_coord(lat_str)
    lon_clean = parse_single_coord(lon_str)
    
    return lat_clean, lon_clean

def clean_mark_data_robust(input_file, output_file):
    """
    Robust cleaning of the marks data file
    """
    cleaned_lines = []
    line_number = 0
    
    print(f"Cleaning data from {input_file}...")
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue
                
                # Skip comment lines
                if line.startswith('#'):
                    continue
                
                # More robust parsing approach
                # First, split by spaces and work backwards from the end
                parts = line.split()
                
                if len(parts) < 5:
                    print(f"Warning: Line {line_num} has too few parts: {line}")
                    continue
                
                # Last part is symbol description
                symbol_desc = parts[-1]
                
                # Find coordinates by looking for patterns
                # Look for the last two coordinate-like patterns
                coord_pattern = r'^[0-9]+\.?[0-9]*\.?[0-9]*$'
                
                # Work backwards to find coordinates
                lat_idx = -1
                lon_idx = -1
                
                for i in range(len(parts) - 2, -1, -1):
                    if re.match(coord_pattern, parts[i]):
                        if lon_idx == -1:
                            lon_idx = i
                        elif lat_idx == -1:
                            lat_idx = i
                            break
                
                if lat_idx == -1 or lon_idx == -1:
                    print(f"Warning: Could not find coordinates on line {line_num}: {line}")
                    continue
                
                # Extract parts
                mark_id = parts[0]
                description = ' '.join(parts[1:lat_idx])
                lat_str = parts[lat_idx]
                lon_str = parts[lon_idx]
                
                # Clean coordinates
                lat_clean, lon_clean = parse_coordinates_robust(lat_str, lon_str)
                
                # Create cleaned line
                cleaned_line = f"{mark_id} {description} {lat_clean} {lon_clean} {symbol_desc}"
                cleaned_lines.append(cleaned_line)
                line_number += 1
                
                print(f"Line {line_num}: {lat_str} {lon_str} -> {lat_clean} {lon_clean}")
    
    except Exception as e:
        print(f"Error reading file: {e}")
        return False
    
    # Write cleaned data to output file
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            for line in cleaned_lines:
                f.write(line + '\n')
        
        print(f"\n✅ Successfully cleaned {line_number} marks")
        print(f"📁 Cleaned data written to: {output_file}")
        return True
        
    except Exception as e:
        print(f"Error writing file: {e}")
        return False

def create_backup(original_file):
    """Create a backup of the original file"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = f"{original_file}.backup_{timestamp}"
    
    try:
        shutil.copy2(original_file, backup_file)
        print(f"📋 Backup created: {backup_file}")
        return backup_file
    except Exception as e:
        print(f"Warning: Could not create backup: {e}")
        return None

def main():
    """Main function"""
    input_file = "Lym Inshore Marks.txt"
    output_file = "Lym Inshore Marks_cleaned.txt"
    
    print("🧹 Lym Inshore Marks Data Cleaner - Final Version")
    print("=" * 50)
    
    # Create backup
    backup_file = create_backup(input_file)
    
    # Clean the data
    success = clean_mark_data_robust(input_file, output_file)
    
    if success:
        print("\n🎉 Data cleaning completed successfully!")
        print(f"📊 Original file: {input_file}")
        print(f"📊 Cleaned file: {output_file}")
        if backup_file:
            print(f"📊 Backup file: {backup_file}")
        
        print("\nWould you like to replace the original file with the cleaned version?")
        print("Run: mv 'Lym Inshore Marks_cleaned.txt' 'Lym Inshore Marks.txt'")
    else:
        print("\n❌ Data cleaning failed!")

if __name__ == "__main__":
    main() 