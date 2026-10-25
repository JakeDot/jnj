#!/usr/bin/env python3
import os
import shutil
import subprocess
import sys

def main():
    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    build_web_dir = os.path.join(root_dir, "build", "web")
    assets_web_dir = os.path.join(root_dir, "android", "app", "src", "main", "assets", "web")

    print("[Jules Shell Wrapper Sync] Starting Flutter Web build & sync...")

    # Run flutter build web
    try:
        subprocess.run(["flutter", "build", "web"], check=True, cwd=root_dir)
        print("[Jules Shell Wrapper Sync] Flutter build web completed successfully.")

        # Create .nojekyll and 404.html for GitHub Pages & web deployment
        nojekyll = os.path.join(build_web_dir, ".nojekyll")
        open(nojekyll, "a").close()
        index_html = os.path.join(build_web_dir, "index.html")
        html_404 = os.path.join(build_web_dir, "404.html")
        if os.path.exists(index_html):
            shutil.copy2(index_html, html_404)
    except Exception as e:
        print(f"[Jules Shell Wrapper Sync] Warning: 'flutter build web' failed or flutter SDK not in PATH ({e}).")
        print("[Jules Shell Wrapper Sync] Proceeding with existing assets...")

    if os.path.exists(build_web_dir):
        os.makedirs(assets_web_dir, exist_ok=True)
        for item in os.listdir(build_web_dir):
            s = os.path.join(build_web_dir, item)
            d = os.path.join(assets_web_dir, item)
            if os.path.isdir(s):
                shutil.copytree(s, d, dirs_exist_ok=True)
            else:
                shutil.copy2(s, d)
        print(f"[Jules Shell Wrapper Sync] Successfully synced web assets from {build_web_dir} to {assets_web_dir}.")
    else:
        print(f"[Jules Shell Wrapper Sync] Web assets present in {assets_web_dir}.")

if __name__ == "__main__":
    main()
