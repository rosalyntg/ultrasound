[Frequency Response Analysis]
{
   Npanes: 1
   {
      traces: 3 {2,0,"probe_adc"} {4,0,"probe_vga"} {6,0,"probe_lna"}
      X: ('M',0,10000,0,1e+08)
      Y[0]: (' ',0,0.251188643150958,4,25.1188643150958)
      Y[1]: (' ',0,-120,20,120)
      Log: 1 2 0
      LargePixels: 1
      PltMag: 1
      PltPhi: 1 0
   }
}
[Transient Analysis]
{
   Npanes: 1
   {
      traces: 4 {524291,0,"V(in)"} {524292,0,"V(vip)-V(vin)"} {524290,0,"V(adcp)-V(adcn)"} {524293,0,"V(voh)-V(vol)"}
      X: ('µ',0,0,1e-05,0.00012)
      Y[0]: (' ',1,-2.5,0.5,2.5)
      Y[1]: ('_',0,1e+308,0,-1e+308)
      Volts: (' ',0,0,1,-2.5,0.5,2.5)
      Log: 0 0 0
   }
}
