function result = funcDeCode(param, s_Data)
    if param == "pH"
        result = [340; 335];
    elseif param == "tds"
        result = [340; 362];
    elseif param == "cod"
        result = [340; 341];
    else
        result = [340 ;288];
    end
end