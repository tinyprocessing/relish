class Relish < Formula
  desc "Relish developer tool"
  homepage "https://github.com/tinyprocessing/relish"
  url "https://github.com/tinyprocessing/relish/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "6b3c3949cfc7bba8d9f9a7b8e0c0788d57ac3e76174d0c1a1f69f35cf452d8f9"
  license "MIT"

  def install
    chmod 0755 "setup.sh"
    system "setup.sh"
    bin.install ".build/release/relish"
  end

  def post_install
    system "relish environment setup"
  end
end


