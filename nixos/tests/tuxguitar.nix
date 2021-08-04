import ./make-test-python.nix ({ pkgs, ... }: {
  name = "tuxguitar";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ asbachb ];
  };

  machine = { config, pkgs, ... }: {
    imports = [
      ./common/x11.nix
    ];

    services.xserver.enable = true;

    environment.systemPackages = [ pkgs.tuxguitar ];
  };

  testScript = ''
    machine.wait_for_x()
    machine.succeed("tuxguitar &")
    machine.wait_for_window("TuxGuitar - Untitled.tg")
    machine.sleep(1)
    machine.screenshot("tuxguitar")
  '';
})
