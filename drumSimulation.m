%Author: Ben Sheffer
clear;
clc;

m = 1;
a = 16;
T = 3*80E6;%6*80E6;
k = 4;
fig = 1;

Nsamples = 48E3;
N = 1600;
gamma = 8;
X = zeros(1,N);
Vel = zeros(1,N);
mVec = m.*ones(1,N);

K = zeros(N,N); %declare the K matrix
%X(N/2) = 8;
tStep = 0.000028; %at 48KHz
A = zeros(1, Nsamples); %hold a second of audio data

Boundary = zeros(1,N); %use this to store the boundary conditions

for y = ((sqrt(N)/2)-2):((sqrt(N)/2)+2)
   for x = ((sqrt(N)/2)-2):((sqrt(N)/2)+2)
       sqrt(N)*(y-1)+x
      X(sqrt(N)*(y-1) + x) = -0.01*exp(-(((x-(sqrt(N)/2))^2+(y-(sqrt(N)/2))^2))^2/(2*3^2));
   end
end


for y = 1:sqrt(N)
   for x = 1:sqrt(N)
       if(sqrt((x-sqrt(N)/2)^2 + (y-sqrt(N)/2)^2) > sqrt(N)/2) mVec(sqrt(N)*(y-1)+x) = 1E9;       else mVec(sqrt(N)*(y-1)+x) = m;
       end
   end
end
M = diag(mVec); %find M and inverse M
invM = inv(M);

C=zeros(1,N);

%fill K matrix
x=1;
y=1;
for y = 1:N
    for x = 1:N
        if(x == y) K(y,x) = 4*T/a; %if the matrix element corresponds to the mass we are considering, add 4T/a
        elseif(x == y+1 && mod(y,sqrt(N)) ~= 0) K(y,x) = -T/a ; %else if the matrix element is a nearest neighbor to the mass we are considering, add -T/a
        elseif(x == y-1 && mod(y - 1,sqrt(N)) ~= 0) K(y,x) = -T/a;
        elseif(x == y+sqrt(N)) K(y,x) = -T/a;
        elseif(x == y-sqrt(N)) K(y,x) = -T/a;
        end
    end
end

sparseK = sparse(K);

X = transpose(X);
Vel = transpose(Vel);

Xplot = zeros(sqrt(N), sqrt(N));
y=1;
for y = 1:sqrt(N)
    Xplot(y,:) = transpose(X((y-1)*sqrt(N)+1:y*sqrt(N)));
end
figure(fig)
fig = fig + 1;
surf(1:sqrt(N),1:sqrt(N),Xplot);

KMinv = sparse(invM*K);
for t = 1:Nsamples
    Vel = (Vel + (-KMinv*X-gamma.*invM*Vel).*tStep);%.*Boundary;
    X = X + Vel*tStep + 1/2*(-KMinv*X-gamma*invM*Vel)*tStep*tStep;
    A(t) = sum(X);
    %print('sample =');print(t); print(' A = ');print(A(t));
    if(mod(t,10) == 0)fprintf('sample = %f, A = %f \n', t, A(t));end
end
figure(fig)
fig = fig + 1;
plot(1:Nsamples, A);

Xplot = zeros(sqrt(N), sqrt(N));
y=1;
for y = 1:sqrt(N)
    Xplot(y,:) = transpose(X((y-1)*sqrt(N)+1:y*sqrt(N)));
end
figure(fig)
fig = fig + 1;
surf(1:sqrt(N),1:sqrt(N),Xplot);