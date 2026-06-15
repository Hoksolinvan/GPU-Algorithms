
std::vector<int> counting_sort(std::vector<int>&input);
void radix_sort(std::vector<int>& input);

int main() {
   
    std::vector<int> input = {1,1,2,0,2,0,4,3};
    auto x = counting_sort(input);
    
   

}



std::vector<int> counting_sort(std::vector<int>& input, int current_max){
    
    
    
    std::vector<int>temp(current_max+1,0);
    std::vector<int>result(input.size(),0);
    
    for(int i=0; i<input.size();i++){
        
        temp[input[i]]++;
    }
    
    for(int i=1; i<(current_max+1);i++){
        temp[i]+=temp[i-1];
    }
    
    
    
    for(int back = input.size()-1;back>=0;back--){
        
        result[temp[input[back]]-1]=input[back];
        
        temp[input[back]]--;
    }
    
    
    
    
    return result;
}
