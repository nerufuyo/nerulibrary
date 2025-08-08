#!/usr/bin/env python3
"""
Script to automatically fix super parameter issues in Dart files.
This will convert constructor parameters to super parameters where appropriate.
"""

import os
import re
import sys

def fix_super_parameters_in_file(file_path):
    """Fix super parameter issues in a single file."""
    print(f"Processing: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Pattern 1: Simple failure class with just message parameter
    # const ClassName({required String message}) : super(message: message);
    pattern1 = re.compile(
        r'(const\s+\w+\s*\{\s*)required String message(\s*\})\s*:\s*super\(message:\s*message\);',
        re.MULTILINE
    )
    content = pattern1.sub(r'\1required super.message\2;', content)
    
    # Pattern 2: Failure class with message and other parameters
    # const ClassName({
    #   required String message,
    #   ...other params...
    # }) : super(message: message);
    pattern2 = re.compile(
        r'(\s+const\s+\w+\s*\{\s*\n\s*)required String message,(\s*(?:[^}]+\n)*\s*\})\s*:\s*super\(message:\s*message\);',
        re.MULTILINE | re.DOTALL
    )
    content = pattern2.sub(r'\1required super.message,\2;', content)
    
    # Pattern 3: Abstract class with just message
    # const ClassName({required String message}) : super(message: message);
    pattern3 = re.compile(
        r'(const\s+\w+\s*\{\s*)required String message(\s*\})\s*:\s*super\(message:\s*message\);',
        re.MULTILINE
    )
    content = pattern3.sub(r'\1required super.message\2;', content)
    
    # Check if anything changed
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  ✅ Fixed super parameters in {file_path}")
        return True
    else:
        print(f"  ⚪ No changes needed in {file_path}")
        return False

def find_dart_files_with_super_parameter_issues():
    """Find Dart files in lib/ directory that likely have super parameter issues."""
    dart_files = []
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                # Focus on failure files which typically have these issues
                if 'failure' in file or 'exception' in file:
                    dart_files.append(os.path.join(root, file))
    return dart_files

def main():
    """Main function to fix super parameters."""
    print("🔧 Starting super parameter fixes...")
    
    # Change to the project directory
    os.chdir('/Users/infantai/Nerufuyo/nerulibrary')
    
    # Find files that likely need fixes
    target_files = [
        'lib/features/library/domain/failures/search_failures.dart',
        'lib/features/reader/domain/failures/reader_failures.dart',
        'lib/features/authentication/domain/failures/auth_failures.dart',
        'lib/features/discovery/domain/failures/api_failures.dart',
        'lib/core/errors/exceptions.dart',
        'lib/core/errors/failures.dart'
    ]
    
    # Also find other potential files
    other_files = find_dart_files_with_super_parameter_issues()
    target_files.extend([f for f in other_files if f not in target_files])
    
    fixed_count = 0
    for file_path in target_files:
        if os.path.exists(file_path):
            if fix_super_parameters_in_file(file_path):
                fixed_count += 1
        else:
            print(f"  ⚠️  File not found: {file_path}")
    
    print(f"\n✅ Fixed super parameters in {fixed_count} files")
    print("🎯 Re-run dart analyze to check improvements!")

if __name__ == "__main__":
    main()
