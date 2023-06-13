//
// Created by Sakura Yang on 2023/5/26.
//

#include <stdio.h>
#include <string.h>

int main ()
{
    char buf[1024];
    FILE *fp = fopen(R"(D:\Xilinx\CS214\uart-tools\prgmip32.coe)", "w");
    FILE *dump = fopen(R"(C:\Users\Sakura Yang\Desktop\dump\dump)", "r");
    if(dump == NULL){
        return -1;
    }
    if(fp == NULL){
        return -1;
    }
    int len = 0;
    int size = 0;
    char T1[] = "memory_initialization_radix = 16;";
    char T2[] = "memory_initialization_vector =";
    fprintf(fp,"%s\n",T1);
    fprintf(fp,"%s\n",T2);
    while (fgets(buf, 1024, dump) != NULL){
        len = strlen(buf);
        buf[len-1] = ',';
        buf[len] = '\n';
        fwrite(buf, len+1, 1, fp);
        size += len-1;
    }
    printf("%d\n",(size)/8);
    int max = 16384;
    int remain = max - (size+1)/8;
    for (int i = 0; i < remain-1; ++i) {
        fwrite("00000000,\n", 10, 1, fp);
    }
    fwrite("00000000;\n", 10, 1, fp);
    fclose(fp);
    fclose(dump);
    return 0;

}