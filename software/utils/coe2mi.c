#include <stdio.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>


int main(int argc, char *argv[])
{
  char *coe_name = NULL;
  char *mi_name = NULL;
  //默认值
  int depth = 32768;// 数据深度
  int width = 32;// 数据位宽

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-i") == 0 && i + 1 < argc) {
      coe_name = argv[i + 1];
      i++;
    } 
    else if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
      mi_name = argv[i + 1];
      i++;
    }
    else if(strcmp(argv[i], "-d") == 0 && i + 1 < argc)
    {
      depth = atoi(argv[i + 1]);
      i++;
    }
    else if(strcmp(argv[i], "-w") == 0 && i + 1 < argc)
    {
      width = atoi(argv[i + 1]);
      i++;
    }
    else if(strcmp(argv[i], "-h") == 0)
    {
      printf("\033[1;34mUsage: coe2mi -i input_file -o output_file -d depth -w width\033[0m\n");
      return 0;
    }
    else
    {
      printf("\033[1;31mInvalid command!\033[0m\n");
      printf("\033[1;34mUsage: coe2mi -i input_file -o output_file -d depth -w width\033[0m\n");
      return 0;
    }
  }

  FILE *fp_mi, *fp_coe;

  char buffer[10] = {0};
  char buffer_end[1] = {0};
  int count = 0;

  fp_mi = fopen(mi_name, "w");
  if (NULL == fp_mi)
    printf("\033[1;31mcan not open file %s!\033[0m\n", mi_name);
  else
  {
    //printf("\033[1;32mopen file %s successfully!\033[0m\n", mi_name);
    fprintf(fp_mi, "#File_format=Hex\n");
    fprintf(fp_mi, "#Address_depth=%d\n", depth);
    fprintf(fp_mi, "#Data_width=%d\n", width);
    fp_coe = fopen(coe_name, "r");
    if (NULL == fp_coe)
      printf("\033[1;31mcan not open file %s!\033[0m\n", coe_name);
    else
    {
      //printf("\033[1;32mopen file %s successfully!\033[0m\n", coe_name);
      fseek(fp_coe, 65, 0);
      while (fread(buffer, sizeof(char), sizeof(buffer) - 1, fp_coe))
      {
        fwrite(buffer, sizeof(char), sizeof(buffer) - 2, fp_mi);
        fread(buffer, sizeof(char), 1, fp_coe);
        fwrite(buffer, sizeof(char), 1, fp_mi);
        memset(buffer, 0, sizeof(buffer));
        count++;
      }
      memset(buffer, '0', sizeof(buffer));
      memset(buffer_end, '\n', 1);
      for (int i = count; i < depth; i++)
      {
        fwrite(buffer, sizeof(char), sizeof(buffer) - 2, fp_mi);
        fwrite(buffer_end, sizeof(char), 1, fp_mi);
      }
      fclose(fp_coe);
    }
    fclose(fp_mi);
  }
}