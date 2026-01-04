$file = "c:\Users\vamsi\Desktop\AD-Security\walkthroughs\00_pentesting_in_corporate.md"
$content = Get-Content $file -Raw

# This will take the current file and convert dense explanation paragraphs to bullets
# We'll do this in a smart way - preserving code blocks, headers, existing bullets, etc.

Write-Host "Document has $((Get-Content $file).Count) lines"
Write-Host "Processing bullet conversion - this is complex, will do it manually in sections"
Write-Host "File size: $((Get-Item $file).Length) bytes"
