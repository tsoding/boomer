self: super:

{
  nim_1_0 = super.callPackage ./nim_1_0.nix {};
  boomer = super.callPackage ./boomer.nix {};
}
