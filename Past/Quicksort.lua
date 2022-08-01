local function swap(list, a, b)
  local prev = list[a];
  list[a] = list[b];
  list[b] = prev;
end

local function partition(list, low, high)
  local pivot = list[high];
  local i = low - 1;
  for j = low, high - 1 do
    if (list[j] < pivot) then
      i = i + 1;
      swap(list, i, j);
    end
  end
  swap(list, i + 1, high);
  return i + 1;
end

local function quicksort(list, low, high)
  if (low < high) then
    local pivot = partition(list, low, high);
    quicksort(list, low, pivot - 1);
    quicksort(list, pivot + 1, high);
  end
end

local function sort(list)
  quicksort(list, 1, #list);
  return list;
end

print(textutils.serialise(sort(nums)));