solve mdl_all using mip maximizing NPV_all;
N(G_HR) = sum((T), x_h.l(T,G_HR))/(y_hr.l(G_HR)+1e-6);
