{
  "targets": [
    {
      "target_name": "native_tson",
      "sources": [ "src/native_tson.cc" ],
      "include_dirs": [
        "<!(node -e \"require('nan')\")"
      ]
    }
  ]
}
