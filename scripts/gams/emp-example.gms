set i 'commodities' / 1*3 /;

variable u 'consumer utility';
positive variables
  y        'activity of the producer'
  x(i)     'Marshallian demand of the consumer'
  p(i)     'prices'
  ;
parameters
  A(i) 'technology matrix'  / 1 1, 2 -1, 3 -1 /
  s(i) 'budget share'       / 1 0.9, 2 0.1, 3 0 /
  b(i) 'endowment'          / 1 0, 2 5, 3 3 /
  ;
equations
  profit   'profit of activity'
  mkt(i)   'constraint on excess demand'
  udef     'Cobb-Douglas utility function'
  budget   'budget constraint'
  ;
profit..   -sum(i, A(i)*p(i)) =g= 0;

mkt(i)..   b(i) + A(i)*y - x(i) =g= 0;

udef..     u =e= sum(i, s(i)*log(x(i)));

budget..   sum(i, p(i)*x(i)) =l= sum(i, p(i)*b(i));

model m / mkt, profit, udef, budget /;

file empinfo /'%emp.info%'/;  putclose empinfo
 'equilibrium' /
 ' max', u, 'x', udef, budget /
 ' vi profit y' /
 ' vi mkt p' /
 ;
* the second commodity is used as a numeraire
p.fx('2') = 1;
x.l(i) = 1;

solve m using EMP;