solve mdl_all using mip maximizing NPV_all;
N(G_HR) = EPS + sum((T), x_h.l(T,G_HR))/(y_hr.l(G_HR) + D6);
