#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main() {
    FILE *inputFile, *outputFile;
    char inputFileName[] = "start_mid.coe";
    char outputFileName[] = "start.coe";
    char buffer[100];

    // 打开输入文件
    inputFile = fopen(inputFileName, "r");
    if (inputFile == NULL) {
        printf("Error: Unable to open input file %s.\n", inputFileName);
        return 1;
    }

    // 创建输出文件
    outputFile = fopen(outputFileName, "w");
    if (outputFile == NULL) {
        printf("Error: Unable to create output file %s.\n", outputFileName);
        fclose(inputFile);
        return 1;
    }

    // 写入 COE 文件头部
    fprintf(outputFile, "memory_initialization_radix = 16;\n");
    fprintf(outputFile, "memory_initialization_vector =\n");

    // 跳过输入文件的前两行
    fgets(buffer, sizeof(buffer), inputFile);
    fgets(buffer, sizeof(buffer), inputFile);

    // 处理每一行数据，转换为新格式写入输出文件
    while (fgets(buffer, sizeof(buffer), inputFile) != NULL) {
        // 删除行末的换行符
        buffer[strcspn(buffer, "\r\n")] = '\0';

        // 提取每行数据中的十六进制数，并按照新格式写入输出文件
        char *token = strtok(buffer, ",");
        while (token != NULL) {
            // 提取两个字符作为一个十六进制数的高位和低位
            char high = token[0];
            char low = token[1];

            // 写入输出文件，注意逗号和换行的位置
            fprintf(outputFile, "%c%c%c%c%c%c%c%c", token[6], token[7] , token[4], token[5] ,token[2], token[3], high ,low);
            token = strtok(NULL, ",");
            if (token != NULL)
                fprintf(outputFile, ",");
            else
                fprintf(outputFile, ",\n");
        }
    }

    // 关闭文件
    fclose(inputFile);
    fclose(outputFile);

    printf("Conversion completed successfully.\n");

    return 0;
}
