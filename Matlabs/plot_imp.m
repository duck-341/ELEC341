function plot_imp(gs,figurenum)
    t = 0:0.001:50;
    figure(figurenum); hold on; grid on;
    gs_imp = inpulse(gs,t);
    plot(t, gs_imp);
    xlabel('Time(s)');
    title('Impulse Response');
end