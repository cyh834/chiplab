#include <stdio.h>
#include <stdlib.h>

int main() {
    FILE *binFile, *coeFile;

    unsigned char byte;
    int count = 0;
	    char inputFileName[] = "main.bin";//此处修改文件名以变更操作对象
    // 输入二进制文件名
    // printf("Enter the name of the input binary file: ");
    // scanf("%s", binFileName);

    // 打开二进制文件
    binFile = fopen(inputFileName, "rb");
    if (binFile == NULL) {
        printf("Error: Unable to open input binary file.\n");
        return 1;
    }

    // 输入 COE 文件名
    // printf("Enter the name of the output COE file: ");
    // scanf("%s", coeFileName);

    // 创建 COE 文件
    coeFile = fopen("start_mid.coe", "w");
    if (coeFile == NULL) {
        printf("Error: Unable to create output COE file.\n");
        fclose(binFile);
        return 1;
    }

    // 写入 COE 文件头部
    fprintf(coeFile, "memory_initialization_radix=16;\n");
    fprintf(coeFile, "memory_initialization_vector=\n");

    // 逐个读取二进制文件中的字节并写入 COE 文件
    while (fread(&byte, sizeof(unsigned char), 1, binFile) == 1) {
        fprintf(coeFile, "%02x", byte); // 将字节转换为十六进制数
        count++;
        if (count % 4 == 0) // 每行写入 4 个数据，根据需求修改
            fprintf(coeFile, ",\n");

    }

    // 关闭文件
    fclose(binFile);
    fclose(coeFile);

    printf("Conversion completed successfully.\n");

    return 0;
}
