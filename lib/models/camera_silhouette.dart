/// Which hand-drawn body archetype [CameraIcon] renders for a camera. Each
/// value is a distinct silhouette "recipe" (see camera_icon.dart) composed
/// from a handful of shared primitives with different proportions — never a
/// sourced photo, a stock icon, or an emoji standing in for one. Several
/// camera profiles intentionally share an archetype where their real-world
/// bodies were genuinely similar (e.g. the mid-2000s compacts).
enum CameraSilhouette {
  /// The original FIELD UNIT 04 shape: rounded body, small viewfinder bump,
  /// centered lens ring. Most mid-2000s point-and-shoots.
  classicCompact,

  /// Chunkier, squarer body with a larger bump and no chrome trim — an
  /// entry-level first camera.
  boxyEntryLevel,

  /// A thin horizontal bar with no viewfinder bump and a flush, minimal
  /// lens ring — glossy metal ultra-compacts.
  slimBar,

  /// A protruding front lens barrel proportionally much larger than the
  /// body — superzoom bridge-compacts.
  chunkyBarrel,

  /// Thicker bezel with rubberized corner bumpers — waterproof/rugged and
  /// toy-class bodies built to survive drops.
  ruggedArmored,

  /// Square-edged, no lens ring detail, no viewfinder bump — a cheap
  /// disposable shell.
  cardboardBox,

  /// An SLR-style viewfinder hump plus a swivel-lens hint — 2000s
  /// prosumer/bridge cameras.
  bridgeSLRHump,

  /// A boxy body with a floppy-disk slot notch along one edge — the
  /// earliest floppy-based digicams.
  floppyBlock,

  /// A square body with a bottom print-slot line — instant-hybrid cameras
  /// that eject a physical print.
  instantSquare,

  /// A small cube body with a dome-shaped wide lens — wearable action
  /// cameras.
  actionCube,

  /// Oversized rounded corners and a chunky handle nub — kids'/toy
  /// cameras.
  toyRound,

  /// A wider, flatter body with a small offset lens — panorama-era
  /// superzoom compacts.
  panoramaWide,
}
