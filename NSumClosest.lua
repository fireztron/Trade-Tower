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

function filterIndices(arr, indices)
	local result = {}
	for _,indice in ipairs(indices) do
		table.insert(result, arr[indice])
	end
	return result
end

function getSum(arr)
	local sum = 0
	for _,val in ipairs(arr) do
		sum = sum + val
	end
	return sum
end

function solution(arr, n, target)
	-- Sort the table from highest to lowest
	table.sort(arr, function(a, b)
		return a > b
	end)

	-- Select the last n items from the array and see if the sum of those surpasses target
	local minValue = 0
	for i = #arr, #arr - (n - 1), -1 do
		minValue = minValue + arr[i]
	end
	if minValue > target then return { Success = false } end

	-- Keep the current indices we want to fetch the sum for
	-- initially we fill it with a range of 1..n
	local currentIndices = {}
	local currentIndicesInv = {}
	for idx = 1, n do
		table.insert(currentIndices, idx)
		currentIndicesInv[idx] = #currentIndices
	end

	-- Keep repeating until we've had all possible options
	local iters = 0
	while true do
		-- Calculate the sum of the given indices
		local filteredValues = filterIndices(arr, currentIndices)
		local sum = getSum(filteredValues)
		-- If the sum is below the target, we return the value (future: forward lookahead)
		if sum < target then
			return { Result = sum, MadeWith = filteredValues, Success = true }
		end
				
		-- Check if the last indice is at the end of the array
		if currentIndices[n] == #arr then
			-- If the last indice is at the end of the array we must shift the first
			-- indice AFTER a free position up by 1 and reset all indices after that
			-- in a linear pattern
			local firstFreeIndice = nil
			local firstIndiceAfterFreeIndice = nil

			-- Check backwards if we can find an open indice spot
			for indiceDepth = (#arr - 1), 0, -1 do
				local indicePos = currentIndicesInv[indiceDepth]
				if indicePos == nil then
					firstFreeIndice = indiceDepth
					break
				end
			end

			-- Get the first indice before the free position
			-- FirstFreePos is always set when we reach here since n must be lower than
			-- #arr and n == #arr meaning there's always at least 1 free indice
			for indiceDepth = (firstFreeIndice - 1), 0, -1 do
				local indicePos = currentIndicesInv[indiceDepth]
				if indicePos ~= nil then
					firstIndiceAfterFreeIndice = indiceDepth
					break
				end
			end
			
			-- Shift the item at firstIndiceAfterFreeIndice up by 1
			local indicePos = currentIndicesInv[firstIndiceAfterFreeIndice]
			currentIndices[indicePos] = firstIndiceAfterFreeIndice + 1
			currentIndicesInv[firstIndiceAfterFreeIndice + 1] = indicePos
			currentIndicesInv[firstIndiceAfterFreeIndice] = nil
			
			-- Reset all indices after firstIndiceAfterFreeIndice back to a linear pattern
			local offset = 1
			for i = (firstIndiceAfterFreeIndice + 1), n do
				local invValue = currentIndices[i]
				currentIndices[i] = i + offset
				currentIndicesInv[i + offset] = i
				currentIndicesInv[invValue] = nil
				offset = offset + 1
			end
		else
			-- Shift the last indice up by 1
			local indicePos = currentIndices[n]
			currentIndices[n] = indicePos + 1
			currentIndicesInv[indicePos + 1] = n
			currentIndicesInv[indicePos] = nil
		end
		
		iters = iters + 1
		if iters > 20 then
			return { Success = false }
		end
	end
end

local cases = {}
for i = 1, 100 do
	local arr1, n1, t1 = generateCase()
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
