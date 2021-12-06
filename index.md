### My Goal

Mass application of herbicide is a cornerstone of modern agriculture, allowing weed control over larger and larger acres. However, overapplication in the last few decades is costing unnecessary amounts to farmers as well as contaminating freshwater lakes, streams and rivers. USDA estimates put herbicide drift in particular as responsible for over 55% of these sources being contaminated. In order to reduce the necessary application rates of herbicide, modeling the distribution of spray is done to simulate how much liquid will be applied upon detection of a weed. 

## Distribution modeling
To do this, and avoid having to simulate every amount of nozzles individually, one such method is to take the distribution of one nozzle and simply 'stack' them, or place a distribution centered at each nozzle location and sum overlapping data. The graphs below are examples of this for three nozzles, plotted between 50-100 cm (20"-40")
![img](40Deg.gif)


Error between this method and actual results with these nozzle amounts is expected, and for this study my overall question is: *"Is error between modeled spray and real spray significant?"*, with the follow-up of *"If so, is the error predictable and repeatable based on location?"*

## Materials
[Here](NozzleBootstrap.m) is the MATLAB code used to run the analysis

[Here](Patternator1DataSheet.xlsx) is the datasheet used. This folder needs to go in MatLAB folder or whatever directory is currently on the MATLAB path. 

While there is data for a combination of nozzles, heights and amounts, at the moment only the F8003 nozzle at 30" Height and 15" Spacing contains enough samples to run a good analysis for a 3-nozzle setup. When editing the code and changing inputs, change information in the "Input" tab in the data sheet. The code utilizes these inputs to index search the table  

## Analysis
![img](Graph1.png)
*Sample mean distribution plots*

The first output of the code is taking the mean of the individual samples in each column. Since there are three nozzles at 15" Spacing, the model emulates a nozzle at -15", 0" and 15", done by shifting the 1" matrix columns accordingly during calculation. This gives a quick visual cue of the true data peaking off to the left of center, but for more meaningful numbers we will get the errors of individual samples as percentages, where (Error %) = ((Stacked Data)-(Real Data)/(Real Data)), with divide by zero columns being ignored. The results for the first three samples are shown here
![img](Graph2.png)

This will be our "training" data that gets three values for expected error at each location. For the farther values, the errors can seems alarmingly high, but that is because they are relative to very small values. (e.g. if the true data is .7 mL and the stacked data is 1.0 mL, this would record a nearly 50% error) but the inner values seem to oscillate between -20% and +20%. Interestingly, the data *roughly* follows a sort of sinusoidal oscillation, so a sine function regresssion fitting was done as follows.
![img](Graph3.png)

However, trying to find the error behavior is only useful if the error behavior is consistent and can be corrected. To do this, I took the three samples of error and bootstrapped the data, simulating the mean of 1,000 samples from this "population". Using an assumed t-distribution, a 95% CI was constructed for the error at each point. This confidence interval was then converted into an expected three-nozzle distribution bounds, and all three sets of training data were evaluated to see the accuracy of these bounds.

![img](Graph4.png)

Less than half of the datapoints were actually following the model, with the most important central datapoints being nearly all outside of these bounds, nowhere near the 95% of datapoints that would be expected. Unfortunately, it does not appear that there is a consistent source or pattern of error in the stacking model that can be numerically modeled, so our answer to both objective questions is no.

## Next steps

Without a way to properly calculate the error relationship between the stacked model and real data, we can still utilize this data to set guidelines for future use. For this particular setup, we could observe that the error between the spacing coordinates (-15" to 15") varied from -20% to +20%, and when utilizing stacking in the future note that all values trying to reach a target threshold surpass it by such that even -20% error still satisfies the value necessary. 

## Assignment

Using this code as a reference, write code that will take the minimum value of error between -15" and 15" (a.k.a the maximum negative error) for a given nozzle setup. Then, enter a target mL range, and have the code plot the data factored with the maximimum negative error against this target, and return the proportion of columns that reached the minimum target amount.

