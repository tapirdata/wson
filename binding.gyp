{
  "targets": [
    {
      "target_name": "native_tson",
      "sources": [ "src/transcribe.cc", "src/stringifier.cc", "src/parser.cc", "src/tson.cc" ],
      "include_dirs": [
        "<!(node -e \"require('nan')\")"
      ]
    }
  ]
}
