#define MATRIX_DIMENSION 2


int main() {
    
     std::random_device rd; 

    std::mt19937 gen(rd()); 

    std::uniform_int_distribution<int> distrib(1, 6); 
    
    int firstarr[MATRIX_DIMENSION][MATRIX_DIMENSION] = {0};
    int secondarr[MATRIX_DIMENSION][MATRIX_DIMENSION] = {0};
    
    int result[MATRIX_DIMENSION][MATRIX_DIMENSION] = {0};
    
    
    for(int j=0; j<MATRIX_DIMENSION;j++){
        for(int i=0; i<MATRIX_DIMENSION;i++){
            firstarr[j][i]=distrib(gen);
            secondarr[j][i]=distrib(gen);
        }
    }
    
    
    
    for(int i=0; i<MATRIX_DIMENSION;i++){
       // int res = 0;
        for(int j=0; j<MATRIX_DIMENSION;j++){
            int res = 0;
            for(int k=0; k<MATRIX_DIMENSION;k++){
                
                res+=firstarr[i][k]*secondarr[k][j];
                
            }
            
            result[i][j]+=res;
        }
        
    }
    
    // i =0; j=0; k=0;
    
    
    
    printf("firstarr Matrix\n");
    for(int i=0; i<MATRIX_DIMENSION;i++){
        for(int j=0; j<MATRIX_DIMENSION;j++){
            printf("%d ",firstarr[i][j]);
        }
        
        printf("\n");
    }
    
    printf("\n");
    
    printf("secondarr Matrix\n");
    for(int i=0; i<MATRIX_DIMENSION;i++){
        for(int j=0; j<MATRIX_DIMENSION;j++){
            printf("%d ",secondarr[i][j]);
        }
        
        printf("\n");
    }
    printf("\n");
    
    printf("Result Matrix\n");
    for(int i=0; i<MATRIX_DIMENSION;i++){
        for(int j=0; j<MATRIX_DIMENSION;j++){
            printf("%d ",result[i][j]);
        }
        
        printf("\n");
    }
    
}
