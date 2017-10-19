%% Add zynq library

set_param(gcs,'EnableLBRepository','on');
zynqlib_anno = find_system('zynq_API','findall','on',...
    'RegExp','on','Type','annotation','Name','annotation');
set_param(zynqlib_anno,'Description','Zynq API library contains zynq specific use of peripherals listed under the AMBA devices. See zynq TRM for more documentation.');