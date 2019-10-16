self: super:

{
  nim_1_0 = super.callPackage ./nim_1_0.nim {};
  boomer = super.callPackage ./boomer.nix {};
}
