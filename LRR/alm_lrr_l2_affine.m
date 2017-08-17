function [Z,E] = alm_lrr_l2_affine(X,A,lambda)
% This routine solves the following nuclear-norm optimization problem,
% min |Z|_*+lambda*|E|_2,1
% s.t., X = AZ+E
% inputs:
%        X -- D*N data matrix, D is the data dimension, and N is the number
%             of data vectors.
%        A -- D*M matrix of a dictionary, M is the size of the dictionary

tol = 1e-8;
maxIter = 1e6;
[d n] = size(X);
m = size(A,2);
rho = 1.1;
max_mu = 1e10;
mu = 1e-6;
atx = A'*X;
inv_a = inv(A'*A+eye(m)+ones(m,m));
%% Initializing optimization variables
% intialize
J = zeros(m,n);
Z = zeros(m,n);
E = sparse(d,n);

Y1 = zeros(d,n);
Y2 = zeros(n,1);
Y3 = zeros(m,n);
%% Start main loop
iter = 0;
disp(['initial,rank=' num2str(rank(Z))]);
while iter<maxIter
    iter = iter + 1;
    %update J
    temp = Z + Y3/mu;
    [U,sigma,V] = svd(temp,'econ');
    sigma = diag(sigma);
    svp = length(find(sigma>1/mu));
    if svp>=1
        sigma = sigma(1:svp)-1/mu;
    else
        svp = 1;
        sigma = 0;
    end
    J = U(:,1:svp)*diag(sigma)*V(:,1:svp)';
    %J = solve_l1l2(temp,1/mu);
    %udpate Z
    Z = inv_a*(atx-A'*E+ones(m,n)+J+(A'*Y1-ones(m,1)*Y2'-Y3)/mu);
    %update E
    xmaz = X-A*Z;
    temp = xmaz+Y1/mu;
    E = mu*temp/(lambda+mu);
    
    leq1 = xmaz-E;
    leq2 = Z'*ones(m,1)-ones(n,1);
    leq3 = Z-J;
    stopC = max( max(max(max(abs(leq1))),max(max(abs(leq2)))) ,max(max(abs(leq3))) );
    if iter==1 || mod(iter,50)==0 || stopC<tol
        disp(['iter ' num2str(iter) ',mu=' num2str(mu,'%2.1e') ...
            ',rank=' num2str(rank(Z,1e-3*norm(Z,2))) ',stopALM=' num2str(stopC,'%2.3e')]);
    end
    if stopC<tol 
        break;
    else
        Y1 = Y1 + mu*leq1;
        Y2 = Y2 + mu*leq2;
        Y3 = Y3 + mu*leq3;
        mu = min(max_mu,mu*rho);
    end
end