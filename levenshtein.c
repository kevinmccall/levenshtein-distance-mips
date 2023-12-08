#include<stdlib.h>
#include<stdio.h>
#include<string.h>

int levenshtein_dist(const char* str1, const char* str2) {
    int** arr = malloc(sizeof(int*) * (strlen(str2) + 1));
    for (int i = 0; i < strlen(str2) + 1; i++) {
        arr[i] = malloc(sizeof(int) * (strlen(str1) + 1));
    }
    int dist;
    for (int j = 0; j < strlen(str1) + 1; j++) {
        arr[0][j] = j;
    }
    for (int i = 0; i < strlen(str2) + 1; i++) {
        arr[i][0] = i;
    }
    for (int i = 1; i < strlen(str2) + 1; i++) {
        for (int j = 1; j < strlen(str1) + 1; j++) {
            if (str1[j - 1] == str2[i - 1]) {
                arr[i][j] = arr[i - 1][j - 1];
            } else {
                int min_val = arr[i - 1][j - 1];
                if (arr[i - 1][j] < min_val) {
                    min_val = arr[i - 1][j];
                }
                if (arr[i][j - 1] < min_val) {
                    min_val = arr[i][j - 1];
                }
                arr[i][j] = min_val + 1;
            }
            printf("min val (%d, %d): %d\n", i, j, arr[i][j]);
        }
    }
    dist = arr[strlen(str2)][strlen(str1)];

    for (int i = 0; i < strlen(str2); i++) {
        free(arr[i]);
    }
    free(arr);
    return dist;
}

int main() {
    char* string1 = "Saturday";
    char* string2 = "Sundays";
    // char* string1 = "fix";
    // char* string2 = "win";
    int distance = levenshtein_dist(string1, string2);
    printf("levenshtein distance: %d\n", distance);
    return 0;
}