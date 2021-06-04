--[[
	For n = 1:
		Time complexity = O[1]
	For n = 2:
		Time complexity = O[2]
	For n > 2:
		Time complexity = O[N^n]

	The time complexity for n > 2 can be reduced by n - 1 for O[N^n] time complexity using pointers, however n > 2 is written with a bruteforce method and is slower than if calculated with pointers.
]]

--// Generate case
function generateCase()
    local arr = {}
    local maxArrValue = 20
    local arrcount = math.random(3, 7) + 1
    for i = 1, arrcount do
        table.insert(arr, math.random(maxArrValue))
    end
    local n = math.random(2, arrcount - 1)
    local target = math.random(arrcount * maxArrValue)
    return arr, n, target
end

--// Checks if it maxed out
local function isMaxed(indexes, index1, arrLength)
    local max1 = indexes[#indexes]
    local min1 = indexes[index1]
    local n = #indexes - index1 + 1 --number of elements

    return max1 - min1 + 1 == n and max1 == arrLength
end

--// Reset indexes
local function resetIndexes(indexes, startIndexReset)
    local res = {}
    for i = indexes[startIndexReset], indexes[startIndexReset] + #indexes - 1 do
        table.insert(res, i)
    end
    
    return res
end

--// Calculate sum
local function getSum(arr, indexes)
    local sum = 0
    local res = {}
    for position, index in ipairs(indexes) do
        sum = sum + arr[index]
        res[position] = arr[index]
    end
    return sum, res
end

local function solution(arr, n, target)
    local foundSum = false
    local closestSum = math.huge
    local res = {}
    
    -- Sort the table from lowest to highest
    table.sort(arr)
    
    -- Select the last n items from the array and see if the sum of those surpasses target
    local minValue = 0
    for i = 1, n, 1 do
        minValue = minValue + arr[i]
    end
    if minValue > target then return { Success = false } end
    
    if n == 1 then
        for _, currentNum in ipairs(arr) do
            if math.abs(target - closestSum) > math.abs(target - currentNum) and currentNum <= target then
                closestSum = currentNum
                res = {currentNum}
                foundSum = true
            end	
        end
        if not foundSum then
           return {Success = false} 
        end
        return {Result = closestSum, MadeWith = res, Success = true}
    elseif n == 2 then
        local res_l, res_r = 0,0 --result pair
    
        local l, r = 1, #arr
    
        while(r >= 1 and l <= #arr) do
            local sum = arr[l] + arr[r]
            if math.abs(target - closestSum) > math.abs(target - sum) and sum <= target then
                res_l = l
                res_r = r
                closestSum = sum
                foundSum = true
            end
            if arr[l] + arr[r] > target then
                r = r - 1
            else
                l = l + 1
            end
        end
        
        res = {arr[res_l], arr[res_r]}
        if not foundSum then
           return {Success = false} 
        end
        return {Result = closestSum, MadeWith = res, Success = true}
    elseif n > 2 then
        --// arr does not need to be sorted
        
        --// Prepare indexes to check
        local indexes = {}
        for i = 1, n, 1 do
            indexes[i] = i --indexes[position] = index
        end
        
        --// Loop through whole array
        local index = #indexes
        while indexes[index] and indexes[1] <= #arr - n + 1 do
                
            --Check sum here and update current sum
            local sum, tmpres = getSum(arr, indexes)
            if math.abs(target - closestSum) > math.abs(target - sum) and sum <= target then
                closestSum = sum
                res = tmpres
                foundSum = true
            end
    
            --// Keep adding to index and checking sums
            while (indexes[index + 1] == nil and indexes[index] < #arr) or (indexes[index + 1] and indexes[index + 1] ~= indexes[index] + 1) do
    
                --// add next index
                indexes[index] = indexes[index] + 1
    
                --Check sum here and update current sum
                local sum, tmpres = getSum(arr, indexes)
                if math.abs(target - closestSum) > math.abs(target - sum) and sum <= target then
                    closestSum = sum
                    res = tmpres
                    foundSum = true
                end
                
            end
    
            index = index - 1
            if index >= 1 then
                if not isMaxed(indexes, index, #arr) then
                    --// Go back an index
                    indexes[index] = indexes[index] + 1
                    indexes[index + 1] = indexes[index] + 1
                    index = index + 1
                else
                    --// Reset indexes
                    index = index - 1
                    indexes[index] = indexes[index] + 1
                    indexes = resetIndexes(indexes, index)
                    index = #indexes
                end
            end
        end
        if not foundSum then
           return {Success = false} 
        end
        return {Result = closestSum, MadeWith = res, Success = true}
    end
end

local cases = {}
for i = 1, 100 do
    local arr1, n1, t1 = generateCase()
    table.sort(arr1)
    table.insert(cases, { arr = arr1, n = n1, target = t1 })
end
for _, case in ipairs(cases) do
    print("Case: " .. table.concat(case.arr, ",") .. " n = " .. case.n .. " target = " .. case.target)
    local sol = solution(case.arr, case.n, case.target)
    if sol.Success then
        print("Solution: " .. sol.Result .. " (" .. table.concat(sol.MadeWith, ",") .. ")")
    else
        print("No valid solution")
    end
end
