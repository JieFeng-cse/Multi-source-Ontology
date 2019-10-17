%ʹ��GPU
parallel.gpu.GPUDeviceManager.instance.selectDevice(1);
classNames = ["Hand" "Background"];
labels = [1 2];
% ʹ�� imageDatastore �� pixelLabelDatastore ����ѵ������
imageFolderTrain = 'D:\ImageNet\hand_labels\HandSegmentation\Experiment\SquareTraining';
labelFolderTrain = 'D:\ImageNet\hand_labels\HandSegmentation\Experiment\SquareLabels';
imageTrain = imageDatastore(imageFolderTrain);
labelTrain= pixelLabelDatastore(labelFolderTrain,classNames,labels);

% �۲����ǩ��ͼƬ����
% I = read(imds);
% C = read(pxds);
% categories(C{1})
% B = labeloverlay(I,C{1});
% figure
% imshow(B)

% ������ǿ
augmenter = imageDataAugmenter('RandXReflection',true,...
    'RandXTranslation',[-10 10],'RandYTranslation',[-10 10]);

pximdsTrain = pixelLabelImageDatastore(imageTrain,labelTrain, ...
    'DataAugmentation',augmenter);

% ������֤����
imageFolderValid='D:\ImageNet\hand_labels\HandSegmentation\Experiment\Valid';
labelFolderTrain='D:\ImageNet\hand_labels\HandSegmentation\Experiment\ValidLabels';
Validset=imageDatastore(imageFolderValid);
Validlabels=pixelLabelDatastore(labelFolderTrain,classNames,labels);
validdata = pixelLabelImageDatastore(Validset,Validlabels);

% ����һ������ѵ�����ݵ�����Դ������ȡÿ����ǩ�����ؼ�����
tbl = countEachLabel(pximdsTrain)

% ʹ����Ƶ�ʼ�Ȩ������Ȩ��
numberPixels = sum(tbl.PixelCount);
frequency = tbl.PixelCount / numberPixels;
classWeights = 1 ./ frequency;

% ����һ���������ط�������磬������һ��ͼ������㣬�����С��Ӧ������ͼ��Ĵ�С����������ָ����Ӧ�ھ���㡢������һ����� ReLU ��������顣����ÿ������㣬ָ�� 32 �����е�������ϵ���� 3��3 ����������ͨ���� 'Padding' ѡ������Ϊ 'same' ��ָ�����������Ϊ�������ͬ�Ĵ�С��Ҫ�����ؽ��з��࣬�����һ������ K �� 1��1 ����ľ���㣨���� K ������������������һ�� softmax ���һ����������Ȩ�ص� pixelClassificationLayer��
inputSize = [720 720 3];
filterSize = 6;
numFilters = 32;
numClasses = numel(classNames);

disp('Building network...')
layers = [
    imageInputLayer(inputSize,'Name','input')
    
    convolution2dLayer(filterSize,numFilters,'DilationFactor',1,'Padding','same','Name','conv1')
    batchNormalizationLayer('Name','BN1')
    reluLayer('Name','ReLU1')
    
    convolution2dLayer(filterSize,numFilters,'DilationFactor',2,'Padding','same','Name','conv2')
    batchNormalizationLayer('Name','BN2')
    reluLayer('Name','ReLU2')
    
    convolution2dLayer(filterSize,numFilters,'DilationFactor',4,'Padding','same','Name','conv3')
    batchNormalizationLayer('Name','BN3')
    reluLayer('Name','ReLU3')
    
    convolution2dLayer(1,numClasses,'Name','conv4')
    softmaxLayer('Name','softmax')
    pixelClassificationLayer('Classes',classNames,'ClassWeights',classWeights,'Name','output')];

% lgraph = layerGraph(layers);
% analyzeNetwork(lgraph);

checkpointPath='D:\ImageNet\hand_labels\HandSegmentation\Experiment';

options = trainingOptions('sgdm', ...
    'Momentum', 0.9, ...
    'MaxEpochs', 2, ...
    'MiniBatchSize', 20, ... 
    'ValidationData',validdata, ...
    'ValidationFrequency',40, ...
    'InitialLearnRate', 1e-2, ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropFactor',0.5,...
    'LearnRateDropPeriod',40, ...
    'L2Regularization',0.01, ...
    'Shuffle','every-epoch', ...
    'Plots','training-progress',...
    'ExecutionEnvironment','cpu', ...
    'CheckpointPath',checkpointPath,...
    'verbose',true,...
    'VerboseFrequency',10);
disp('Start training...')
net = trainNetwork(pximdsTrain,layers,options);