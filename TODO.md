# Roadmap

Next steps:

1. [x] Unit tests for existing Steps 1, 2
2. [x] Ability to save/load json files containing touch event data
3. [x] Unit tests for `TouchPathStream`
4. [x] Unit tests for `PolylineStream`
4. [x] Unit tests for `BezierStream`
5. [x] Create UIBezierPath cubic smoothing
7. [x] Example app showing the stream of events and the output from each step
8. [ ] Allow encode/decode of arbitrary `DrawEvent` subclass instead of only `TouchEvent`
9. [ ] Generated documentation and tutorials in DocC
    - Related to https://github.com/apple/swift-docc-symbolkit/pull/48


## Example App

1. [x] Add list of `TouchPath.Points` to the Example app
2. [x] Ability to step event by event and see output
3. [x] Ability to toggle smoothing filters
4. [x] Ability to show generated points, lines, curves at each step of the pipeline
5. [x] Pinch to zoom and pan the ink view in the Example app
6. [ ] Configurable filters and bezier smoothing


## Smoothing:

- [x] SmoothStroke model for generating fixed-width UIBezierPaths
- [ ] SmoothStroke model for generating variable-width UIBezierPaths


## Renderers:

- [x] Basic CGContext rendering
    - with and without background image
- [x] naive DrawRect
- [x] smarter DrawRect
- [ ] CAShapeLayer
- [ ] CAShapeLayer with flattened cache
- [ ] SceneKit (git@github.com:adamwulf/SKDraw.git)


## Filters:

- [x] Implement naive SavitzkyGolay smoothing
- [x] Implement optimized SavitzkyGolay smoothing
- [x] Implement naive DouglasPeucker filtering
- [x] Implement optimized DouglasPeucker filtering
- [ ] Implement naive DistanceThinning filtering
- [ ] Implement optimized DistanceThinning filtering


