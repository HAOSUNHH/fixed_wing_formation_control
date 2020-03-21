%============说明============%
%1. NED地面坐标系
%2. 只有二维平面仿真关系
%===========================%
clear;
clc;
%===
%===变量定义初始化
%===

%类宏定义
GROUP_LENGTH=3000;
GRAVITY_CONSTANT=9.81;

time_stamp = 0; %时间戳，整数增加，用来数组索引
TIMT = zeros(1, GROUP_LENGTH); %时间队列
now = 0.0; %当前时间
d_t = 0.1; %时间间隔
end_time = 100.0; %终止时间

%===
%===领机定义初始化
%===
%位置
led_pos_xg=zeros(1, GROUP_LENGTH);
led_pos_yg=zeros(1, GROUP_LENGTH);
led_pos_xg(1)=150;
led_pos_yg(1)=100;
%速度
led_vel_xg=zeros(1, GROUP_LENGTH);
led_vel_yg=zeros(1, GROUP_LENGTH);
led_vel_xg(1)=0.0;
led_vel_yg(1)=20.0;

%===
%===从机定义初始化
%===

%位置
fol_pos_xg=zeros(1, GROUP_LENGTH);
fol_pos_yg=zeros(1, GROUP_LENGTH);
fol_pos_xg(1)=0;
fol_pos_yg(1)=0;

%速度
fol_vel_xg=zeros(1, GROUP_LENGTH);
fol_vel_yg=zeros(1, GROUP_LENGTH);
fol_vel_xg(1)=15.0;
fol_vel_yg(1)=0;

%速度角度（偏航角）
fol_Psi=zeros(1, GROUP_LENGTH);

%误差
err_pos_xk=zeros(1, GROUP_LENGTH);
err_pos_yk=zeros(1, GROUP_LENGTH);

err_vel_xk=zeros(1, GROUP_LENGTH);
err_vel_yk=zeros(1, GROUP_LENGTH);
err_vel_k=zeros(1, GROUP_LENGTH);

err_mix_xg=zeros(1, GROUP_LENGTH);

%===
%===控制器参数
%===

k_mix_pos=0.8;%机体前向误差-位置混合系数
k_mix_vel=0.8;%机体前向误差-速度混合系数

%==
%==控制器期望值
%==

v_sp_inc=zeros(1, GROUP_LENGTH);
v_sp=zeros(1, GROUP_LENGTH);

%===
%===仿真主循环
%===

for now=0.0:d_t:end_time
    
time_stamp=time_stamp+1;
TIMT(time_stamp)=now;

%===
%===STEP: 得到位置误差、速度大小误差以及速度方向误差
%===
%位置误差
fol_vel_2d=[fol_vel_xg(time_stamp),fol_vel_yg(time_stamp)];
fol_vel_unit=fol_vel_2d/(norm(fol_vel_2d));

%fol_Psi(time_stamp)=atan()%计算此项需要分情况
led_pos_2d=[led_pos_xg(time_stamp),led_pos_yg(time_stamp)];

err_pos_xk(time_stamp)=dot(fol_vel_unit,led_pos_2d);
err_pos_yk(time_stamp)=vec2cross(fol_vel_unit,led_pos_2d);

%速度误差
led_vel_2d=[led_vel_xg(time_stamp),led_vel_yg(time_stamp)];
err_vel_2d=led_vel_2d-fol_vel_2d;

err_vel_xk(time_stamp)=dot(fol_vel_unit,err_vel_2d);
err_vel_yk(time_stamp)=vec2cross(fol_vel_unit,err_vel_2d);

err_vel_k(time_stamp)=sqrt(err_vel_xk(time_stamp)^2+err_vel_yk(time_stamp)^2);

%速度角度误差
if (err_vel_xk(time_stamp)==0)&&(err_vel_yk(time_stamp)>0)%正右方
    fol_Psi(time_stamp)=pi/2;
elseif (err_vel_xk(time_stamp)==0&&err_vel_yk(time_stamp)<0)%正左方
    fol_Psi(time_stamp)=-pi/2;
elseif (err_vel_xk(time_stamp)>0&&err_vel_yk(time_stamp)==0)%正前方
    fol_Psi(time_stamp)=0;
elseif(err_vel_xk(time_stamp)<0&&err_vel_yk(time_stamp)==0)%正后方
    fol_Psi(time_stamp)=pi;

elseif(err_vel_xk(time_stamp)>0&&err_vel_yk(time_stamp)>0)%右前方
    fol_Psi(time_stamp)=atan(err_vel_yk(time_stamp)/err_vel_xk(time_stamp));
elseif(err_vel_xk(time_stamp)>0&&err_vel_yk(time_stamp)>0)%左前方
    fol_Psi(time_stamp)=atan(err_vel_yk(time_stamp)/err_vel_xk(time_stamp));
elseif(err_vel_xk(time_stamp)>0&&err_vel_yk(time_stamp)>0)%右后方
    fol_Psi(time_stamp)= atan(err_vel_yk(time_stamp)/err_vel_xk(time_stamp))+pi;
elseif(err_vel_xk(time_stamp)>0&&err_vel_yk(time_stamp)>0)%左后方
    fol_Psi(time_stamp)= atan(err_vel_yk(time_stamp)/err_vel_xk(time_stamp))-pi;
end

%===
%===STEP: 获得机体前向速度期望值
%===

err_mix_xg(time_stamp)=k_mix_pos*err_pos_xk(time_stamp)+k_mix_vel*err_vel_k(time_stamp);

[err_prev,err_2prev]=find_err(time_stamp,err_mix_xg);
%按照情况选定误差，调用增量
    
v_sp_inc(time_stamp) = Incremental_PID(0.1, 0.1, 0.0, err_2prev, err_prev, err_mix_xg(time_stamp));

if(time_stamp==1)
v_sp(time_stamp)=v_sp_inc(time_stamp);
elseif(time_stamp>=2)
v_sp(time_stamp)=v_sp_inc(time_stamp)+v_sp(time_stamp-1);
end

%===
%===STEP: 获得机体侧向向加速度速度期望值
%===

%===
%===STEP: 更新从机状态
%===

%===
%===SUB_STEP: 根据航迹侧向加速度计算地面之中的分量
%===

%===
%===SUB_STEP: 更新从机速度
%===



%===
%===SUB_STEP: 更新从机位置
%===

%===
%===STEP: 更新领机状态
%===

%===
%===SUB_STEP: 根据航迹侧向加速度计算地面之中的分量
%===

%===
%===SUB_STEP: 更新领机速度
%===

%===
%===SUB_STEP: 更新领机位置
%===
end