function CSP2_Report(H,outdir)
fn=fullfile(outdir,'CSP2_history.csv');f=fopen(fn,'w');assert(f>0);
fprintf(f,'time_days,dt_days,BHP_kPa,Qo_sm3_day,Qw_sm3_day,Qg_sm3_day,WCUT,GOR_sm3_sm3,Np_sm3,Wp_sm3,Gp_sm3,BHP_control,well_status\n');
fclose(f);dlmwrite(fn,H,'-append','delimiter',',','precision','%.12g');
a=H(end,:);f=fopen(fullfile(outdir,'CSP2_summary.txt'),'w');
fprintf(f,'MRST CSP-2 final: t=%.6f d BHP=%.6f kPa Qo=%.6f Qw=%.6f Qg=%.6f WCUT=%.8f GOR=%.6f Np=%.6f Wp=%.6f Gp=%.6f\n', ...
 a(1),a(3),a(4),a(5),a(6),a(7),a(8),a(9),a(10),a(11));
fprintf(f,'CMG reference day 900: BHP=23402 kPa WCUT=0.37463 GOR=240.42 Np=82217 m3\n');
fclose(f);
end
