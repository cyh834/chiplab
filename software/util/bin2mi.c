#include <stdio.h>
#include <stdlib.h>

int main(int argc,char *argv[]){
    FILE *in;
    FILE *out;

    int i,j,k;
    unsigned char mem[32];

    in = fopen(argv[1], "rb");
    out = fopen(argv[2],"w");

    fprintf(out, "memory_initialization_radix = 16;\n");
    fprintf(out, "memory_initialization_vector =\n");
    while(!feof(in)) {
        if(fread(mem,1,4,in)!=4) {
            fprintf(out, "%02x%02x%02x%02x\n", mem[3], mem[2],	mem[1], mem[0]);
            break;
        }
        fprintf(out, "%02x%02x%02x%02x\n", mem[3], mem[2], mem[1],mem[0]);
    }
    fclose(in);
    fclose(out);

    return 0;
}