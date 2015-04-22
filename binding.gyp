{
  "targets": [
    {
      "target_name": "native_tson",
      "sources": [ "src/source_buffer.cc", "src/transcribe.cc", "src/serializer.cc", "src/parser.cc", "src/tson.cc" ],
      "include_dirs": [
        "<!(node -e \"require('nan')\")"
      ]
    }
  ]
}
