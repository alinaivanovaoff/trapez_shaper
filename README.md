# trapez_shaper
Trapezoidal Shaper
 dkl(n) = v(n)   - v(n-k) - v(n-l) + v(n-k-l)
   p(n) = p(n-1) + dkl(n), n<=0
   r(n) = p(n)   + M*dkl(n)
   q(n) = r(n)   + M2*dkl(n)
   s(n) = s(n-1) + q(n),   n<=0
   M    = 1/(exp(Tclk/tau) - 1)
