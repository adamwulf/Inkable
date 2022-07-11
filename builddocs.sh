xcodebuild docbuild -scheme Inkable -destination generic/platform=iOS OTHER_DOCC_FLAGS="--transform-for-static-hosting --hosting-base-path Inkable --output-path docs"
xcodebuild docbuild -scheme Inkable -destination generic/platform=iOS OTHER_DOCC_FLAGS="--output-path .build/Inkable.doccarchive"
open .build/Inkable.doccarchive
