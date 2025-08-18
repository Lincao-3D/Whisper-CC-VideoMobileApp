Get-ChildItem scripts,android -Recurse |
  Where-Object { -not $_.PSIsContainer } |
  ForEach-Object {
      (Get-Content $_.FullName) |
      Set-Content -NoNewline -Encoding utf8 $_.FullName
  }
