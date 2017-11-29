::curl -u "cppcommons" https://api.github.com/repos/cppcommons/d-sample/contents
::curl https://api.github.com/repos/cppcommons/d-sample/contents
::curl https://api.github.com/repos/cppcommons/d-sample/contents/vc2017-env.bat
::curl -I https://api.github.com/repos/cppcommons/d-sample/zipball/master
::curl -I https://api.github.com/repos/cppcommons/d-sample/zipball/414b0b01a3411db761776e024d1b4f4a0ed85ea8
::curl -I https://codeload.github.com/cppcommons/d-sample/legacy.zip/414b0b01a3411db761776e024d1b4f4a0ed85ea8
::curl https://api.github.com/repos/cppcommons/d-sample/commits?until=2017-10-30T23:59:59Z^&since=2017-10-30T00:00:00Z
::curl https://api.github.com/repos/cppcommons/d-sample/commits?since=2017-11-27T00:00:00%%2B09:00
::curl -I https://api.github.com/repos/cppcommons/d-sample/commits
::curl -I https://api.github.com/repos/cppcommons/d-sample/commits -H "If-Modified-Since: Mon, 27 Nov 2017 08:52:41 GMT"
::curl -I https://api.github.com/repos/cppcommons/d-sample/branches/master
::curl -I https://api.github.com/repos/cppcommons/d-sample/branches/master -H 'If-None-Match: "8c3110186a1587659cb242cbea04a631"'
::curl https://api.github.com/repos/cppcommons/d-sample/branches/master
::curl -I https://api.github.com/repos/cppcommons/d-sample/contents/vc2017-env.bat
::curl -I https://api.github.com/repos/cppcommons/d-sample/contents/vc2017-env.bat -H 'If-None-Match: "69037afaf506a820e75afb3dd67099d2f6c3de58"'
::curl -I https://api.github.com/repos/cppcommons/d-sample/contents/vc2017-env.bat -H "If-Modified-Since: Mon, 27 Nov 2017 08:52:41 GMT"
::curl -i https://api.github.com/repos/cppcommons/d-sample/contents
::curl -i https://api.github.com/repos/cppcommons/d-sample/commits?since=2017-11-29T00:00:00%%2B09:00
::curl -i https://api.github.com/repos/cppcommons/d-sample/contents?ref=718d9fafc199134bfccb1788e4f1d9bf8d9b5c7a
curl -i https://api.github.com/repos/cppcommons/d-sample/contents/vc2017-env.bat
