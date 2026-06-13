
std::vector<int> counting_sort(std::vector<int>& input, int size, int bit_position);
std::vector<int> radixSort(std::vector<int> arr);

int main() {
   
    std::vector<int> input = {1,1,2,0,2,0,4,3};
    auto x = radixSort(input);
    
   for(const int& y : x){
       printf("%d ",y);
   }
    
}

std::vector<int> radixSort(std::vector<int> arr){
    
    
    int current_max = std::ranges::max(arr);
    int bit_position = 31 - __builtin_clz(current_max);
    uint32_t current_mask = 1;
    
    std::vector<int> buffer=arr;
    
    for(int i=0; i<=bit_position; i++){
        buffer  = counting_sort(buffer,buffer.size(),i);
        
    }
    
    
    
    return buffer;
}

std::vector<int> counting_sort(std::vector<int>& input, int size, int bit_position){
    
    std::vector<int> temp(2, 0);  
    std::vector<int> result(size, 0);
    
    uint32_t mask = 1 << bit_position;
    
    for(int i = 0; i < size; i++){
        int bit = (input[i] & mask) ? 1 : 0;  
        temp[bit]++;
    }
    
    
    temp[1] += temp[0];
    
    for(int i = size-1; i >= 0; i--){
        int bit = (input[i] & mask) ? 1 : 0;
        result[temp[bit] - 1] = input[i];
        temp[bit]--;
    }
    
    return result;
}
