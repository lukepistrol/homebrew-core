class Periscope < Formula
  desc "Organize and de-duplicate your files without losing data"
  homepage "https://github.com/anishathalye/periscope"
  url "https://github.com/anishathalye/periscope.git",
    tag:      "v0.2.0",
    revision: "d672bf60f4b59c1f54fa3c26aef75d0593615c40"
  license "GPL-3.0-only"

  depends_on "go" => :build

  def install
    system "go", "build", "-ldflags",
      "-s -w -X main.version=#{version} -X main.commit=#{stable.specs[:revision]}",
      "-trimpath", "./cmd/psc"

    bin.install "psc"

    # install bash completion
    output = Utils.safe_popen_read("#{bin}/psc", "completion", "bash")
    (bash_completion/"psc").write output

    # install zsh completion
    output = Utils.safe_popen_read("#{bin}/psc", "completion", "zsh")
    (zsh_completion/"_psc").write output
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/psc version")

    # setup
    (testpath/"a").write("dupe")
    (testpath/"b").write("dupe")
    (testpath/"c").write("unique")

    # scan + summary is correct
    shell_output "#{bin}/psc scan 2>/dev/null"
    summary = shell_output("#{bin}/psc summary").strip.split("\n").map { |l| l.strip.split(" ") }
    assert_equal [["tracked", "2"], ["unique", "1"], ["duplicate", "1"], ["overhead", "4", "B"]], summary

    # rm allows deleting dupes but not uniques
    shell_output "#{bin}/psc rm #{testpath/"a"}"
    assert_not_predicate (testpath/"a"), :exist?
    # now b is unique
    shell_output "#{bin}/psc rm #{testpath/"b"} 2>/dev/null", 1
    assert_predicate (testpath/"b"), :exist?
    shell_output "#{bin}/psc rm #{testpath/"c"} 2>/dev/null", 1
    assert_predicate (testpath/"c"), :exist?

    # cleanup
    shell_output("#{bin}/psc finish")
  end
end
