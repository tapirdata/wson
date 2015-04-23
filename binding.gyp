{
  "targets": [
    {
      "target_name": "native_tson",
      "sources": [ "src/transcribe.cc", "src/stringifier_target.cc", "src/stringifier.cc", "src/parser_source.cc", "src/parser.cc", "src/tson.cc" ],
      "include_dirs": [
        "<!(node -e \"require('nan')\")"
      ],
      "cflags": ["-std=c++11"]
    }
  ]
}
