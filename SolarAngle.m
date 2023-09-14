function solar_zen = SolarAngle(time,lon,lat)
%calculates the solar zenith angle at inputed location and time
%functional with matrices, returns a matrix 
%Time format: UTC julian dates with format yyyyMMddHHmmss or datetime
%Lon format: -180:180
%Lat format: -90:90
%calculations based on https://gml.noaa.gov/grad/solcalc/solareqns.PDF

%seperate time to years, days, minutes, and seconds
if isa(time,'datetime')
    doy = day(time,'dayofyear');
    yr = year(time);
    hr = hour(time);
    min = minute(time);
    sec = second(time);
else
    doy = day(datetime(string(time),'InputFormat','yyyyMMddHHmmss'),'dayofyear'); %1-365, accounts for leap years
    yr = year(datetime(string(time),'InputFormat','yyyyMMddHHmmss')); %year
    hr = hour(datetime(string(time),'InputFormat','yyyyMMddHHmmss')); %0-24 hours
    min = minute(datetime(string(time),'InputFormat','yyyyMMddHHmmss')); %0-60 minutes
    sec = second(datetime(string(time),'InputFormat','yyyyMMddHHmmss')); %0-60 seconds
end

%First, the fractional year (γ) is calculated, in radians, if its a leap
%year uses 366 days vs 365 for a non-leap year
y = NaN(size(yr,1),size(yr,2));
for k = 1:size(y,1)
    for h = 1:size(y,2)
        if leapyear(yr) %returns a boolean, requires aerospace toolbox
            y(k,h) = 2*pi/366.*(doy(k,h)-1+(hr(k,h)-12)/24); %calculation for leap years
        else
            y(k,h) = 2*pi/365.*(doy(k,h)-1+(hr(k,h)-12)/24); %calculation for nonleap years
        end
    end
end

%uses the timezone function to find the time zone of each location
tz = NaN(size(lon,1),size(lon,2));
for k = 1:size(tz,1)
    for h = 1:size(tz,2)
        if isnan(lon(k,h)) %the time zone function cannot deal with NaN values and thus skips them
            tz(k,h) = 0; %0 serves as a placeholder which is later turned into a nan value 
        else
            tz(k,h) = timezone(lon(k,h));  %calculates timezone  
        end
    end
end

%From γ, we can estimate the equation of time (in minutes) and the solar declination angle (in radians)
eqtime = 229.18.*(0.000075 + 0.001868.*cos(y) - 0.032077.*sin(y) - 0.014615.*cos(2*y) - 0.040849.*sin(2*y) );
decl = 0.006918 - 0.399912.*cos(y) + 0.070257.*sin(y) - 0.006758.*cos(2.*y) + 0.000907.*sin(2.*y) - 0.002697.*cos(3.*y) + 0.00148*sin(3.*y);

%true solar time is calculated in the following two equations
%time offset is found, in minutes, and then the true solar time, in minutes
%where eqtime is in minutes, longitude is in degrees (positive to the east of the Prime Meridian), 
%timezone is in hours from UTC (U.S. Mountain Standard Time = –7 hours)
time_offset = eqtime + 4.*lon - 60.*tz;
tst = hr.*60 + min + sec./60 + time_offset;

%solar hour angle, in degrees, is
ha = (tst ./ 4) - 180;

%solar zenith angle () can then be found from the hour angle (ha), latitude (lat) and solar 
%declination (decl) using the following equation

solar_zen = acosd(sin(deg2rad(lat)).*sin(decl) + cos(deg2rad(lat)).*cos(decl).*cos(deg2rad(ha))); 



