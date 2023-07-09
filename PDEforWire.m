L = 1;
WireTemp=300;%電熱線温度[℃]
OutSideTemp = 30;%初期条件、室温[℃]
Div = 50;
x = linspace(0,L ,Div);
t = [linspace(0,100,Div)];    %[s]
%global WireTemp;
%WireTemp = 130;  ←認識されない
%global Coefficient;
Prop = readtable("ThermoConductivity.xlsx",'Range','B2:E5');
glassInner = 0.02;     %ガラス管の内径（直径）[m]
glassOuter = 0.04;    %ガラス管の外径（直径）[m]
MandrelInner = 0.35;     %マンドレルの内径（直径）[m]
MandrelOUter = 0.4;  %[m]
ThicknessOfInsulation = 0.1;  %[m]
if glassOuter > MandrelInner
    error('Invalid Input! Please check the value of glassInner.')
end
LastOutline = (MandrelOUter + ThicknessOfInsulation)/2;   %[m] 最外形を計算、以降各寸法を無次元化・正規化する
% global Coefficient;
% global SpecificHeatCapacity;
Coefficient= zeros(1,Div);    %各部熱伝導率行列の作成[W/m・K]
SpecificHeatCapacity = zeros(1,Div);    %容積比熱（比熱×密度）行列の作成[J/m^3・K]
for ii = 1:Div
    if ii < glassInner/(2*LastOutline)*Div   %ガラス管の内部
        Coefficient(ii) = Prop{2,1};
        SpecificHeatCapacity(ii) = Prop{2,4};
        continue
    elseif ii < glassOuter/(2*LastOutline)*Div    %ガラス管
        Coefficient(ii) = Prop{1,1};
        SpecificHeatCapacity(ii) = Prop{1,4};
        continue
    elseif ii < MandrelInner/(2*LastOutline)*Div    %マンドレル内中空部
        Coefficient(ii) = Prop{2,1};
        SpecificHeatCapacity(ii) = Prop{2,4};
        continue
    elseif ii < MandrelOUter/(2*LastOutline) *Div   %マンドレル金属部
        Coefficient(ii) = Prop{3,1};
        SpecificHeatCapacity(ii) = Prop{3,4};
        continue
    else                                  %断熱材部分
        Coefficient(ii) = Prop{4,1};
        SpecificHeatCapacity(ii) = Prop{4,4};
    end
end
Cylinderize = linspace(1,Div*2 -1,Div);   %円柱座標との数値的な変換
Coefficient = (1/LastOutline).*Coefficient;
SpecificHeatCapacity = LastOutline.* SpecificHeatCapacity;
SpecificHeatCapacity = SpecificHeatCapacity .* Cylinderize;

%%

m = 0;     %円柱座標を指定すると中心で加熱することが定式化できないので一応デカルトで解く
sol = pdepe(m,make_heatpde(SpecificHeatCapacity,Coefficient,Div),make_heatic(OutSideTemp),make_heatbc(WireTemp,OutSideTemp),x,t);
%%
colormap hot
imagesc(x,t,sol)
colorbar
xlabel('Distance x','interpreter','latex')
ylabel('Time t','interpreter','latex')
title('Heat Equation for $0 \le x \le 1$ and $0 \le t \le 5$','interpreter','latex')
%%
function fcn=make_heatpde(SpecificHeatCapacity,Coefficient,Div)
    fcn=@heatpde;
function [c,f,s] = heatpde(x,t,u,dudx)
    idx=int16(Div*x);
c = SpecificHeatCapacity(idx);
f = dudx * Coefficient(idx)  ;
s = 0;
end
end

function fcn=make_heatic(OutSideTemp)
    fcn=@heatic;
function u0 = heatic(x)   %initial Condition
u0 = OutSideTemp;
end
end

function fcn=make_heatbc(WireTemp,OutSideTemp)
    fcn=@heatbc;
function [pl,ql,pr,qr] = heatbc(xl,ul,xr,ur,t) %Boundary Condition
pl = ul - WireTemp;
ql = 0;
pr = ur - OutSideTemp;
qr = 0;
end
end
