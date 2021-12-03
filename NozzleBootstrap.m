close all
clear all
BinSpacing = 1; %Sets bin spacing, grouping by 1,2 or 4 inches
[Archive,~,ArchiveTypesCell] = xlsread('Patternator1DataSheet.xlsx','Raw Data'); %reads 1-D data
ArchiveTypes = string(ArchiveTypesCell(:,3)); %reads archived nozzle types
[BoomInput,StrInput,Input] = xlsread('Patternator1DataSheet.xlsx','Input'); %gets input page info
Time=BoomInput(:,2);Spacing=BoomInput(:,3);XFirst=BoomInput(:,4);Height=BoomInput(:,5);
NozzCt=round(BoomInput(:,6));PSI=BoomInput(:,7);
%break down info into variable names
[row,~] = size(BoomInput); %detects table size
CountEnd=row+3;%accounts for file spacing
Range = append('H4:H',int2str(CountEnd));%
[~,~,Type] = xlsread('Patternator1DataSheet.xlsx','Input',Range); %finds corressponding nozzle types in user table
Type = string(Type); %reads nozzle names
[NozzInfoNum,~,NozzInfo] = xlsread('Patternator1DataSheet.xlsx','NozzleInfo');%Finds nozzle names from database
NozzInfoString = string(NozzInfo(2:length(NozzInfo),1));%stores primary nozzles names
Size = NozzInfoNum(:,2); 
XColumns=-58:BinSpacing:58; %Sets an x-data set for position using bins
% XMids= XColumns(2:length(XColumns))-BinSpacing/2;
for r=1:row %main loop for each row of input
%     TargetIndex = XColumns>=-Spacing(r)&XColumns<=Spacing(r); 
%     MidIndex = XMids>=-Spacing(r)&XMids<=Spacing(r);
    h=figure; %creates plot
    set(gcf,'Position',[0 100 1000 600]); %plot formatting
    CurrentNozzIndex = NozzInfoString==Type(r);%checks for nozzle name
    Angle=NozzInfoNum(CurrentNozzIndex,1); %reads corresponding nozzle angle
    ArchiveHeights = unique(Archive(:,1)); %stored data nozzle heights
    ArchiveIndex=Archive(:,5)==Height(r)&Archive(:,4)==1&ArchiveTypes==Type(r);
    %Index searches for 1-nozzle data using the input type and height
    VolData=Archive(ArchiveIndex,7:123);
    %Assigns the volume data columns from -58" to 58"
    NozzVols=zeros(NozzCt(r),length(VolData));
    %initialize matrix to store stacked data
    Locations=-1*floor((NozzCt(r)-1)/2):ceil((NozzCt(r)-1)/2);
    %creates vector with relative locations
    sz=size(VolData);
    ThreeNozzInd=Archive(:,5)==Height(r)&Archive(:,4)==3&ArchiveTypes==Type(r);
    ThreeVolData=Archive(ThreeNozzInd,7:123);szThree=size(ThreeVolData);
    %find and index the three-nozzle data
    ThreeVolMean=mean(ThreeVolData); %mean data
    Errors=BinSum(zeros(sz),XColumns);MeanData=Errors;
    OneMean=mean(VolData);Columns=length(OneMean);OneMatrix=zeros(3,Columns);
    %create storage matrices 
    OneMatrix(1,1:Columns-Spacing)=OneMean((Spacing+1):Columns);
    OneMatrix(2,:)=OneMean;
    OneMatrix(3,(Spacing+1):Columns)=OneMean(1:Columns-Spacing);
    %Create three nozzles by assigning values offset by spacing
    br=bar(-58:58,OneMatrix,'stacked','DisplayName','Stacked Data');
    br(1).FaceColor='c';br(2).FaceColor='c';br(3).FaceColor='c';
    br(1).LineWidth=1;br(2).LineWidth=1;br(3).LineWidth=1;
    hold on
    plot(-58:58,ThreeVolMean,'-o','DisplayName','3-Nozzle Data')
    xlim([-40 40])
    title('Raw Stacked Data vs 3-Volume data')
    ylabel('Volume (mL)')
    ylabel('Location from center (in.)')
    yyaxis right
    ylim([0 Height+2])
    scatter(Spacing(r)*Locations,[Height Height Height],'^','DisplayName','Nozzle Location')
    %create bar and line chart for comparison
    legend
    grid on
    figure
    set(gcf,'Position',[0 100 700 600])
    %new plot
    for l=1:sz(1) %loop for every "training" data entry
        OneNozzData=VolData(l,:); 
        TrueData=ThreeVolData(l,:); %get One nozzle and "True" 3 Nozzle Data
        for n=1:3 %loop 
            Offset=round(Spacing(r)*Locations(n));
            if Offset<0 %alternate method to stacking using if statement
                NozzVols(n,1:(length(OneNozzData)+Offset))=OneNozzData((-1*Offset+1):length(OneNozzData));
                %Data stack with negative offset
            else
                NozzVols(n,(Offset+1):length(OneNozzData))=OneNozzData(1:(length(OneNozzData)-Offset));
                %Data stack with positive offset
            end
        end
        OneSumData=sum(NozzVols); MeanData(l,:)=BinSum(OneSumData,XColumns);
        NormSumData=OneSumData/sum(OneSumData); OneNormBin=BinSum(NormSumData,XColumns);
        NormTrue=TrueData/sum(TrueData); NormBin=BinSum(NormTrue,XColumns);
        %sum all data and convert into normalized values for comparison
        Errors(l,:)=(OneNormBin-NormBin)./NormBin;
        Errors(isnan(Errors))=0;
        %calculate error percentage/filter divide by zero error
    end
    hold on   
    plot(XColumns,100*Errors) %plot errors used for bootstrap data
    title('Errors of training samples')
    hold on
    xlim([-40 40])
    yline(0)
    xline(0)
    ylabel('Error %')
    xlabel('Position (in.)')
    grid on
    figure
    title('Error bars fit to sine curve')
    errorbar(XColumns,mean(100*Errors),std(100*Errors),'DisplayName','Error means w/deviation bar')
    %plot error bars
    xlim([-40 40])
    yline(0)
    xline(0)
    ylabel('Error %')
    xlabel('Position (in.)')
    SineFit(XColumns,mean(100*Errors))
    figure
    ErrorBoot=bootstrp(1000,@mean,Errors); %get 1000 bootstrapped samples from training data
    ErrorBootMeans=mean(ErrorBoot);ErrorBootStd=sqrt(3)*std(ErrorBoot); 
    %get mean and deviation of 1000 samples
    ErrorBootLow=ErrorBootMeans-2*ErrorBootStd;ErrorBootHigh=ErrorBootMeans+2*ErrorBootStd; 
    %get 2 sigma 95% bounds
    TestSamples=szThree(1)-l;TestThreeData=ThreeVolData((l+1):szThree(1),:); 
    %use rest of samples for testing
    TestThreeBin=BinSum(TestThreeData,XColumns); %format data to bins
    LowMatrix=zeros(size(TestThreeBin));
    HighMatrix=LowMatrix;PlotMatrix=LowMatrix; %create matrices for storage
    ModelBoundsHigh=mean(MeanData./(1+ErrorBootLow));ModelBoundsLow=mean(MeanData./(1+ErrorBootHigh));
    %get upper and lower bounds volume bounds using error 95% CI
    for test=1:TestSamples
        LowMatrix(test,:)=ModelBoundsLow; HighMatrix(test,:)=ModelBoundsHigh;
        PlotMatrix(test,:)=XColumns; %make a same size matrix for testing data
    end
    ConfidenceIndex=TestThreeBin>=LowMatrix&TestThreeBin<=HighMatrix;
    %use matrices to find all values within bounds
    WrongIndex=ConfidenceIndex==0; %rest of values
    WrongMatrix=find(TestThreeBin(WrongIndex));
    RightMatrix=find(TestThreeBin(ConfidenceIndex));
    bar(XColumns,mean(MeanData),'DisplayName','Stacked One Nozzle') %plot original one stack data
    hold on
    plot(XColumns,ModelBoundsHigh,'DisplayName','95% Trained Upper Bounds')
    plot(XColumns,ModelBoundsLow,'DisplayName','95% Trained Lower Bounds')
    %plot predicted model confidence interval
    scatter(PlotMatrix(ConfidenceIndex),TestThreeBin(ConfidenceIndex),'g','DisplayName','Test values predicted')
    scatter(PlotMatrix(WrongIndex),TestThreeBin(WrongIndex),'r','DisplayName','Test values not predicted')
    %plot values in and out of bounds
    title(append('Stack Model vs Real Data: ',num2str(round(100*length(RightMatrix)/(length(RightMatrix)+length(WrongMatrix)),2)),'% data within 3-sigma'))
    xlabel('Position from center (in)')
    ylabel('Volume (mL)')
    legend
    xlim([-40 40])
