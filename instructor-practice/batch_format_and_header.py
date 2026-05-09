import sys
import os
import re
import subprocess

def extract_number(filename):
    match = re.search(r'(\d+)', filename)
    return int(match.group(1)) if match else None

def get_range_files(start_file, end_file, folder):
    files = [f for f in os.listdir(folder) if f.endswith('.txt')]
    files_with_num = [(f, extract_number(f)) for f in files]
    files_with_num = [t for t in files_with_num if t[1] is not None]
    files_with_num.sort(key=lambda x: x[1])
    start_num = extract_number(start_file)
    end_num = extract_number(end_file)
    return [os.path.join(folder, f) for f, n in files_with_num if start_num <= n <= end_num]

def main():
    if len(sys.argv) != 4:
        print("Usage: python batch_format_and_header.py <folder> <start_file.txt> <end_file.txt>")
        sys.exit(1)
    folder = sys.argv[1]
    start_file = sys.argv[2]
    end_file = sys.argv[3]
    files = get_range_files(start_file, end_file, folder)
    if not files:
        print("No files found in range.")
        sys.exit(1)
    import time
    for txt_file in files:
        print(f"Processing {txt_file}...")
        base = os.path.splitext(os.path.basename(txt_file))[0]
        html_file = os.path.join(folder, f"{base}.html")
        html_file_alt = os.path.join(folder, f"Chapter_{base.split('_')[-1]}.html")

        # If neither html_file nor html_file_alt exists, run format_questions.py
        if not os.path.exists(html_file) and not os.path.exists(html_file_alt):
            print(f"[DEBUG] Running: {sys.executable} format_questions.py {txt_file}")
            result = subprocess.run([sys.executable, 'format_questions.py', txt_file], capture_output=True, text=True)
            print(f"[DEBUG] format_questions.py stdout:\n{result.stdout}")
            if result.returncode != 0:
                print(f"Error running format_questions.py on {txt_file}:\n{result.stderr}")
                continue
            # Wait a moment to ensure file system is up to date
            time.sleep(0.1)

        # After running or skipping, check which html file exists
        html_to_use = html_file if os.path.exists(html_file) else html_file_alt if os.path.exists(html_file_alt) else None
        if html_to_use and os.path.exists(html_to_use):
            print(f"Adding header to {html_to_use}...")
            print(f"[DEBUG] Running: {sys.executable} add_header.py {html_to_use}")
            result2 = subprocess.run([sys.executable, 'add_header.py', html_to_use], capture_output=True, text=True)
            print(f"[DEBUG] add_header.py stdout:\n{result2.stdout}")
            if result2.returncode != 0:
                print(f"Error running add_header.py on {html_to_use}:\n{result2.stderr}")
        else:
            print(f"HTML file not found for {txt_file}, skipping header addition.")

if __name__ == "__main__":
    main()
