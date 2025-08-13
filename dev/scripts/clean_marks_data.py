#!/usr/bin/env python3
"""
Data cleaning script for Lym Inshore Marks.txt
Standardizes coordinate formats and fixes data inconsistencies
"""

import re
import shutil
from datetime import datetime

def clean_coordinates(lat_str, lon_str):
    """
    Clean and standardize coordinate strings to consistent format
    Input formats: "50.41.50", "50 42.767", "50.42.97 01.28.16."
    Output format: "50.41.50 01.41.60"
    """
    def clean_single_coord(coord_str):
        # Remove trailing periods and extra spaces
        coord_str = coord_str.strip().rstrip('.')
        
        # Handle different formats
        if '.' in coord_str:
            # Format like "50.41.50" or "50 42.767"
            parts = coord_str.replace(' ', '').split('.')
            if len(parts) == 3:
                # Already in correct format
                return f"{parts[0]}.{parts[1]}.{parts[2]}"
            elif len(parts) == 2:
                # Format like "50.42" - assume it's degrees.minutes
                return f"{parts[0]}.{parts[1]}.00"
        else:
            # Format like "50 42" - assume degrees minutes
            parts = coord_str.split()
            if len(parts) >= 2:
                return f"{parts[0]}.{parts[1]}.00"
        
        return coord_str
    
    lat_clean = clean_single_coord(lat_str)
    lon_clean = clean_single_coord(lon_str)
    
    return lat_clean, lon_clean

def clean_mark_data(input_file, output_file):
    """
    Clean the marks data file and write to output file
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
                
                # Parse the line using a more flexible regex
                # Pattern: mark_id description lat lon symbol_description
                pattern = r'^([A-Z0-9#♠🌰π+@V]+)\s+(.+?)\s+([0-9\s\.]+)\s+([0-9\s\.]+)\s+(.+)$'
                match = re.match(pattern, line)
                
                if match:
                    mark_id = match.group(1).strip()
                    description = match.group(2).strip()
                    lat_str = match.group(3).strip()
                    lon_str = match.group(4).strip()
                    symbol_desc = match.group(5).strip()
                    
                    # Clean coordinates
                    lat_clean, lon_clean = clean_coordinates(lat_str, lon_str)
                    
                    # Create cleaned line
                    cleaned_line = f"{mark_id} {description} {lat_clean} {lon_clean} {symbol_desc}"
                    cleaned_lines.append(cleaned_line)
                    line_number += 1
                    
                    print(f"Line {line_num}: Cleaned coordinates {lat_str} {lon_str} -> {lat_clean} {lon_clean}")
                else:
                    print(f"Warning: Could not parse line {line_num}: {line}")
    
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
    
    print("🧹 Lym Inshore Marks Data Cleaner")
    print("=" * 40)
    
    # Create backup
    backup_file = create_backup(input_file)
    
    # Clean the data
    success = clean_mark_data(input_file, output_file)
    
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