# Target (libvirt)
{
  snabbvirtbot = {
    deployment.targetEnv = "libvirtd";
    deployment.libvirtd.memorySize = 8192;
    deployment.libvirtd.vcpu = 4;
    deployment.libvirtd.baseImageSize = 40;
    deployment.libvirtd.extraDomainXML = ''
      <cpu mode='host-passthrough'/>
    '';
  };
}
