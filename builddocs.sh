xcodebuild docbuild -scheme Inkable -destination generic/platform=iOS OTHER_DOCC_FLAGS="--transform-for-static-hosting --hosting-base-path Inkable --output-path docs"
xcodebuild docbuild -scheme Inkable -destination generic/platform=iOS OTHER_DOCC_FLAGS="--output-path Inkable.doccarchive"
open Inkable.doccarchive
rm -rf Inkable.doccarchive
