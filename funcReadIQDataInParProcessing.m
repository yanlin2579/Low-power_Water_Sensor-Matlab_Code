function IQData = funcReadIQDataInParProcessing(sFileName, gnReadRange, nRawFs, nFs, nDivCount, nMaxCoreCount)
%% 参数与返回值
% - sFileName：文件名
% - gnReadRange：读取范围，[a, b]表示读取文件a到b之间的部分，且0<=a<b<=1。如[0.1, 0.9]则表示读取10%到90%的之间的部分
% - nRawFs：sFileName中的信号的原始频率
% - nFs：新的采样频率
% - nDivCount：将文件切分为nDivCount份，切分数与并行处理能力正相关。但切分数太多，或切分数大于电脑CPU核心数量可能会导致性能下降
% - nMaxCoreCount：调用电脑的核心数量，当大于电脑实际核心数的时候，将设置为实际核心数
% - IQData：返回读取的IQ信号，读取失败则返回数字0
%% 代码
    % 输入合法判断
    if gnReadRange(1) < 0 || gnReadRange(1) > 1 || gnReadRange(2) < 0 || gnReadRange(2) > 1
        IQData = 0;
        return;
    end

    if nRawFs<nFs
        IQData = 0;
        return;
    end

    % 计算文件大小
    pFile = fopen(sFileName, "r");
    fseek(pFile,0,'eof'); 
    nFileSize = ftell(pFile);
    fclose(pFile);
    
    % 参数初始化
    nFileSkipDistance = (floor(nRawFs/nFs)-1); % 读取一次一个完整的复数后，跳过的距离（跳过多少个复数）
    IQ = cell(1, nDivCount);  % 计算时的IQ数据，为了使得并行处理时数据分离，所以采用cell装入不同部分的数据
    nStartLocation = nFileSize*gnReadRange(1);
    nEndLocation = nFileSize*gnReadRange(2);
    nStartLocation = nStartLocation - rem(nStartLocation, 8);  % 开始读取位置
    nEndLocation = nEndLocation - rem(nEndLocation, 8);  % 读取截止位置
    nReadSize = nEndLocation - nStartLocation;  % 读入大小
    
    parfor (i = 1:nDivCount, nMaxCoreCount)  % 并行for
        pFile = fopen(sFileName, "r");
        fseek(pFile, (i-1)*4*2*floor(nReadSize/(nDivCount*4*2))+nStartLocation, "bof");  % 乘4是因为float32为4个字节，乘2是因为实部和虚部各一个float32
        while ftell(pFile) < i*4*2*floor(nReadSize/(nDivCount*4*2))+nStartLocation
            IQ{1,i} = [IQ{1,i} complex(fread (pFile, 1, 'float32'), fread (pFile, 1, 'float32'))];
            fseek(pFile, nFileSkipDistance*4*2, "cof");
        end
        fclose(pFile);
    end
    
    IQData = cell2mat(IQ);
end