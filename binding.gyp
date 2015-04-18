{
  "targets": [
    {
      "target_name": "native_tson",
      "sources": [ "src/tson.cc", "src/serializer.cc" ],
      "include_dirs": [
        "<!(node -e \"require('nan')\")"
      ]
    }
  ]
}