end

function BinsVol = BinSum(OneBin,SpacedBins) %function that refits data to defined bins
sz = size(OneBin);
BinsVol = zeros(sz(1),length(SpacedBins));
BaseBins=zeros(size(OneBin));
for t=1:sz(1)
    BaseBins(t,:) = -58:58;
end
for n=1:length(SpacedBins)
    if n==1||n==length(SpacedBins)
        NewInd = BaseBins==SpacedBins(n);
    else
        NewInd = BaseBins>SpacedBins(n-1)&BaseBins<=SpacedBins(n);
    end
    Group = OneBin(NewInd);GCols=length(Group)/sz(1);
    GroupMat=zeros(sz(1),GCols);GroupMat(:)=Group;
    if GCols==1
        BinsVol(:,n)=GroupMat;
    else
        GroupMat=transpose(GroupMat);
        BinsVol(:,n)=sum(GroupMat);
    end
end
end
function SineFit(InputX,InputY) %function that fits a sine curve to data
    Index = InputY~=0;
    x = InputX(Index);
    y = InputY(Index);
    yu = max(y);
    yl = min(y);
    yr = (yu-yl);                               % Range of ‘y’
    yz = y-yu+(yr/2);
    zx = x(yz .* circshift(yz,[0 1]) <= 0);     % Find zero-crossings
    per = 2*mean(diff(zx));                     % Estimate period
    ym = mean(y);                               % Estimate offset
    fit = @(b,x)  b(1).*(sin(2*pi*x./b(2) + 2*pi/b(3))) + b(4);    % Function to fit
    fcn = @(b) sum((fit(b,x) - y).^2);                              % Least-Squares cost function
    s = fminsearch(fcn, [yr;  per;  -1;  ym])  ;                     % Minimise Least-Squares
    xp = linspace(min(x),max(x));
    plot(x,y,'b',  xp,fit(s,xp), 'r','DisplayName','Sine curve fit')
    grid on
    legend
end